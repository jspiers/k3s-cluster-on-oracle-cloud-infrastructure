#!/bin/bash
set -ex
IMAGE_FILENAME="openSUSE-MicroOS.aarch64-ContainerHost-kvm-and-xen.qcow2"
DOWNLOAD_URL="https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/$IMAGE_FILENAME"
curl -LO $DOWNLOAD_URL
qemu-img convert -p -f qcow2 -O host_device $IMAGE_FILENAME /dev/sda
sgdisk -e /dev/sda
parted -s /dev/sda resizepart 4 "99%"
parted -s /dev/sda mkpart primary ext2 "99%" "100%"
partprobe /dev/sda && udevadm settle && fdisk -l /dev/sda
mount /dev/sda4 /mnt/ && btrfs filesystem resize max /mnt && umount /mnt
mke2fs -L ignition /dev/sda5
mount /dev/sda5 /mnt
mkdir /mnt/ignition
cp /root/config.ign /mnt/ignition/config.ign
mkdir /mnt/combustion
cp /root/script /mnt/combustion/script
umount /mnt