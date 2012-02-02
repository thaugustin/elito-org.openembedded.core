def get_imagecmds(d):
    cmds = "\n"
    old_overrides = d.getVar('OVERRIDES', 0)

    types = d.getVar('IMAGE_FSTYPES', True).split()
    # Live images will be processed via inheriting bbclass and 
    # does not get processed here.
    # live images also depend on ext3 so ensure its present
    if "live" in types:
        if "ext3" not in types:
            types.append("ext3")
        types.remove("live")

    for type in types:
        localdata = bb.data.createCopy(d)
        localdata.setVar('OVERRIDES', '%s:%s' % (type, old_overrides))
        bb.data.update_data(localdata)
        localdata.setVar('type', type)
        cmd = localdata.getVar("IMAGE_CMD", True)
        localdata.setVar('cmd', cmd)
        cmds += localdata.getVar("runimagecmd", True)
    return cmds

_image_rootfs_size_kib = "${@(int('${IMAGE_ROOTFS_SIZE}') + 1023) / 1024}"
_image_rootfs_extra_space_kib = "${@(int('${IMAGE_ROOTFS_EXTRA_SPACE}') + 1023) / 1024}"

runimagecmd () {
	# Image generation code for image type ${type}
	ROOTFS_SIZE=`du -ks ${IMAGE_ROOTFS}|awk '{base_size = ($1 * ${IMAGE_OVERHEAD_FACTOR});  OFMT = "%.0f" ; print ((base_size > ${_image_rootfs_size_kib} ? base_size : ${_image_rootfs_size_kib}) + ${_image_rootfs_extra_space_kib}) }'`
	${cmd}
	cd ${DEPLOY_DIR_IMAGE}/
	rm -f ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${type}
	ln -s ${IMAGE_NAME}.rootfs.${type} ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.${type}
}


XZ_COMPRESSION_LEVEL ?= "-e -9"
XZ_INTEGRITY_CHECK ?= "crc32"

IMAGE_CMD_jffs2 = "mkfs.jffs2 --root=${IMAGE_ROOTFS} --output=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.jffs2 ${EXTRA_IMAGECMD}"
IMAGE_CMD_sum.jffs2 = "${IMAGE_CMD_jffs2} && sumtool -i ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.jffs2 \
	-o ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.sum.jffs2 -n ${EXTRA_IMAGECMD}"

IMAGE_CMD_cramfs = "mkcramfs ${IMAGE_ROOTFS} ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.cramfs ${EXTRA_IMAGECMD}"

IMAGE_CMD_ext2 () {
	rm -rf ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN} && mkdir ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}
	genext2fs -b $ROOTFS_SIZE -d ${IMAGE_ROOTFS} ${EXTRA_IMAGECMD} ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext2
	mv ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext2 ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext2
	rmdir ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}
}
IMAGE_CMD_ext2.gz () {
	rm -rf ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN} && mkdir ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}
	genext2fs -b $ROOTFS_SIZE -i 4096 -d ${IMAGE_ROOTFS} ${EXTRA_IMAGECMD} ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext2
	gzip -f -9 ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext2
	mv ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext2.gz ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext2.gz
	rmdir ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}
}
IMAGE_CMD_ext2.bz2 () {
	rm -rf ${DEPLOY_DIR_IMAGE}/tmp.gz && mkdir ${DEPLOY_DIR_IMAGE}/tmp.gz
	genext2fs -b $ROOTFS_SIZE -i 4096 -d ${IMAGE_ROOTFS} ${EXTRA_IMAGECMD} ${DEPLOY_DIR_IMAGE}/tmp.gz/${IMAGE_NAME}.rootfs.ext2
	bzip2 -f -9 ${DEPLOY_DIR_IMAGE}/tmp.gz/${IMAGE_NAME}.rootfs.ext2
	mv ${DEPLOY_DIR_IMAGE}/tmp.gz/${IMAGE_NAME}.rootfs.ext2.bz2 ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext2.bz2
	rmdir ${DEPLOY_DIR_IMAGE}/tmp.gz
}
IMAGE_CMD_ext2.lzma () {
	rm -rf ${DEPLOY_DIR_IMAGE}/tmp.gz && mkdir ${DEPLOY_DIR_IMAGE}/tmp.gz
	genext2fs -b $ROOTFS_SIZE -i 4096 -d ${IMAGE_ROOTFS} ${EXTRA_IMAGECMD} ${DEPLOY_DIR_IMAGE}/tmp.gz/${IMAGE_NAME}.rootfs.ext2
	lzma -f -7 ${DEPLOY_DIR_IMAGE}/tmp.gz/${IMAGE_NAME}.rootfs.ext2
	mv ${DEPLOY_DIR_IMAGE}/tmp.gz/${IMAGE_NAME}.rootfs.ext2.lzma ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext2.lzma
	rmdir ${DEPLOY_DIR_IMAGE}/tmp.gz
}

