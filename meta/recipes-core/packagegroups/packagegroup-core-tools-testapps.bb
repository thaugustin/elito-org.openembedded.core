#
# Copyright (C) 2008 OpenedHand Ltd.
#

SUMMARY = "Testing tools/applications"
LICENSE = "MIT"

PR = "r2"

inherit packagegroup

PACKAGE_ARCH = "${MACHINE_ARCH}"

# For backwards compatibility after rename
RPROVIDES_${PN} = "task-core-tools-testapps"
RREPLACES_${PN} = "task-core-tools-testapps"
RCONFLICTS_${PN} = "task-core-tools-testapps"

# kexec-tools doesn't work on Mips
KEXECTOOLS ?= "kexec"
KEXECTOOLS_mips ?= ""
KEXECTOOLS_mipsel ?= ""
KEXECTOOLS_powerpc ?= ""
KEXECTOOLS_e5500-64b ?= ""
KEXECTOOLS_aarch64 ?= ""

GLTOOLS = "\
    mesa-demos \
    piglit \
    "

3GTOOLS = "\
    ofono-tests \
    "

_pkgs_touch = "\
    tslib-calibrate \
    tslib-tests \
"

_pkgs_screen = "\
    fstests \
    owl-video \
"

_pkgs_x11 = "\
    x11perf \
    xrestop \
    xwininfo \
    xprop \
    xvideo-tests \
"

_pkgs_alsa = " \
    alsa-utils-amixer \
    alsa-utils-aplay \
"

RDEPENDS_${PN} = "\
    ${@base_contains('MACHINE_FEATURES', 'touchscreen', '${_pkgs_touch}', '', d)} \
    ${@base_contains('MACHINE_FEATURES', 'screen', '${_pkgs_screen}', '', d)} \
    ${@base_contains('DISTRO_FEATURES',  'x11', '${_pkgs_x11}', '', d)} \
    ${@base_contains('DISTRO_FEATURES', 'opengl', "${GLTOOLS}", "", d)} \
    ${@base_contains('DISTRO_FEATURES', '3g', "${3GTOOLS}", "", d)} \
    ${@base_contains('MACHINE_FEATURES', 'alsa', '${_pkgs_alsa}', '', d)} \
    blktool \
    lrzsz \
    ${KEXECTOOLS} \
    gst-meta-video \
    gst-meta-audio \
    ltp \
    connman-tools \
    connman-tests \
    connman-client \
    "
