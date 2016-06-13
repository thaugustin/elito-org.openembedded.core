SUMMARY = "Script-directed dynamic tracing and performance analysis tool for Linux"

require systemtap_git.inc

DEPENDS = "elfutils sqlite3 systemtap-native ncurses json-c"
DEPENDS_class-native = "elfutils-native sqlite3-native gettext-native"
DEPENDS_class-nativesdk = "nativesdk-elfutils nativesdk-sqlite3 nativesdk-gettext"

RDEPENDS_${PN} += "python3-core bash"

EXTRA_OECONF += "--with-libelf=${STAGING_DIR_TARGET} --without-rpm \
            --without-nss --without-avahi --without-dyninst \
            --disable-server --disable-grapher --enable-prologues \
            --with-python3 \
            ac_cv_prog_have_javac=no \
            ac_cv_prog_have_jar=no "

STAP_DOCS ?= "--disable-docs --disable-publican --disable-refdocs"

EXTRA_OECONF += "${STAP_DOCS} "

PACKAGECONFIG ??= ""
PACKAGECONFIG[libvirt] = "--enable-libvirt,--disable-libvirt,libvirt"

inherit autotools gettext pkgconfig

BBCLASSEXTEND = "native nativesdk"
