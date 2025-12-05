#!/bin/bash

set +e

CMDLINE_PATH="/boot/cmdline.txt"
if [ -f /boot/firmware/cmdline.txt ]; then
   CMDLINE_PATH="/boot/firmware/cmdline.txt"
fi

TARGET_USER="admin"
TARGET_PASS='Admin01!'
TARGET_HASH=$(TARGET_PASS="$TARGET_PASS" python3 - <<'PY'
import crypt, os
print(crypt.crypt(os.environ["TARGET_PASS"], crypt.mksalt(crypt.METHOD_SHA512)))
PY
)
TARGET_GROUPS="sudo,adm,dialout,cdrom,audio,video,plugdev,games,input,netdev,spi,i2c,gpio"

NVME_DEV="/dev/nvme0n1"
NVME_BOOT_PART="${NVME_DEV}p1"
NVME_ROOT_PART="${NVME_DEV}p2"
NVME_BOOT_LABEL="BOOT"
NVME_ROOT_LABEL="rpios-root"
NVME_BOOT_MNT="/mnt/nvme-boot"
NVME_ROOT_MNT="/mnt/nvme-root"

move_root_to_nvme() {
   if [ ! -b "$NVME_DEV" ]; then
      echo "NVMe device not found ($NVME_DEV); skipping root move"
      return
   fi

   if [ ! -b "$NVME_BOOT_PART" ] || [ ! -b "$NVME_ROOT_PART" ]; then
      parted -s "$NVME_DEV" mklabel gpt \
         mkpart primary fat32 1MiB 256MiB \
         set 1 boot on \
         mkpart primary ext4 256MiB 100% || return
   fi

   mkfs.vfat -F 32 -n "$NVME_BOOT_LABEL" "$NVME_BOOT_PART" || return
   mkfs.ext4 -F -L "$NVME_ROOT_LABEL" "$NVME_ROOT_PART" || return

   mkdir -p "$NVME_BOOT_MNT" "$NVME_ROOT_MNT"
   mount "$NVME_BOOT_PART" "$NVME_BOOT_MNT" || return
   mount "$NVME_ROOT_PART" "$NVME_ROOT_MNT" || { umount "$NVME_BOOT_MNT"; return; }

   rsync -aHAX /boot/ "$NVME_BOOT_MNT"/ || { umount "$NVME_BOOT_MNT" "$NVME_ROOT_MNT"; return; }

   rsync -axHAX --numeric-ids \
     --exclude=/boot/* \
     --exclude=/dev/* \
     --exclude=/proc/* \
     --exclude=/sys/* \
     --exclude=/tmp/* \
     --exclude=/run/* \
     --exclude=/mnt/* \
     --exclude=/media/* \
     --exclude=/lost+found \
     / "$NVME_ROOT_MNT"/ || { umount "$NVME_BOOT_MNT" "$NVME_ROOT_MNT"; return; }

   cp /etc/fstab "$NVME_ROOT_MNT/etc/fstab"
   sed -i 's@^[^#][^[:space:]]*[[:space:]]/[[:space:]].*@LABEL=rpios-root / ext4 defaults,noatime 0 1@' "$NVME_ROOT_MNT/etc/fstab"
   sed -i '/[[:space:]]\\/boot[[:space:]]/d' "$NVME_ROOT_MNT/etc/fstab"
   echo "LABEL=${NVME_BOOT_LABEL} /boot vfat defaults,flush,umask=000 0 2" >> "$NVME_ROOT_MNT/etc/fstab"

   if grep -q 'root=' "$CMDLINE_PATH"; then
      sed -i "s@root=[^ ]*@root=LABEL=$NVME_ROOT_LABEL@" "$CMDLINE_PATH"
   else
      sed -i "1s@$@ root=LABEL=$NVME_ROOT_LABEL@" "$CMDLINE_PATH"
   fi
   grep -q 'rootfstype=' "$CMDLINE_PATH" || sed -i '1s@$@ rootfstype=ext4@' "$CMDLINE_PATH"
   grep -q 'rootwait' "$CMDLINE_PATH" || sed -i '1s@$@ rootwait@' "$CMDLINE_PATH"

   umount "$NVME_BOOT_MNT" "$NVME_ROOT_MNT"
}

CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname IOT-manager
else
   echo IOT-manager >/etc/hostname
   sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\tIOT-manager/g" /etc/hosts
fi
FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom enable_ssh
   systemctl enable ssh
   systemctl start ssh || systemctl restart ssh
else
   systemctl enable ssh
   systemctl start ssh || systemctl restart ssh
fi
touch /boot/ssh 2>/dev/null || true
touch /boot/firmware/ssh 2>/dev/null || true
if [ -f /usr/lib/userconf-pi/userconf ]; then
   if ! id -u "$TARGET_USER" >/dev/null 2>&1; then
      adduser --gecos "" --disabled-password "$TARGET_USER"
   fi
   /usr/lib/userconf-pi/userconf "$TARGET_USER" "$TARGET_HASH"
else
   echo "$FIRSTUSER:$TARGET_HASH" | chpasswd -e
   if [ "$FIRSTUSER" != "$TARGET_USER" ]; then
      usermod -l "$TARGET_USER" "$FIRSTUSER"
      usermod -m -d "/home/$TARGET_USER" "$TARGET_USER"
      groupmod -n "$TARGET_USER" "$FIRSTUSER"
      if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
         sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=$TARGET_USER/"
      fi
      if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
         sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/$FIRSTUSER/$TARGET_USER/"
      fi
      if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
         sed -i "s/^$FIRSTUSER /$TARGET_USER /" /etc/sudoers.d/010_pi-nopasswd
      fi
   fi
fi

# Ensure admin has sudo and common groups
usermod -a -G "$TARGET_GROUPS" "$TARGET_USER" 2>/dev/null || true
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan  -h 'Merodningen' 'c1e936f08966e41bf357efd4bc19485ae070fde0f5328a8253fe37fbede41dea' 'NO'
else
cat >/etc/wpa_supplicant/wpa_supplicant.conf <<'WPAEOF'
country=NO
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	scan_ssid=1
	ssid="Merodningen"
	psk=c1e936f08966e41bf357efd4bc19485ae070fde0f5328a8253fe37fbede41dea
}

WPAEOF
   chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
   rfkill unblock wifi
   for filename in /var/lib/systemd/rfkill/*:wlan ; do
       echo 0 > $filename
   done
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_keymap 'no'
   /usr/lib/raspberrypi-sys-mods/imager_custom set_timezone 'Europe/Oslo'
else
   rm -f /etc/localtime
   echo "Europe/Oslo" >/etc/timezone
   dpkg-reconfigure -f noninteractive tzdata
cat >/etc/default/keyboard <<'KBEOF'
XKBMODEL="pc105"
XKBLAYOUT="no"
XKBVARIANT=""
XKBOPTIONS=""

KBEOF
   dpkg-reconfigure -f noninteractive keyboard-configuration
fi
move_root_to_nvme
rm -f /boot/firstrun.sh
rm -f /boot/firmware/firstrun.sh
sed -i 's| systemd.run.*||g' "$CMDLINE_PATH"
exit 0
