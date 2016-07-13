require pseudo.inc

SRC_URI = "http://downloads.yoctoproject.org/releases/pseudo/${BPN}-${PV}.tar.bz2 \
           file://0001-configure-Prune-PIE-flags.patch \
           file://fallback-passwd \
           file://fallback-group \
           file://moreretries.patch \
           "

SRC_URI[md5sum] = "ee38e4fb62ff88ad067b1a5a3825bac7"
SRC_URI[sha256sum] = "dac4ad2d21228053151121320f629d41dd5c0c87695ac4e7aea286c414192ab5"
