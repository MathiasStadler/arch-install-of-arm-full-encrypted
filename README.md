# arch install of arm full encrypted

- e.g. on rock64

[x] with tinyssh
[x] lvm
[x] luks
[ ] static ip

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

# tinyssh
https://tinyssh.org/install.html

# arch network w/o networkmanager
https://wiki.archlinux.de/title/Statische_IP
```

## scripts

```bash

###SCRIPT_START_STEP1###

#!/bin/bash

set -e

export LUKS_PASSWD="password"
export ROOT_PASSWD="password"
export TINYSSH_PASSWORD="password"
export TIME_ZINE="EUROPE/BERLIN"
export HOSTNAME="ENCRYPTED_ROCK64"
export VOL_NAME="Vol"
export LVM_DEVICE="/dev/sda2"
export ETH0_STATIC_IP="192.168.178.250"
export ETH0_CIDR="24"
export ETH0_NETMASK="255.255.255.0"
export ETH0_GATEWAY="192.168.178.1"

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

echo "check output from the last fdisk command"
echo " on some device is a reboot necessary"
echo " check careful the status and in any unclear cases REBOOT :-)"
echo " start step2 "

###SCRIPT_END_STEP1###

###SCRIPT_START_STEP2###

#!/bin/bash

set -e

export LUKS_PASSWD="password"
export ROOT_PASSWD="password"
export TINYSSH_PASSWORD="password"
export TIME_ZINE="EUROPE/BERLIN"
export HOSTNAME="ENCRYPTED_ROCK64"
export VOL_NAME="Vol"
export LVM_DEVICE="/dev/sda2"
export ETH0_STATIC_IP="192.168.178.250"
export ETH0_CIDR="24"
export ETH0_NETMASK="255.255.255.0"
export ETH0_GATEWAY="192.168.178.1"
export ETH0_DNS_1="192.168.178.245"

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

# copy boot.txt_encrypted to /mnt/boot
cp ./boot.txt_encrypted /mnt/boot

# copy mksrc.sh to /mnt/boot
cp ./mksrc.sh /mnt/boot

# enter chroot
arch-chroot /mnt /bin/bash <<EOF
echo "Setting and generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "Setting time zone"
# delete old link is there
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
# found UUID from Vol-root
VOL_ROOT_UUID=$(blkid | sed -n '/Vol-root/s/.*UUID=\"\([^\"]*\)\".*/\1/p')
echo "Vol-root UUID => ${VOL_ROOT_UUID}"
echo "replace the UUID in boot.txt"
sed -i "s/LVM_ROOT_MAPPER_UUID/${VOL_ROOT_UUID}/" /boot/boot.txt
echo "create boot.scr"
cd boot && ./mksrc.sh

# default user for sd card
username="alarm"

# install sudo
pacman -Sy sudo

# add user to group wheel
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# add alarm ( default user from sd-card ) to group wheel
usermod -a -G wheel alarm

# switch user to  $username
su $username

# install package from default repository for make packages from AUR
sudo pacman -S binutils gcc pkg-config make fakeroot patch

# crate dir for build something
mkdir ~/build

# build package package-query
cd ~/build
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/package-query.tar.gz
tar -xvzf package-query.tar.gz
cd package-query
makepkg -si --noconfirm

# build package yaourt
cd ~/build
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/yaourt.tar.gz
tar -xvzf yaourt.tar.gz
cd yaourt
makepkg -si --noconfirm


# enable  ucspi mkinitcpio-wrapper for aarch64
# a HACK default not enable for architecture aarch64
cd ~/build/
git clone https://aur.archlinux.org/ucspi-tcp.git
cd ucspi-tcp
# add aarch in the line arch to the other architecture
sed -i 's/^arch.*$/arch=(\x27i686\x27 \x27x86_64\x27 \x27aarch64\x27)/' PKGBUILD
makepkg -si --noconfirm

# install mkinitcpio wrapper from AUR
cd ~/build
yaourt -S --noconfirm mkinitcpio-utils mkinitcpio-netconf mkinitcpio-tinyssh

# switch back to root
exit

