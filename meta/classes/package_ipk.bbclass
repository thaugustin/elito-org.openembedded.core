inherit package

IMAGE_PKGTYPE ?= "ipk"

IPKGCONF_TARGET = "${WORKDIR}/opkg.conf"
IPKGCONF_SDK =  "${WORKDIR}/opkg-sdk.conf"

PKGWRITEDIRIPK = "${WORKDIR}/deploy-ipks"

# Program to be used to build opkg packages
OPKGBUILDCMD ??= "opkg-build"

python package_ipk_fn () {
	d.setVar('PKGFN', d.getVar('PKG'))
}

python package_ipk_install () {
	pkg = d.getVar('PKG', True)
	pkgfn = d.getVar('PKGFN', True)
	rootfs = d.getVar('IMAGE_ROOTFS', True)
	ipkdir = d.getVar('DEPLOY_DIR_IPK', True)
	stagingdir = d.getVar('STAGING_DIR', True)
	tmpdir = d.getVar('TMPDIR', True)

	if None in (pkg,pkgfn,rootfs):
		raise bb.build.FuncFailed("missing variables (one or more of PKG, PKGFN, IMAGEROOTFS)")
	try:
		bb.mkdirhier(rootfs)
		os.chdir(rootfs)
	except OSError:
		import sys
		(type, value, traceback) = sys.exc_info()
		print value
		raise bb.build.FuncFailed

	# Generate ipk.conf if it or the stamp doesnt exist
	conffile = os.path.join(stagingdir,"ipkg.conf")
	if not os.access(conffile, os.R_OK):
		ipkg_archs = d.getVar('PACKAGE_ARCHS')
		if ipkg_archs is None:
			bb.error("PACKAGE_ARCHS missing")
			raise FuncFailed
		ipkg_archs = ipkg_archs.split()
		arch_priority = 1

		f = open(conffile,"w")
		for arch in ipkg_archs:
			f.write("arch %s %s\n" % ( arch, arch_priority ))
			arch_priority += 1
		f.write("src local file:%s" % ipkdir)
		f.close()


	if not os.access(os.path.join(ipkdir,"Packages"), os.R_OK) or not os.access(os.path.join(tmpdir, "stamps", "IPK_PACKAGE_INDEX_CLEAN"),os.R_OK):
		ret = os.system('opkg-make-index -p %s %s ' % (os.path.join(ipkdir, "Packages"), ipkdir))
		if (ret != 0 ):
			raise bb.build.FuncFailed
		f = open(os.path.join(tmpdir, "stamps", "IPK_PACKAGE_INDEX_CLEAN"),"w")
		f.close()

	ret = os.system('opkg-cl  -o %s -f %s update' % (rootfs, conffile))
	ret = os.system('opkg-cl  -o %s -f %s install %s' % (rootfs, conffile, pkgfn))
	if (ret != 0 ):
		raise bb.build.FuncFailed
}

