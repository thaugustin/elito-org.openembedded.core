#
# Copyright (C) 2008 OpenedHand Ltd.
#

DESCRIPTION = "Test apps task for OE-Core"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=3f40d7994397109285ec7b81fdeb3b58 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

PACKAGES = "\
    ${PN} \
    ${PN}-dbg \
    ${PN}-dev \
    "

PACKAGE_ARCH = "${MACHINE_ARCH}"

ALLOW_EMPTY = "1"

# kexec-tools doesn't work on Mips
KEXECTOOLS ?= "kexec"
KEXECTOOLS_mips ?= ""
KEXECTOOLS_mipsel ?= ""
KEXECTOOLS_powerpc ?= ""

_pkgs_touch = "\
    tslib-calibrate \
    tslib-tests \
"

_pkgs_screen = "\
    fstests \
    clutter-box2d \
    owl-video \
"

_pkgs_x11 = "\
    mesa-demos \
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
    ${@base_contains('MACHINE_FEATURES', 'alsa', '${_pkgs_alsa}', '', d)} \
    blktool \
    lrzsz \
    ${KEXECTOOLS} \
    gst-meta-video \
    gst-meta-audio \
    ltp \
    "