# prepare tinyssh kez
# ATTENTION /tmp will be delete after each reboot we wont that :-)
mkdir -p /tmp/tinyssh
# passphrase = password
ssh-keygen -t ed25519  -C "kez for tinyssh" -P "${TINYSSH_PASSWORD}" -f "/tmp/tinyssh/kez" -q
# add key 
grep ssh-ed25519:* /tmp/tinyssh/kez.pub |sudo tee -a /etc/tinyssh/root_key
# protect kez :-?
chmod 0400 /etc/tinyssh/root_key
chmod 0400 /etc/tinyssh/

echo "ATTENTION Don't forget save your private kez "

# add hooks for prepare initramfs
sudo sed -i 's/^\(HOOKS=.*\)encrypt\(.*\)$/\1netconf tinyssh encryptssh\2/' /etc/mkinitcpio.conf

# make new initramfs
mkinitcpio -p linux-aarch64


# build BOOT_NETWORK_CONFIG for bootargs
#BOOT_NETWORK_CONFIG="ip=192.168.0.10::192.168.0.1:255.255.255.0:pi:eth0:none"
BOOT_NETWORK_CONFIG="ip=$ETH0_STATIC_IP::$ETH0_GATEWAY:$ETH0_NETMASK:$HOSTNAME:eth0:none"
# add ip=dhcp to setenvbootcmds in boot.scr file
# necessary for tinyssh ip during the boot phase
# sudo sed -i 's/^setenv bootargs\(.*\)$/& ip=dhcp/' /boot/boot.txt
sudo sed -i "s/^setenv bootargs\(.*\)$/& $BOOT_NETWORK_CONFIG/" /boot/boot.txt
# create boot.scr
cd /boot && ./mksrc.sh


echo "# kiss approach"
echo "# NO any network manager"
echo "# NO resolve services "
systemctl stop dbus-org.freedesktop.network1.service
systemctl disable dbus-org.freedesktop.network1.service
systemctl stop dbus-org.freedesktop.resolve1.service
systemctl disable dbus-org.freedesktop.resolve1.service

# remove link if there for  /etc/resolv.conf
rm -rf  /etc/resolv.conf

# write new one
echo "nameserver $ETH0_DNS_1" | tee -a /etc/resolv.conf



# TODO to be check
systemctl disable dbus-org.freedesktop.timesync1.service




# sync
sync

# leave arch_chroot
exit

EOF





# cross the finger and reboot
shutdown -Fr now

###SCRIPT_END_STEP2###

# get script into script file
sed -n '/^###SCRIPT_START_STEP1###/,/^###SCRIPT_END_STEP1###/p' README.md >arch-install-encrypted-STEP-1.sh

sed -n '/^###SCRIPT_START_STEP2###/,/^###SCRIPT_END_STEP2###/p' README.md >arch-install-encrypted-STEP-2.sh

```

## mount encrypted devices if you start from sd card - rescue boot

```bash
LUKS_PASSWD="password"
VOL_NAME="Vol"
echo -n $LUKS_PASSWD |cryptsetup open /dev/mapper/$VOL_NAME-root root -
mount /dev/mapper/root /mnt
mount /dev/sda1 /mnt/boot/
```

## encrypt volume via tinyssh

```bash
# login
ssh -i kez root@<ip from sbc>

#search for ip from sbc
# nmap -sn <network >/<netmask>
nmap -sn 192.168.178.0/24

```


## steps
default via 192.168.178.1 dev eth0 proto static 
192.168.178.0/24 dev eth0 proto kernel scope link src 192.168.178.250 


# disabkle dhcp services

# nicht vergessen
rm /etc/system/network/ snXXXX
  491  systemctl list-unit-files | grep enabled
  492  systemctl disable dbus-org.freedesktop.network1.service
  493  systemctl disable dbus-org.freedesktop.resolve1.service
  494  systemctl disable dbus-org.freedesktop.timesync1.service
  495  systemctl list-unit-files | grep enabled
  496  systemctl disable remote-fs.target
  497  systemctl disable dbus-org.freedesktop.timesync1.service
  498  systemctl list-unit-files | grep enabled
  502  history |grep systemctl
[root@ENCRYPTED_ROCK64 alarm]# 
