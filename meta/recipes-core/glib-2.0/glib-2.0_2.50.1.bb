require glib.inc

PE = "1"

SHRT_VER = "${@oe.utils.trim_version("${PV}", 2)}"

SRC_URI = "${GNOME_MIRROR}/glib/${SHRT_VER}/glib-${PV}.tar.xz \
           file://configure-libtool.patch \
           file://fix-conflicting-rand.patch \
           file://run-ptest \
           file://ptest-paths.patch \
           file://uclibc_musl_translation.patch \
           file://allow-run-media-sdX-drive-mount-if-username-root.patch \
           file://0001-Remove-the-warning-about-deprecated-paths-in-schemas.patch \
           file://Enable-more-tests-while-cross-compiling.patch \
           file://gi-exclude.patch \
           file://0001-Install-gio-querymodules-as-libexec_PROGRAM.patch \
           file://0001-Do-not-ignore-return-value-of-write.patch \
           "

SRC_URI_append_class-native = " file://glib-gettextize-dir.patch \
                                file://relocate-modules.patch"

SRC_URI[md5sum] = "6baee4d7e3b1ec791b4ced93976365ee"
SRC_URI[sha256sum] = "2ef87a78f37c1eb5b95f4cc95efd5b66f69afad9c9c0899918d04659cf6df7dd"
