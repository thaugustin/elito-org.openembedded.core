SUMMMARY = "URI testcase"
SECTION = "base"
LICENSE = "GPLv2"

PACKAGE_ARCH = "all"
INHIBIT_DEFAULT_DEPS = "1"
PACKAGES = ""
PRIORITY = "optional"

SRC_URI = "\
  file://test0.txt \
  file://test1.txt;subdir=a \
  file://test2.txt;subdir=${S} \
  file://test3.patch;subdir=b;apply=no \
  file://A/test4.txt \
  file://A/test5.txt;subdir=c \
  file://test6.txt;subdir=${S}/a \
  file://test6.patch \
\
  file://B \
  file://C;subdir=${S} \
\
  file://${S}/a/test6.txt;subdir=${S}/b \
"

S = "${WORKDIR}/tests"

inherit test

do_test() {
    test -e ${WORKDIR}/test0.txt
    test -e ${WORKDIR}/a/test1.txt
    test -e ${S}/test2.txt
    test -e ${WORKDIR}/b/test3.patch
    test -e ${WORKDIR}/A/test4.txt
    test -e ${WORKDIR}/c/test5.txt
    grep -q 'patched test6' ${S}/a/test6.txt

    test -e ${WORKDIR}/B/file-B0.txt
    test -e ${WORKDIR}/B/file-B1.txt

    test -e ${S}/C/file-C0.txt
    test -e ${S}/C/file-C1.txt

}
