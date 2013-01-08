require recipes-kernel/linux/linux-yocto.inc

KBRANCH = "standard/preempt-rt/base"
KBRANCH_qemuppc = "standard/preempt-rt/qemuppc"

LINUX_VERSION ?= "3.4.24"
LINUX_KERNEL_TYPE = "preempt-rt"

KMETA = "meta"

SRCREV_machine ?= "729e8634f75bf10582916eae6b5b96325785c001"
SRCREV_machine_qemuppc ?= "15ce18fac50c49ea4893b0d7ed3d0086ef9c7448"
SRCREV_meta ?= "7e0cd2990798aae80565baa17d3b6c771874f284"

PR = "${INC_PR}.0"
PV = "${LINUX_VERSION}+git${SRCPV}"

SRC_URI = "git://git.yoctoproject.org/linux-yocto-3.4.git;protocol=git;bareclone=1;branch=${KBRANCH},meta;name=machine,meta"

# Omit broken machines from COMPATIBLE_MACHINE
#   qemuppc hangs at boot
#   qemumips panics at boot
COMPATIBLE_MACHINE = "(qemux86|qemux86-64|qemuarm)"

# Functionality flags
KERNEL_FEATURES_append = " features/netfilter"
KERNEL_FEATURES_append = " features/taskstats"
KERNEL_FEATURES_append_qemux86 = " cfg/sound"
KERNEL_FEATURES_append_qemux86-64 = " cfg/sound"
KERNEL_FEATURES_append = " ${@bb.utils.contains("TUNE_FEATURES", "mx32", " cfg/x32", "" ,d)}"
