###SCRIPT_START_STEP2###

#!/bin/bash

set -e

export LUKS_PASSWD="password"
export ROOT_PASSWD="password"
export TIME_ZINE="EUROPE/BERLIN"
export HOSTNAME="ENCRYPTED_ROCK64"
export VOL_NAME="Vol"
export LVM_DEVICE="/dev/sda2"

# create lvm
pvcreate $LVM_DEVICE
vgcreate $VOL_NAME $LVM_DEVICE
lvcreate -L 5G -n root $VOL_NAME
lvcreate -L 500M -n swap $VOL_NAME
# the rest of space
lvcreate -l 100%FREE -n home $VOL_NAME


# create encrypted device
LUKS_PASSWD="password"
echo -n $LUKS_PASSWD | cryptsetup luksFormat -q -c aes-xts-plain64 -s 512 /dev/mapper/$VOL_NAME-root -

echo -n $LUKS_PASSWD |cryptsetup open /dev/mapper/$VOL_NAME-root root -


# mkfs with -F force option
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/mapper/root
  
# mount fs
mount /dev/mapper/root /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


# install rsync
pacman -S  --noconfirm rsync


# copy os to encrypted /root and mounted /boot
 rsync -aAXv /* /mnt --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/var/tmp/*,/run/*,/mnt/*,/media/*,/lost+found}


# enter chroot
arch-chroot /mnt /bin/bash <<EOF
echo "Setting and generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "Setting time zone"
# delete old link
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
echo "Setting hostname"
echo $hostname > /etc/hostname
sed -i "/localhost/s/$/ $hostname/" /etc/hosts
echo "Generating initramfs"
sed -i 's/^HOOKS.*/HOOKS="base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck"/' /etc/mkinitcpio.conf
mkinitcpio -p  linux-aarch64
echo "Setting root password"
echo "root:${ROOT_PASSWD}" | chpasswd
EOF
###SCRIPT_END_STEP2###
