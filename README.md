# arch install of arm full encrypted

[] with dropbear
[] luks

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

## presteps

- create a bootable sd card with the last arch for arm
- check your usb3 interface  and disk are detect
- check you can write on your disk device

- enable epi boot of rock64 sbc board

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


## steps

```bash
 dhcpcd 
    2  cd /boot
    3  ls
    4  cd dtbs/
    5  ls
    6  cd rockchip/
    7  ls
    8  ls -ltr
    9  cd ..
   10  cp -a rockchip/ rockchip/
   11  cp -a rockchip/ rockchip_save
   12  cp -a rockchip/ ~/rockchip_save
   13  sync
   14  cd
   15  pwd
   16  cd /root
   17  ls
   18  cd rockchip_save/
   19  ls
   20  cd
   21  uname -a
   22  pacman -Syu
   23  pacman-key --init
   24  pacman-key --populate archlinuxarm
   25  pacman -Syu
   26  cd /boot/dtbs/
   27  ls
   28  cd rockchip
   29  ls
   30  ls -l
   31  pwd
   32  ls -l /root/rockchip_save/
   33  ls -l rk3328
   34  ls -l rk3328*
   35  ip a
   36  dhcpcd 
   37  uname -a
   38  reboot
   39  dhcpcd 
   40  ls
   41  cd /boot/dtbs/
   42  ls
   43  cd rockchip
   44  ls -l
   45  ls -l rk3328-rock64.dtb 
   46  ls -l /root/rockchip_save/rk3328-rock64.dtb 
   47  cp /boot/dtbs/rockchip/rk3328-rock64.dtb /boot/dtbs/rockchip/rk3328-rock64.dtb_save 
   48  cp /root/rockchip_save/rockchip/rk3328-rock64.dtb /boot/dtbs/rockchip/rk3328-rock64.dtb
   49  lsusb
   50  uname -a
   51  uname -a
   52  uname -a
   53  reboot
   54  lsusb
   55  fdisk -ll
   56  fdisk /dev/sda
   57  lsblk
   58  blkid 
   59  pvcreate /dev/sda2
   60  vgcreate Vol /dev/sda2
   61  lvcreate -L 10G -n root Vol
   62  lvcreate -L 500M -n swap Vol
   63  lvcreate -L 10G -n home Vol
   64  cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/mapper/Vol-root
   65  cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/mapper/Vol-root
   66  cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/mapper/Vol-root
   67* cryptsetup open /dev/mapper/Vol-root root
   68  mkfs.ext4 /dev/mapper/root
   69  mkfs.vfat -F32 /dev/sda1
   70  pacman -S mkfs.vfat
   71  pacman -S dosfstools
   72  mkfs.vfat -F32 /dev/sda1
   73  mount /dev/mapper/root /mnt
   74  mkdir /mnt/boot
   75  mount /dev/sda1 /mnt/boot
   76  vgdisplay 
   77  lvdisplay 
   78  cd /mnt/home
   79  cd /mnt
   80  ls
   81  mkdir home
   82  cd
   83  pacstrap -i /mnt base base-devel
   84  pacman-key --init
   85  pacman-key --populate archlinuxarm
   86  pacman -Syu
   87  which pacstrap
   88  pacman -S arch-install-scripts
   89  pacstrap -i /mnt base base-devel



 127  vi /boot/loader/entries/arch-encrypted.conf 
  128  vi /boot/loader/entries/arch-encrypted.conf 
  129  vi /etc/mkinitcpio.conf 
  130  vi /etc/mkinitcpio.conf 
  131  CD
  132  cd
  133  mkdir -m 700 /etc/luks-keys
  134  dd if=/dev/random of=/etc/luks-keys/home bs=1 count=256 status=progress
  135  ls -l /etc/luks-keys/home 
  136  cat /etc/luks-keys/home 
  137  cryptsetup luksFormat -c aes-xts-plain64 -s 512 /dev/mapper/Vol-home
  138  cryptsetup luksAddKey /dev/mapper/Vol-home /etc/luks-keys/home
  139  cryptsetup -d /etc/luks-keys/home open /dev/Vol/home home
  140  mkfs.ext4 /dev/mapper/home
  141  mount /dev/mapper/home /home
  142  cd home
  143  cd /home/
  144  df -k .
  145  ls
  146  vi /etc/crypttab
  147  vi /etc/fstab 
  148  genfstab -U
  149  genfstab -U /
  150  genfstab -U -�p /
  151  genfstab -U -p /
  152  genfstab -U -p / >/etc/fstab
  153  history 

```
