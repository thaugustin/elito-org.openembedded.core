require connman.inc

PR = "r7+1"

# 0.78 tag
SRCREV = "ee6107560e96ce8047939edb5fac81d11f29dd11"
SRC_URI  = "git://git.kernel.org/pub/scm/network/connman/connman.git \
            file://add_xuser_dbus_permission.patch \
            file://ethernet_default.patch \
            file://disable_alg-test.patch \
            file://connman"
S = "${WORKDIR}/git"
