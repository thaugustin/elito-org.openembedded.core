SUMMARY = "Command line tool and library for client-side URL transfers"
HOMEPAGE = "http://curl.haxx.se/"
BUGTRACKER = "http://curl.haxx.se/mail/list.cgi?list=curl-tracker"
SECTION = "console/network"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;beginline=7;md5=3a34942f4ae3fbf1a303160714e664ac"

DEPENDS = "zlib gnutls"
DEPENDS_class-native = "zlib-native openssl-native"
DEPENDS_class-nativesdk = "nativesdk-zlib"

SRC_URI = "http://curl.haxx.se/download/curl-${PV}.tar.bz2 \
           file://pkgconfig_fix.patch \
"

# curl likes to set -g0 in CFLAGS, so we stop it
# from mucking around with debug options
#
SRC_URI += " file://configure_ac.patch"

SRC_URI[md5sum] = "88491df2bb32e9146e776ae6ac2f8327"
SRC_URI[sha256sum] = "10beade56b48311499e444783df3413405b22f20a147ed4a1d8a8125f1cc829b"

inherit autotools pkgconfig binconfig multilib_header

EXTRA_OECONF = "--with-zlib=${STAGING_LIBDIR}/../ \
                --without-libssh2 \
                --with-random=/dev/urandom \
                --without-libidn \
                --enable-crypto-auth \
                --disable-ldap \
                --disable-ldaps \
                ${CURLGNUTLS} \
                "

CURLGNUTLS = " --with-gnutls=${STAGING_LIBDIR}/../ --without-ssl"
CURLGNUTLS_class-native = "--without-gnutls --with-ssl"
CURLGNUTLS_class-nativesdk = "--without-gnutls --without-ssl"

do_configure_prepend() {
	sed -i s:OPT_GNUTLS/bin:OPT_GNUTLS:g ${S}/configure.ac
}

do_install_append() {
	oe_multilib_header curl/curlbuild.h
}

PACKAGES =+ "${PN}-certs libcurl libcurl-dev libcurl-staticdev libcurl-doc"

FILES_${PN}-certs = "${datadir}/curl/curl-*"
PACKAGE_ARCH_${PN}-certs = "all"

FILES_lib${BPN} = "${libdir}/lib*.so.*"
RRECOMMENDS_lib${BPN} += "${PN}-certs"
FILES_lib${BPN}-dev = "${includedir} \
                      ${libdir}/lib*.so \
                      ${libdir}/lib*.la \
                      ${libdir}/pkgconfig \
                      ${datadir}/aclocal \
                      ${bindir}/*-config"
FILES_lib${BPN}-staticdev = "${libdir}/lib*.a"
FILES_lib${BPN}-doc = "${mandir}/man3 \
                      ${mandir}/man1/curl-config.1"

BBCLASSEXTEND = "native nativesdk"
