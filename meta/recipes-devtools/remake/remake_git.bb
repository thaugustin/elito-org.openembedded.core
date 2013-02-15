PR = "r0"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d32239bcb673463ab874e80d47fae504 \
                    file://tests/COPYING;md5=d32239bcb673463ab874e80d47fae504 \
                    file://glob/COPYING.LIB;md5=4a770b67e6be0f60da244beb2de0fce4"
require remake.inc

SRC_URI += "file://version-remake.texi.patch"
SRCREV = "414d6e84121c6740ff5079370c905dea0f0e1ddb"
S = "${WORKDIR}/git"

DEPENDS += "readline"
PROVIDES += "make"

do_configure_prepend() {
    # remove the default LINGUAS since we are not going to generate languages
    rm po/LINGUAS
    touch po/LINGUAS
    # create config.rpath which required by configure.ac
    autopoint || touch config.rpath
}

BBCLASSEXTEND = "native"
