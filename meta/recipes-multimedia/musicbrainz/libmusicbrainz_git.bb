SUMMARY = "MusicBrainz Client"
DESCRIPTION = "The MusicBrainz client is a library which can be built into other programs.  The library allows you to access the data held on the MusicBrainz server."
HOMEPAGE = "http://musicbrainz.org"
LICENSE = "LGPLv2.1+"
LIC_FILES_CHKSUM = "file://COPYING.txt;md5=fbc093901857fcd118f065f900982c24"
DEPENDS = "expat neon"

PV = "5.0.1+git${SRCPV}"
PR = "r0"

SRCREV = "0749dd0a35b4a54316da064475863a4ac6e28e7e"
SRC_URI = "git://github.com/metabrainz/libmusicbrainz.git \
           file://allow-libdir-override.patch "

S = "${WORKDIR}/git"

LDFLAGS_prepend_libc-uclibc = " -lpthread "


inherit cmake pkgconfig

do_configure_prepend() {
    mkdir build-native
    cd build-native
    cmake -DCMAKE_C_FLAGS=${BUILD_CFLAGS} \
            -DCMAKE_C_COMPILER=${BUILD_CC} \
            -DCMAKE_CXX_FLAGS=${BUILD_CXXFLAGS} \
            -DCMAKE_CXX_COMPILER=${BUILD_CXX} \
            -DCMAKE_LINK_FLAGS=${BUILD_LDFLAGS} \
            ..
    make
    cd ..
}

EXTRA_OECMAKE = "-DLIB_INSTALL_DIR:PATH=${libdir} \
                -DIMPORT_EXECUTABLES=build-native/ImportExecutables.cmake"
