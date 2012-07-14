DESCRIPTION = "Basic image without X support suitable for Linux Standard Base \
(LSB) implementations. It includes the full meta-toolchain, plus development \
headers and libraries to form a standalone SDK."

IMAGE_FEATURES += "apps-console-core tools-sdk dev-pkgs ssh-server-openssh \
	tools-debug tools-profile tools-testapps debug-tweaks"


IMAGE_INSTALL = "\
    ${CORE_IMAGE_BASE_INSTALL} \
    task-core-basic \
    task-core-lsb \
    kernel-dev \
    "

inherit core-image
