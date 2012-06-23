SUMMARY = "Performance analysis tools for Linux"
DESCRIPTION = "Performance counters for Linux are a new kernel-based \
subsystem that provide a framework for all things \
performance analysis. It covers hardware level \
(CPU/PMU, Performance Monitoring Unit) features \
and software features (software counters, tracepoints) \
as well."

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"

PR = "r0"

BUILDPERF_libc-uclibc = "no"

DEPENDS = "virtual/kernel \
           virtual/${MLPREFIX}libc \
           ${MLPREFIX}elfutils \
           ${MLPREFIX}binutils \
          "
RDEPENDS_${PN} += "elfutils perl python"

PROVIDES = "virtual/perf"

inherit kernel-arch

S = "${STAGING_KERNEL_DIR}"
B = "${WORKDIR}/${BPN}-${PV}"

EXTRA_OEMAKE = \
		'-C ${S}/tools/perf \
		O=${B} \
		CROSS_COMPILE=${TARGET_PREFIX} \
		ARCH=${ARCH} \
		CC="${CC}" \
		AR="${AR}" \
		prefix=/usr \
		NO_GTK2=1 NO_NEWT=1 NO_DWARF=1 \
		'

do_compile() {
	oe_runmake all
}

do_install() {
	oe_runmake DESTDIR=${D} install
}

PACKAGE_ARCH = "${MACHINE_ARCH}"

