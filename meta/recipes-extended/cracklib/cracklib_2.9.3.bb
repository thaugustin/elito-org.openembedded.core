SUMMARY = "Password strength checker library"
HOMEPAGE = "http://sourceforge.net/projects/cracklib"

LICENSE = "LGPLv2.1+"
LIC_FILES_CHKSUM = "file://COPYING.LIB;md5=e3eda01d9815f8d24aae2dbd89b68b06"

DEPENDS = "cracklib-native zlib python"
RDEPEND_${PN}-python += "python"

PACKAGES += "${PN}-python"

EXTRA_OECONF = "--with-python --libdir=${base_libdir}"

SRC_URI = "${SOURCEFORGE_MIRROR}/cracklib/cracklib-${PV}.tar.gz \
           file://0001-packlib.c-support-dictionary-byte-order-dependent.patch \
           file://0002-craklib-fix-testnum-and-teststr-failed.patch"

SRC_URI[md5sum] = "1e18ed9a593719af71b6440f16f91182"
SRC_URI[sha256sum] = "9c55afcdc01ae90aad0af0f9e4de0db9ba2fadf88cdf3a585a08a3530d25dba5"

inherit autotools gettext pythonnative python-dir

do_install_append_class-target() {
	create-cracklib-dict -o ${D}${datadir}/cracklib/pw_dict ${D}${datadir}/cracklib/cracklib-small
}

do_install_append() {
	src_dir="${D}${base_libdir}/${PYTHON_DIR}/site-packages"
	rm -f $src_dir/*.pyo
	rm -f $src_dir/test_cracklib.py
	# Move python files from ${base_libdir} to ${libdir} since used --libdir=${base_libdir}
	install -d -m 0755 ${D}${PYTHON_SITEPACKAGES_DIR}/
	mv $src_dir/* ${D}${PYTHON_SITEPACKAGES_DIR}
	rm -fr ${D}${base_libdir}/${PYTHON_DIR}
}

BBCLASSEXTEND = "native nativesdk"

FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}/cracklib.py \
	${PYTHON_SITEPACKAGES_DIR}/_cracklib.so \
    "
FILES_${PN}-dbg += "${PYTHON_SITEPACKAGES_DIR}/.debug/_cracklib.so"
FILES_${PN}-staticdev += "${PYTHON_SITEPACKAGES_DIR}/_cracklib.a \
	${PYTHON_SITEPACKAGES_DIR}/_cracklib.la \
    "
