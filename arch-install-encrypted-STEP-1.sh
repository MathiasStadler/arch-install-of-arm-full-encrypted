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
