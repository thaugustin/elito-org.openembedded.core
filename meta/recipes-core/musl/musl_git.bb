# Copyright (C) 2014 Khem Raj <raj.khem@gmail.com>
# Released under the MIT license (see COPYING.MIT for the terms)

require musl.inc

SRCREV = "cf115059ba0ecd611008c89c78c37b62f8e6d6af"

PV = "1.1.13+git${SRCPV}"

# mirror is at git://github.com/kraj/musl.git

SRC_URI = "git://git.musl-libc.org/musl \
           file://0001-Make-dynamic-linker-a-relative-symlink-to-libc.patch \
          "

S = "${WORKDIR}/git"

PROVIDES += "virtual/libc virtual/${TARGET_PREFIX}libc-for-gcc virtual/libiconv virtual/libintl"

DEPENDS = "virtual/${TARGET_PREFIX}binutils \
           virtual/${TARGET_PREFIX}gcc-initial \
           libgcc-initial \
           bsd-headers \
          "

export CROSS_COMPILE="${TARGET_PREFIX}"

EXTRA_OEMAKE = ""

LDFLAGS += "-Wl,-soname,libc.so"

CONFIGUREOPTS = " \
    --prefix=${prefix} \
    --exec-prefix=${exec_prefix} \
    --bindir=${bindir} \
    --libdir=${libdir} \
    --includedir=${includedir} \
    --syslibdir=${base_libdir} \
"

do_configure() {
	${S}/configure ${CONFIGUREOPTS}
}

do_compile() {
	oe_runmake
}

do_install() {
	oe_runmake install DESTDIR='${D}'

	install -d ${D}${bindir}
	ln -s ../../${libdir}/libc.so ${D}${bindir}/ldd
}

RDEPENDS_${PN}-dev += "linux-libc-headers-dev bsd-headers-dev"
RPROVIDES_${PN}-dev += "libc-dev virtual-libc-dev"
RPROVIDES_${PN} += "ldd libsegfault rtld(GNU_HASH)"

LEAD_SONAME = "libc.so"
