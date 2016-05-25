KBRANCH ?= "standard/tiny/common-pc"
LINUX_KERNEL_TYPE = "tiny"
KCONFIG_MODE = "--allnoconfig"

require recipes-kernel/linux/linux-yocto.inc

LINUX_VERSION ?= "4.1.24"

KMETA = "kernel-meta"
KCONF_BSP_AUDIT_LEVEL = "2"

SRCREV_machine ?= "ecc983477682203619da0e456fa4a8689ac41097"
SRCREV_meta ?= "d6e1f4bfc254c677a8dfef92f0ad8c78bdeeea75"

PV = "${LINUX_VERSION}+git${SRCPV}"

SRC_URI = "git://git.yoctoproject.org/linux-yocto-4.1.git;branch=${KBRANCH};name=machine \
           git://git.yoctoproject.org/yocto-kernel-cache;type=kmeta;name=meta;branch=yocto-4.1;destsuffix=${KMETA}"

COMPATIBLE_MACHINE = "(qemux86$)"

# Functionality flags
KERNEL_FEATURES = ""
