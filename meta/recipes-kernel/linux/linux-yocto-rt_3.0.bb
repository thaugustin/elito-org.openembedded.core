inherit kernel
require recipes-kernel/linux/linux-yocto.inc

KMACHINE = "common-pc"
KMACHINE_qemux86  = "common-pc"
KMACHINE_qemux86-64  = "common-pc-64"
KMACHINE_qemuarm  = "arm-versatile-926ejs"
KMACHINE_qemuppc  = "qemu-ppc32"
KMACHINE_qemumips = "mti-malta32-be"

KBRANCH = "yocto/standard/preempt-rt/base"
KBRANCH_qemuppc = "yocto/standard/preempt-rt/qemu-ppc32"

LINUX_VERSION ?= "3.0.18"
LINUX_KERNEL_TYPE = "preempt-rt"

SRCREV_machine ?= "2f9d925f5681eaae7f341cc1270c739e8b329c03"
SRCREV_machine_qemuppc ?= "c66f7ef2315010756c8c97af6b13d52f9f18c03b"
SRCREV_meta ?= "b78a519841bd8b477cad599af8d38df6760445c1"

PR = "r1"
PV = "${LINUX_VERSION}+git${SRCPV}"

SRC_URI = "git://git.yoctoproject.org/linux-yocto-3.0.git;protocol=git;nocheckout=1;branch=${KBRANCH},meta;name=machine,meta"

# Omit broken machines from COMPATIBLE_MACHINE
#   qemuppc hangs at boot
#   qemumips panics at boot
COMPATIBLE_MACHINE = "(qemux86|qemux86-64|qemuarm)"

# Functionality flags
KERNEL_FEATURES = "features/netfilter"
KERNEL_FEATURES_append = " features/taskstats"
KERNEL_FEATURES_append_qemux86 = " cfg/sound"
KERNEL_FEATURES_append_qemux86-64 = " cfg/sound"

require recipes-kernel/linux/linux-tools.inc
