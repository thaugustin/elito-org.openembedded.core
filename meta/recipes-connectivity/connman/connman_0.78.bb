require connman.inc

PR = "r7+2"

# 0.78 tag
SRCREV = "e8dbd3160116346eae8613c242dd8f4db3ed1781"
SRC_URI  = "git://git.kernel.org/pub/scm/network/connman/connman.git \
            file://add_xuser_dbus_permission.patch \
            file://ethernet_default.patch \
            file://disable_alg-test.patch \
            file://connman"
S = "${WORKDIR}/git"
