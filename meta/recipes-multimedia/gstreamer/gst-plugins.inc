DESCRIPTION = "Plugins for GStreamer"
HOMEPAGE = "http://gstreamer.freedesktop.org/"
BUGTRACKER = "https://bugzilla.gnome.org/enter_bug.cgi?product=Gstreamer"
SECTION = "multimedia"
DEPENDS = "gstreamer"

inherit autotools pkgconfig

FILESPATH =. "${FILE_DIRNAME}/gst-plugins:"

SRC_URI = "http://gstreamer.freedesktop.org/src/${BPN}/${BPN}-${PV}.tar.bz2"

EXTRA_OECONF = "--disable-valgrind --disable-debug --disable-examples "
EXTRA_OECONF += "${@base_contains('DISTRO_FEATURES','x11','','--disable-x', d)}"

acpaths = "-I ${S}/common/m4 -I ${S}/m4"

require gst-plugins-package.inc

PACKAGES_DYNAMIC = "${PN}-*"

