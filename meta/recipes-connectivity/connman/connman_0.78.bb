require connman.inc

PR = "r7"

# 0.78 tag
SRCREV = "4bd503c8218bdc278ca432f5fad34654de0cbc44"
SRC_URI  = "git://git.kernel.org/pub/scm/network/connman/connman.git \
            file://add_xuser_dbus_permission.patch \
            file://ethernet_default.patch \
            file://disable_alg-test.patch \
            file://connman"
S = "${WORKDIR}/git"
