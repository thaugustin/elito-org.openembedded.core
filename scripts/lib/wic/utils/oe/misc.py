# ex:ts=4:sw=4:sts=4:et
# -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*-
#
# Copyright (c) 2013, Intel Corporation.
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# DESCRIPTION
# This module provides a place to collect various wic-related utils
# for the OpenEmbedded Image Tools.
#
# AUTHORS
# Tom Zanussi <tom.zanussi (at] linux.intel.com>
#
"""Miscellaneous functions."""

from collections import defaultdict

from wic import msger
from wic.utils import runner

# executable -> recipe pairs for exec_native_cmd
NATIVE_RECIPES = {"mcopy": "mtools",
                  "mkdosfs": "dosfstools",
                  "mkfs.btrfs": "btrfs-tools",
                  "mkfs.ext2": "e2fsprogs",
                  "mkfs.ext3": "e2fsprogs",
                  "mkfs.ext4": "e2fsprogs",
                  "mkfs.vfat": "dosfstools",
                  "mksquashfs": "squashfs-tools",
                  "mkswqp": "util-linux",
                  "parted": "parted",
                  "sgdisk": "gptfdisk",
                  "syslinux": "syslinux"
                 }

def __exec_cmd(cmd_and_args, as_shell=False, catch=3):
    """
    Execute command, catching stderr, stdout

    Need to execute as_shell if the command uses wildcards
    """
    msger.debug("__exec_cmd: %s" % cmd_and_args)
    args = cmd_and_args.split()
    msger.debug(args)

    if as_shell:
        ret, out = runner.runtool(cmd_and_args, catch)
    else:
        ret, out = runner.runtool(args, catch)
    out = out.strip()
    msger.debug("__exec_cmd: output for %s (rc = %d): %s" % \
                (cmd_and_args, ret, out))

    return (ret, out)


def exec_cmd(cmd_and_args, as_shell=False, catch=3):
    """
    Execute command, catching stderr, stdout

    Exits if rc non-zero
    """
    ret, out = __exec_cmd(cmd_and_args, as_shell, catch)

    if ret != 0:
        msger.error("exec_cmd: %s returned '%s' instead of 0" % \
                    (cmd_and_args, ret))

    return out


def exec_native_cmd(cmd_and_args, native_sysroot, catch=3):
    """
    Execute native command, catching stderr, stdout

    Need to execute as_shell if the command uses wildcards

    Always need to execute native commands as_shell
    """
    native_paths = \
        "export PATH=%s/sbin:%s/usr/sbin:%s/usr/bin" % \
        (native_sysroot, native_sysroot, native_sysroot)
    native_cmd_and_args = "%s;%s" % (native_paths, cmd_and_args)
    msger.debug("exec_native_cmd: %s" % cmd_and_args)

    args = cmd_and_args.split()
    msger.debug(args)

    ret, out = __exec_cmd(native_cmd_and_args, True, catch)

    if ret == 127: # shell command-not-found
        prog = args[0]
        msg = "A native program %s required to build the image "\
              "was not found (see details above).\n\n" % prog
        recipe = NATIVE_RECIPES.get(prog)
        if recipe:
            msg += "Please bake it with 'bitbake %s-native' "\
                   "and try again.\n" % recipe
        else:
            msg += "Wic failed to find a recipe to build native %s. Please "\
                   "file a bug against wic.\n" % prog
        msger.error(msg)
    if out:
        msger.debug('"%s" output: %s' % (args[0], out))

    if ret != 0:
        msger.error("exec_cmd: '%s' returned '%s' instead of 0" % \
                    (cmd_and_args, ret))

    return ret, out

BOOTDD_EXTRA_SPACE = 16384

_BITBAKE_VARS = defaultdict(dict)

def get_bitbake_var(var, image=None):
    """
    Get bitbake variable value lazy way, i.e. run
    'bitbake -e' only when variable is requested.
    """
    if image not in _BITBAKE_VARS:
        # Get bitbake -e output
        cmd = "bitbake -e"
        if image:
            cmd += " %s" % image

        log_level = msger.get_loglevel()
        msger.set_loglevel('normal')
        ret, lines = __exec_cmd(cmd)
        msger.set_loglevel(log_level)

        if ret:
            print "Couldn't get '%s' output." % cmd
            print "Bitbake failed with error:\n%s\n" % lines
            return

        # Parse bitbake -e output
        for line in lines.split('\n'):
            if "=" not in line:
                continue
            try:
                key, val = line.split("=")
            except ValueError:
                continue
            key = key.strip()
            val = val.strip()
            if key.replace('_', '').isalnum():
                _BITBAKE_VARS[image][key] = val.strip('"')

        # Make first image a default set of variables
        images = [key for key in _BITBAKE_VARS if key]
        if len(images) == 1:
            _BITBAKE_VARS[None] = _BITBAKE_VARS[image]

    return _BITBAKE_VARS[image].get(var)

def parse_sourceparams(sourceparams):
    """
    Split sourceparams string of the form key1=val1[,key2=val2,...]
    into a dict.  Also accepts valueless keys i.e. without =.

    Returns dict of param key/val pairs (note that val may be None).
    """
    params_dict = {}

    params = sourceparams.split(',')
    if params:
        for par in params:
            if not par:
                continue
            if not '=' in par:
                key = par
                val = None
            else:
                key, val = par.split('=')
            params_dict[key] = val

    return params_dict
