# arch install of arm full encrypted

- e.g. on rock64

[ ] with dropbear
[x] lvm
[x] luks

## TL;DR

- used if available a serial modem, very helpfully in unclear situation

```bash
sudo  minicom -s -D /dev/ttyUSB0 -b 1500000 --color=on
```

- plug in a usb storage device that will used as encrypted device
- enable spi boot on rock64 via flash uboot on spi => [see here](https://github.com/ayufan-rock64/linux-build/blob/master/recipes/flash-spi.md)
- prepare and boot via sd-card the rock64 => [follow this steps](https://archlinuxarm.org/platforms/armv8/rockchip/rock64#installation)
- boot from sd card
- install git and clone this repo in alarm home  

```bash
pacmann -S git && git clone https://github.com/MathiasStadler/arch-install-of-arm-full-encrypted.git
```

- create both script with instruction from the README.md

```bash
# get script into script file
sed -n '/^###SCRIPT_START_STEP1###/,/^###SCRIPT_END_STEP1###/p' README.md >arch-install-encrypted-STEP-1.sh

sed -n '/^###SCRIPT_START_STEP2###/,/^###SCRIPT_END_STEP2###/p' README.md >arch-install-encrypted-STEP-2.sh
```

- run both script

```bash
bash +x arch-install-encrypted-STEP-1.sh

# check the output from fdisk some storage device need a reboot

bash +x arch-install-encrypted-STEP-1.sh
```

- shutdown thr rock64
- eject the sd-card and
- cross the finger and boot the encrypted rock64 from usb mounted device
- the password was *password* :-)

## sources

```txt
# install tutorial lvm luks
http://turlucode.com/arch-linux-install-guide-efi-lvm-luks/#1499978715503-ad8f936f-d6c9

# base install
http://turlucode.com/arch-linux-install-guide-step-1-basic-installation/

# install pactrap
https://www.archlinux.org/packages/?name=arch-install-scripts

# arch rsync copy system
https://www.rdeeson.com/weblog/157/moving-arch-linux-to-a-new-ssd-with-rsync

# 2nd partion for root
https://github.com/procount/pinn/issues/58

# encrypted dropbear
https://raspberrypi.stackexchange.com/questions/67051/raspberry-pi-3-with-archarm-and-encrypted-disk-will-not-boot-how-can-be-identif


# another sample for installation script
https://gist.github.com/rasschaert/0bb7ebc506e26daee585


# mkinitcpio replace udev with systemd
https://bbs.archlinux.org/viewtopic.php?id=243253&p=2
```

## boot.scr

```bash
# add for verbose
echo "Boot script loaded from ${devtype} ${devnum} distro_bootpart=${distro_bootpart}"
```

## script

```bash

###SCRIPT_START_STEP1###

#!/bin/bash

set -e

export LUKS_PASSWD="password"
export ROOT_PASSWD="password"
export TIME_ZINE="EUROPE/BERLIN"
export HOSTNAME="ENCRYPTED_ROCK64"
export VOL_NAME="Vol"
export LVM_DEVICE="/dev/sda2"

# delete device we used just overwrite with 0
# if you have used device delete the old data carefully :-)
dd if=/dev/zero of=/dev/sda bs=4M status=progress count=64| sync

sync

echo "sleep 10 second before we will start the next steps"
sleep 10

# create two filesystem for boot and encrypted root
fdisk /dev/sda <<EOF
o
n
p
1
32768
4227071
t
83
n
p
2
4227072

t
2
83
p
w
EOF

echo "Please reboot before you start step2 !"

###SCRIPT_END_STEP1###

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

# open encrypted device
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

# get script into script file
sed -n '/^###SCRIPT_START_STEP1###/,/^###SCRIPT_END_STEP1###/p' README.md >arch-install-encrypted-STEP-1.sh

sed -n '/^###SCRIPT_START_STEP2###/,/^###SCRIPT_END_STEP2###/p' README.md >arch-install-encrypted-STEP-2.sh

```

## mount encrypted devices

```bash
LUKS_PASSWD="password"
VOL_NAME="Vol"
echo -n $LUKS_PASSWD |cryptsetup open /dev/mapper/$VOL_NAME-root root -
mount /dev/mapper/root /mnt
mount /dev/sda1 /mnt/boot/
```