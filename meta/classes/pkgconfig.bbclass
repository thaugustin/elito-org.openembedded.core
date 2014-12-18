DEPENDS_prepend = "pkgconfig-native "

PKGCONFIG_FILE_PATTERN ?= "-path '*/pkgconfig/*' -name '*.pc' -type f"
PKGCONFIG_FILE_PATTERN[doc] = "Options given to the 'find' utility to \
 iterate over pkgconfig files"

pkgconfig_mangle_pc() {
    if test -n '${PKG_CONFIG_SYSROOT_DIR}'; then
	# find .pc files, check and give out whether they contain
	# the sysroot dir and remove this string
	find '${D}' ${PKGCONFIG_FILE_PATTERN} \
	     -exec grep '${PKG_CONFIG_SYSROOT_DIR}' '{}' \; \
	     -printf "NOTE: removing PKG_CONFIG_SYSROOT_DIR from %P\n" \
	     -exec sed -i \
	               -e 's!${PKG_CONFIG_SYSROOT_DIR}!!g' \
	           '{}' \;
    fi
}
do_install[postfuncs] += "pkgconfig_mangle_pc"
