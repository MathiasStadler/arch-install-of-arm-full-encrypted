###SCRIPT_START###

#!/bin/bash

set -e

# delete device we used just overwrite with 0
# if you have used device delete the old data carefully :-)
dd if=/dev/zero of=/dev/sda bs=4M status=progress | sync


# create two filesystem for boot and encrypted root
fdisk /dfdisk /dev/sda -C32 -H32 <<EOF
o
n
p
1

+2048M
t

n
p
2


t

p
w
EOF


# create lvm
VOL_NAME="Vol"
LVM_DEVICE="/dev/sda2"
pvcreate $LVM_DEVICE
vgcreate $VOL_NAME $LVM_DEVICE
lvcreate -L 10G -n root $VOL_NAME
lvcreate -L 500M -n swap $VOL_NAME
lvcreate -L 10G -n home $VOL_NAME


# create encrypted device
cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/mapper/$VOL_NAME-root
cryptsetup open /dev/mapper/$VOL_NAME-root root


# mkfs
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/mapper/root
  
# mount fs
mount /dev/mapper/root /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


# install rsync
pacman -S rsync


# copy os to encrypted /root and mounted /boot



###SCRIPT_END###