IMAGE_CMD_ext3 () {
	genext2fs -b $ROOTFS_SIZE -i 4096 -d ${IMAGE_ROOTFS} ${EXTRA_IMAGECMD} ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext3
	tune2fs -j ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext3
}
IMAGE_CMD_ext3.gz () {
	rm -rf ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN} && mkdir ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}
	genext2fs -b $ROOTFS_SIZE -i 4096 -d ${IMAGE_ROOTFS} ${EXTRA_IMAGECMD} ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext3
	tune2fs -j ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext3
	gzip -f -9 ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext3
	mv ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext3.gz ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext3.gz
	rmdir ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}
}

oe_mkext4fs () {
	genext2fs -b $ROOTFS_SIZE -i 4096 -d ${IMAGE_ROOTFS} ${EXTRA_IMAGECMD} $1
	tune2fs -O extents,uninit_bg,dir_index,has_journal $1
	e2fsck -yfDC0 $1 || chk=$?
	case $chk in
	0|1|2)
	    ;;
	*)
	    return $chk
	    ;;
	esac
}

IMAGE_CMD_ext4 () {
	oe_mkext4fs ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext4
}
IMAGE_CMD_ext4.gz () {
	rm -rf ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN} && mkdir ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}
	oe_mkext4fs ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext4
	gzip -f -9 ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext4
	mv ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}/${IMAGE_NAME}.rootfs.ext4.gz ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ext4.gz
	rmdir ${DEPLOY_DIR_IMAGE}/tmp.gz-${PN}
}

IMAGE_CMD_btrfs () {
	mkfs.btrfs -b `expr ${ROOTFS_SIZE} \* 1024` ${EXTRA_IMAGECMD} -r ${IMAGE_ROOTFS} ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.btrfs
}

IMAGE_CMD_squashfs = "mksquashfs ${IMAGE_ROOTFS} ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.squashfs ${EXTRA_IMAGECMD} -noappend"
IMAGE_CMD_squashfs-lzma = "mksquashfs-lzma ${IMAGE_ROOTFS} ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.squashfs-lzma ${EXTRA_IMAGECMD} -noappend"
IMAGE_CMD_tar = "cd ${IMAGE_ROOTFS} && tar -cvf ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.tar ."
IMAGE_CMD_tar.gz = "cd ${IMAGE_ROOTFS} && tar -zcvf ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.tar.gz ."
IMAGE_CMD_tar.bz2 = "cd ${IMAGE_ROOTFS} && tar -jcvf ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.tar.bz2 ."
IMAGE_CMD_tar.xz = "cd ${IMAGE_ROOTFS} && tar --xz -cvf ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.tar.xz ."