package_tryout_install_multilib_ipk() {
	#try install multilib
	multilib_tryout_dirs=""
	for item in ${MULTILIB_VARIANTS}; do
		local target_rootfs="${MULTILIB_TEMP_ROOTFS}/${item}"
		local ipkg_args="-f ${INSTALL_CONF_IPK} -o ${target_rootfs} --force_overwrite"
		local selected_pkg=""
		local pkgname_prefix="${item}-"
		local pkgname_len=${#pkgname_prefix}
		for pkg in ${INSTALL_PACKAGES_MULTILIB_IPK}; do
			local pkgname=$(echo $pkg | awk -v var=$pkgname_len '{ pkgname=substr($1, 1, var - 1); print pkgname; }' )
			if [ ${pkgname} = ${pkgname_prefix} ]; then
			    selected_pkg="${selected_pkg} ${pkg}"
			fi
		done
		if [ ! -z "${selected_pkg}" ]; then
			rm -f ${target_rootfs}
			mkdir -p ${target_rootfs}/${opkglibdir}
			opkg-cl ${ipkg_args} update
			opkg-cl ${ipkg_args} install ${selected_pkg}
			multilib_tryout_dirs="${multilib_tryout_dirs} ${target_rootfs}"
		fi
	done
}

split_multilib_packages() {
	INSTALL_PACKAGES_NORMAL_IPK=""
	INSTALL_PACKAGES_MULTILIB_IPK=""
	for pkg in ${INSTALL_PACKAGES_IPK}; do
		is_multilib=0
		for item in ${MULTILIB_VARIANTS}; do
			local pkgname_prefix="${item}-"
			local pkgname_len=${#pkgname_prefix}
			local pkgname=$(echo $pkg | awk -v var=$pkgname_len '{ pkgname=substr($1, 1, var - 1); print pkgname; }' )
			if [ ${pkgname} = ${pkgname_prefix} ]; then
				is_multilib=1
				break
			fi
		done

		if [ ${is_multilib} = 0 ]; then
			INSTALL_PACKAGES_NORMAL_IPK="${INSTALL_PACKAGES_NORMAL_IPK} ${pkg}"
		else
			INSTALL_PACKAGES_MULTILIB_IPK="${INSTALL_PACKAGES_MULTILIB_IPK} ${pkg}"
		fi
	done
}

#
# install a bunch of packages using opkg
# the following shell variables needs to be set before calling this func:
# INSTALL_ROOTFS_IPK - install root dir
# INSTALL_CONF_IPK - configuration file
# INSTALL_PACKAGES_IPK - packages to be installed
# INSTALL_PACKAGES_ATTEMPTONLY_IPK - packages attemped to be installed only
# INSTALL_PACKAGES_LINGUAS_IPK - additional packages for uclibc
# INSTALL_TASK_IPK - task name

package_install_internal_ipk() {

	local target_rootfs="${INSTALL_ROOTFS_IPK}"
	local conffile="${INSTALL_CONF_IPK}"
	local package_attemptonly="${INSTALL_PACKAGES_ATTEMPTONLY_IPK}"
	local package_linguas="${INSTALL_PACKAGES_LINGUAS_IPK}"
	local task="${INSTALL_TASK_IPK}"

	split_multilib_packages

	local package_to_install="${INSTALL_PACKAGES_NORMAL_IPK}"
	local package_multilib="${INSTALL_PACKAGES_MULTILIB_IPK}"

	mkdir -p ${target_rootfs}${localstatedir}/lib/opkg/

	local ipkg_args="-f ${conffile} -o ${target_rootfs} --force-overwrite --force_postinstall"

	opkg-cl ${ipkg_args} update

	# Uclibc builds don't provide this stuff...
	if [ x${TARGET_OS} = "xlinux" ] || [ x${TARGET_OS} = "xlinux-gnueabi" ] ; then
		if [ ! -z "${package_linguas}" ]; then
			for i in ${package_linguas}; do
				opkg-cl ${ipkg_args} install $i
			done
		fi
	fi

	if [ ! -z "${package_to_install}" ]; then
		opkg-cl ${ipkg_args} install ${package_to_install}
	fi

	if [ ! -z "${package_attemptonly}" ]; then
		opkg-cl ${ipkg_args} install ${package_attemptonly} > "${WORKDIR}/temp/log.do_${task}_attemptonly.${PID}" || true
	fi

	package_tryout_install_multilib_ipk
	if [ ! -z "${MULTILIB_CHECK_FILE}" ]; then
		#sanity check
		multilib_sanity_check ${target_rootfs} ${multilib_tryout_dirs} || exit 1
	fi

	if [ ! -z "${package_multilib}" ]; then
		opkg-cl ${ipkg_args} install ${package_multilib}
	fi
}

ipk_log_check() {
       target="$1"
       lf_path="$2"

       lf_txt="`cat $lf_path`"
       for keyword_die in "exit 1" "Collected errors" ERR Fail
       do
               if (echo "$lf_txt" | grep -v log_check | grep "$keyword_die") >/dev/null 2>&1
               then
                       echo "log_check: There were error messages in the logfile"
                       echo -e "log_check: Matched keyword: [$keyword_die]\n"
                       echo "$lf_txt" | grep -v log_check | grep -C 5 -i "$keyword_die"
                       echo ""
                       do_exit=1
               fi
       done
       test "$do_exit" = 1 && exit 1
       true
}

#
# Update the Packages index files in ${DEPLOY_DIR_IPK}
#
package_update_index_ipk () {
	set -x

	ipkgarchs="${ALL_MULTILIB_PACKAGE_ARCHS} ${SDK_PACKAGE_ARCHS}"

	if [ ! -z "${DEPLOY_KEEP_PACKAGES}" ]; then
		return
	fi

	packagedirs="${DEPLOY_DIR_IPK}"
	for arch in $ipkgarchs; do
		packagedirs="$packagedirs ${DEPLOY_DIR_IPK}/$arch"
	done

	multilib_archs="${MULTILIB_ARCHS}"
	for arch in $multilib_archs; do
		packagedirs="$packagedirs ${DEPLOY_DIR_IPK}/$arch"
	done

	for pkgdir in $packagedirs; do
		if [ -e $pkgdir/ ]; then
			touch $pkgdir/Packages
			flock $pkgdir/Packages.flock -c "opkg-make-index -r $pkgdir/Packages -p $pkgdir/Packages -l $pkgdir/Packages.filelist -m $pkgdir/"
		fi
	done
}

#
# Generate an ipkg conf file ${IPKGCONF_TARGET} suitable for use against 
# the target system and an ipkg conf file ${IPKGCONF_SDK} suitable for 
# use against the host system in sdk builds
#
package_generate_ipkg_conf () {
	package_generate_archlist
	echo "src oe file:${DEPLOY_DIR_IPK}" >> ${IPKGCONF_SDK}
	ipkgarchs="${SDK_PACKAGE_ARCHS}"
	for arch in $ipkgarchs; do
		if [ -e ${DEPLOY_DIR_IPK}/$arch/Packages ] ; then
		        echo "src oe-$arch file:${DEPLOY_DIR_IPK}/$arch" >> ${IPKGCONF_SDK}
		fi
	done

	echo "src oe file:${DEPLOY_DIR_IPK}" >> ${IPKGCONF_TARGET}
	ipkgarchs="${ALL_MULTILIB_PACKAGE_ARCHS}"
	for arch in $ipkgarchs; do
		if [ -e ${DEPLOY_DIR_IPK}/$arch/Packages ] ; then
		        echo "src oe-$arch file:${DEPLOY_DIR_IPK}/$arch" >> ${IPKGCONF_TARGET}
		fi
	done
}

package_generate_archlist () {
	ipkgarchs="${SDK_PACKAGE_ARCHS}"
	priority=1
	for arch in $ipkgarchs; do
		echo "arch $arch $priority" >> ${IPKGCONF_SDK}
		priority=$(expr $priority + 5)
	done

	ipkgarchs="${ALL_MULTILIB_PACKAGE_ARCHS}"
	priority=1
	for arch in $ipkgarchs; do
		echo "arch $arch $priority" >> ${IPKGCONF_TARGET}
		priority=$(expr $priority + 5)
	done
}

python do_package_ipk () {
	import re, copy
	import textwrap

	workdir = d.getVar('WORKDIR', True)
	outdir = d.getVar('PKGWRITEDIRIPK', True)
	tmpdir = d.getVar('TMPDIR', True)
	pkgdest = d.getVar('PKGDEST', True)
	if not workdir or not outdir or not tmpdir:
		bb.error("Variables incorrectly set, unable to package")
		return

	packages = d.getVar('PACKAGES', True)
	if not packages or packages == '':
		bb.debug(1, "No packages; nothing to do")
		return

	# We're about to add new packages so the index needs to be checked
        # so remove the appropriate stamp file.
	if os.access(os.path.join(tmpdir, "stamps", "IPK_PACKAGE_INDEX_CLEAN"), os.R_OK):
		os.unlink(os.path.join(tmpdir, "stamps", "IPK_PACKAGE_INDEX_CLEAN"))

	for pkg in packages.split():
		localdata = bb.data.createCopy(d)
		root = "%s/%s" % (pkgdest, pkg)

		lf = bb.utils.lockfile(root + ".lock")

		localdata.setVar('ROOT', '')
		localdata.setVar('ROOT_%s' % pkg, root)
		pkgname = localdata.getVar('PKG_%s' % pkg, True)
		if not pkgname:
			pkgname = pkg
		localdata.setVar('PKG', pkgname)

		localdata.setVar('OVERRIDES', pkg)

		bb.data.update_data(localdata)
		basedir = os.path.join(os.path.dirname(root))
		arch = localdata.getVar('PACKAGE_ARCH', True)
		pkgoutdir = "%s/%s" % (outdir, arch)
		bb.mkdirhier(pkgoutdir)
		os.chdir(root)
		from glob import glob
		g = glob('*')
		try:
			del g[g.index('CONTROL')]
			del g[g.index('./CONTROL')]
		except ValueError:
			pass
		if not g and localdata.getVar('ALLOW_EMPTY') != "1":
			bb.note("Not creating empty archive for %s-%s-%s" % (pkg, localdata.getVar('PKGV', True), localdata.getVar('PKGR', True)))
			bb.utils.unlockfile(lf)
			continue

		controldir = os.path.join(root, 'CONTROL')
		bb.mkdirhier(controldir)
		try:
			ctrlfile = file(os.path.join(controldir, 'control'), 'w')
		except OSError:
			bb.utils.unlockfile(lf)
			raise bb.build.FuncFailed("unable to open control file for writing.")

		fields = []
		pe = d.getVar('PKGE', True)
		if pe and int(pe) > 0:
			fields.append(["Version: %s:%s-%s\n", ['PKGE', 'PKGV', 'PKGR']])
		else:
			fields.append(["Version: %s-%s\n", ['PKGV', 'PKGR']])
		fields.append(["Description: %s\n", ['DESCRIPTION']])
		fields.append(["Section: %s\n", ['SECTION']])
		fields.append(["Priority: %s\n", ['PRIORITY']])
		fields.append(["Maintainer: %s\n", ['MAINTAINER']])
		fields.append(["License: %s\n", ['LICENSE']])
		fields.append(["Architecture: %s\n", ['PACKAGE_ARCH']])
		fields.append(["OE: %s\n", ['PN']])
		fields.append(["Homepage: %s\n", ['HOMEPAGE']])

		def pullData(l, d):
			l2 = []
			for i in l:
				l2.append(d.getVar(i, True))
			return l2

		ctrlfile.write("Package: %s\n" % pkgname)
		# check for required fields
		try:
			for (c, fs) in fields:
				for f in fs:
					if localdata.getVar(f) is None:
						raise KeyError(f)
				# Special behavior for description...
				if 'DESCRIPTION' in fs:
					summary = localdata.getVar('SUMMARY', True) or localdata.getVar('DESCRIPTION', True) or "."
					description = localdata.getVar('DESCRIPTION', True) or "."
					description = textwrap.dedent(description).strip()
					ctrlfile.write('Description: %s\n' % summary)
					ctrlfile.write('%s\n' % textwrap.fill(description, width=74, initial_indent=' ', subsequent_indent=' '))
				else:
					ctrlfile.write(c % tuple(pullData(fs, localdata)))
		except KeyError:
			import sys
			(type, value, traceback) = sys.exc_info()
			ctrlfile.close()
			bb.utils.unlockfile(lf)
			raise bb.build.FuncFailed("Missing field for ipk generation: %s" % value)
		# more fields

		bb.build.exec_func("mapping_rename_hook", localdata)

		rdepends = bb.utils.explode_dep_versions(localdata.getVar("RDEPENDS", True) or "")
		rrecommends = bb.utils.explode_dep_versions(localdata.getVar("RRECOMMENDS", True) or "")
		rsuggests = bb.utils.explode_dep_versions(localdata.getVar("RSUGGESTS", True) or "")
		rprovides = bb.utils.explode_dep_versions(localdata.getVar("RPROVIDES", True) or "")
		rreplaces = bb.utils.explode_dep_versions(localdata.getVar("RREPLACES", True) or "")
		rconflicts = bb.utils.explode_dep_versions(localdata.getVar("RCONFLICTS", True) or "")

		if rdepends:
			ctrlfile.write("Depends: %s\n" % bb.utils.join_deps(rdepends))
		if rsuggests:
			ctrlfile.write("Suggests: %s\n" % bb.utils.join_deps(rsuggests))
		if rrecommends:
			ctrlfile.write("Recommends: %s\n" % bb.utils.join_deps(rrecommends))
		if rprovides:
			ctrlfile.write("Provides: %s\n" % bb.utils.join_deps(rprovides))
		if rreplaces:
			ctrlfile.write("Replaces: %s\n" % bb.utils.join_deps(rreplaces))
		if rconflicts:
			ctrlfile.write("Conflicts: %s\n" % bb.utils.join_deps(rconflicts))
		src_uri = localdata.getVar("SRC_URI", True) or "None"
		if src_uri:
			src_uri = re.sub("\s+", " ", src_uri)
			ctrlfile.write("Source: %s\n" % " ".join(src_uri.split()))
		ctrlfile.close()

		for script in ["preinst", "postinst", "prerm", "postrm"]:
			scriptvar = localdata.getVar('pkg_%s' % script, True)
			if not scriptvar:
				continue
			try:
				scriptfile = file(os.path.join(controldir, script), 'w')
			except OSError:
				bb.utils.unlockfile(lf)
				raise bb.build.FuncFailed("unable to open %s script file for writing." % script)
			scriptfile.write(scriptvar)
			scriptfile.close()
			os.chmod(os.path.join(controldir, script), 0755)

		conffiles_str = localdata.getVar("CONFFILES", True)
		if conffiles_str:
			try:
				conffiles = file(os.path.join(controldir, 'conffiles'), 'w')
			except OSError:
				bb.utils.unlockfile(lf)
				raise bb.build.FuncFailed("unable to open conffiles for writing.")
			for f in conffiles_str.split():
				conffiles.write('%s\n' % f)
			conffiles.close()

		os.chdir(basedir)
		ret = os.system("PATH=\"%s\" %s %s %s" % (localdata.getVar("PATH", True), 
                                                          localdata.getVar("OPKGBUILDCMD",True), pkg, pkgoutdir))
		if ret != 0:
			bb.utils.unlockfile(lf)
			raise bb.build.FuncFailed("opkg-build execution failed")

		bb.utils.prunedir(controldir)
		bb.utils.unlockfile(lf)

}

SSTATETASKS += "do_package_write_ipk"
do_package_write_ipk[sstate-name] = "deploy-ipk"
do_package_write_ipk[sstate-inputdirs] = "${PKGWRITEDIRIPK}"
do_package_write_ipk[sstate-outputdirs] = "${DEPLOY_DIR_IPK}"

python do_package_write_ipk_setscene () {
	sstate_setscene(d)
}
addtask do_package_write_ipk_setscene

python () {
    if d.getVar('PACKAGES', True) != '':
        deps = ' opkg-utils-native:do_populate_sysroot virtual/fakeroot-native:do_populate_sysroot'
        d.appendVarFlag('do_package_write_ipk', 'depends', deps)
        d.setVarFlag('do_package_write_ipk', 'fakeroot', "1")
        d.setVarFlag('do_package_write_ipk_setscene', 'fakeroot', "1")
}

python do_package_write_ipk () {
	bb.build.exec_func("read_subpackage_metadata", d)
	bb.build.exec_func("do_package_ipk", d)
}
do_package_write_ipk[dirs] = "${PKGWRITEDIRIPK}"
addtask package_write_ipk before do_package_write after do_package

PACKAGEINDEXES += "package_update_index_ipk;"
PACKAGEINDEXDEPS += "opkg-utils-native:do_populate_sysroot"
PACKAGEINDEXDEPS += "opkg-native:do_populate_sysroot"
