require openssl.inc

# For target side versions of openssl enable support for OCF Linux driver
# if they are available.
DEPENDS += "cryptodev-linux"

CFLAG += "-DHAVE_CRYPTODEV -DUSE_CRYPTODEV_DIGESTS"

LIC_FILES_CHKSUM = "file://LICENSE;md5=f9a8f968107345e0b75aa8c2ecaa7ec8"

export DIRS = "crypto ssl apps engines"
export OE_LDFLAGS="${LDFLAGS}"

SRC_URI += "file://find.pl;subdir=${BP}/util/ \
            file://run-ptest \
            file://configure-targets.patch \
            file://shared-libs.patch \
            file://oe-ldflags.patch \
            file://engines-install-in-libdir-ssl.patch \
            file://debian1.0.2/block_diginotar.patch \
            file://debian1.0.2/block_digicert_malaysia.patch \
            file://debian/ca.patch \
            file://debian/c_rehash-compat.patch \
            file://debian/debian-targets.patch \
            file://debian/man-dir.patch \
            file://debian/man-section.patch \
            file://debian/no-rpath.patch \
            file://debian/no-symbolic.patch \
            file://debian/pic.patch \
            file://debian/version-script.patch \
            file://openssl_fix_for_x32.patch \
            file://fix-cipher-des-ede3-cfb1.patch \
            file://openssl-avoid-NULL-pointer-dereference-in-EVP_DigestInit_ex.patch \
            file://openssl-fix-des.pod-error.patch \
            file://Makefiles-ptest.patch \
            file://ptest-deps.patch \
            file://crypto_use_bigint_in_x86-64_perl.patch \
            file://openssl-1.0.2a-x32-asm.patch \
            file://ptest_makefile_deps.patch  \
            file://configure-musl-target.patch \
           "

SRC_URI[md5sum] = "5262bfa25b60ed9de9f28d5d52d77fc5"
SRC_URI[sha256sum] = "e23ccafdb75cfcde782da0151731aa2185195ac745eea3846133f2e05c0e0bff"

PACKAGES =+ "${PN}-engines"
FILES_${PN}-engines = "${libdir}/ssl/engines/*.so ${libdir}/engines"

# The crypto_use_bigint patch means that perl's bignum module needs to be
# installed, but some distributions (for example Fedora 23) don't ship it by
# default.  As the resulting error is very misleading check for bignum before
# building.
do_configure_prepend() {
	if ! perl -Mbigint -e true; then
		bbfatal "The perl module 'bignum' was not found but this is required to build openssl.  Please install this module (often packaged as perl-bignum) and re-run bitbake."
	fi
}