CPIO_TOUCH_INIT () {
	if [ ! -L ${IMAGE_ROOTFS}/init ]
	then
	touch ${IMAGE_ROOTFS}/init
	fi
}
IMAGE_CMD_cpio () {
	${CPIO_TOUCH_INIT}
	cd ${IMAGE_ROOTFS} && (find . | cpio -o -H newc >${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.cpio)
}
IMAGE_CMD_cpio.gz () {
	${CPIO_TOUCH_INIT}
	cd ${IMAGE_ROOTFS} && (find . | cpio -o -H newc | gzip -c -9 >${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.cpio.gz)
}
IMAGE_CMD_cpio.xz () {
	${CPIO_TOUCH_INIT}
	cd ${IMAGE_ROOTFS} && (find . | cpio -o -H newc | xz -c ${XZ_COMPRESSION_LEVEL} --check=${XZ_INTEGRITY_CHECK} > ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.cpio.xz) ${EXTRA_IMAGECMD}
}
IMAGE_CMD_cpio.lzma () {
	${CPIO_TOUCH_INIT}
	cd ${IMAGE_ROOTFS} && (find . | cpio -o -H newc | xz --format=lzma -c ${XZ_COMPRESSION_LEVEL} --check=${XZ_INTEGRITY_CHECK} >${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.cpio.lzma) ${EXTRA_IMAGECMD}
}

UBI_VOLNAME ?= "${MACHINE}-rootfs"

IMAGE_CMD_ubi () {
	echo \[ubifs\] > ubinize.cfg 
	echo mode=ubi >> ubinize.cfg
	echo image=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ubifs >> ubinize.cfg 
	echo vol_id=0 >> ubinize.cfg 
	echo vol_type=dynamic >> ubinize.cfg 
	echo vol_name=${UBI_VOLNAME} >> ubinize.cfg 
	echo vol_flags=autoresize >> ubinize.cfg
	mkfs.ubifs -r ${IMAGE_ROOTFS} -o ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ubifs ${MKUBIFS_ARGS} && ubinize -o ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ubi ${UBINIZE_ARGS} ubinize.cfg
}
IMAGE_CMD_ubifs = "mkfs.ubifs -r ${IMAGE_ROOTFS} -o ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}.rootfs.ubifs ${MKUBIFS_ARGS}"

EXTRA_IMAGECMD = ""
EXTRA_IMAGECMD_jffs2 ?= "--pad --little-endian --eraseblock=0x40000"
# Change these if you want default genext2fs behavior (i.e. create minimal inode number)
EXTRA_IMAGECMD_ext2 ?= "-i 8192"
EXTRA_IMAGECMD_ext2.gz ?= "-i 8192"
EXTRA_IMAGECMD_ext3 ?= "-i 8192"
EXTRA_IMAGECMD_ext3.gz ?= "-i 8192"
EXTRA_IMAGECMD_btrfs ?= ""

IMAGE_DEPENDS = ""
IMAGE_DEPENDS_jffs2 = "mtd-utils-native"
IMAGE_DEPENDS_sum.jffs2 = "mtd-utils-native"
IMAGE_DEPENDS_cramfs = "cramfs-native"
IMAGE_DEPENDS_ext2 = "genext2fs-native"
IMAGE_DEPENDS_ext2.gz = "genext2fs-native"
IMAGE_DEPENDS_ext2.bz2 = "genext2fs-native"
IMAGE_DEPENDS_ext2.lzma = "genext2fs-native xz-native"
IMAGE_DEPENDS_ext3 = "genext2fs-native e2fsprogs-native"
IMAGE_DEPENDS_ext3.gz = "genext2fs-native e2fsprogs-native"
IMAGE_DEPENDS_ext4 = "genext2fs-native e2fsprogs-native"
IMAGE_DEPENDS_ext4.gz = "genext2fs-native e2fsprogs-native"
IMAGE_DEPENDS_btrfs = "btrfs-tools-native"
IMAGE_DEPENDS_squashfs = "squashfs-tools-native"
IMAGE_DEPENDS_squashfs-lzma = "squashfs-lzma-tools-native"
IMAGE_DEPENDS_tar.xz = "tar-native xz-native"
IMAGE_DEPENDS_cpio.lzma = "xz-native"
IMAGE_DEPENDS_cpio.xz = "xz-native"
IMAGE_DEPENDS_ubi = "mtd-utils-native"
IMAGE_DEPENDS_ubifs = "mtd-utils-native"

# This variable is available to request which values are suitable for IMAGE_FSTYPES
IMAGE_TYPES = "jffs2 sum.jffs2 cramfs ext2 ext2.gz ext2.bz2 ext3 ext3.gz ext2.lzma btrfs live squashfs squashfs-lzma ubi tar tar.gz tar.bz2 tar.xz cpio cpio.gz cpio.xz cpio.lzma"
