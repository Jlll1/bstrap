ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc

pacman -S grub os-prober efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

echo 'Root password: '
passwd
useradd -m rb
echo 'User password: '
passwd rb

cat << EOT >> /etc/hosts
127.0.0.1	localhost
::1		localhost
EOT

pacman -S dhcpcd wpa_supplicant connman-runit connman-gtk
ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default

#### Base pkgs
pacman -S firefox keepassxc transmission-gtk neovim


#### Set up git/github key
echo 'Setting up git/github key'
pacman -Sy --needed openssh git

cat << EOT > /home/rb/.gitconfig
[user]
	email = "arghantentua@tutanota.com"
	name = "Jlll1"
EOT

PASSPHRASE=${GH_SSH_PASSPHRASE:''}
ssh-keygen -t ed25519 -C "arghantentua@tutanota.com" -N $PASSPHRASE -f /home/rb/.ssh/gh

##### Set up xorg
echo 'Setting up xorg'
pacman -Sy --needed xorg-server xf86-video-amdgpu xorg-xinit

#### Set up suckless suite
echo 'Setting up suckless suite'
pacman -Sy --needed git ttf-font-awesome xorg-xsetroot
pacman -S --needed imlib2 #needed for icons in dwm

git clone https://github.com/Jlll1/dwm
cd dwm && make install && cd .. && rm -rf dwm

git clone https://git.suckless.org/dmenu
cd dmenu && make install && cd .. && rm -rf dmenu

echo 'exec dwm' > /home/rb/.xinitrc

#### Set up polkit
echo 'Setting up polkit'
pacman -Sy --needed git base-devel
git clone https://aur.archlinux.org/xfce-polkit.git
cd xfce-polkit && makepkg -si && cd .. && rm -rf xfce-polkit
sed -i '1 i\exec --no-startup-id /usr/lib/xfce-polkit/xfce-polkit &' /home/rb/.xinitrc

#### Install udisks
pacman -Sy --needed udisks2

#### Setup arch repos

cat << EOT >> /etc/pacman.conf

[universe]
Server = https://universe.artixlinux.org/$arch
Server = https://mirror1.artixlinux.org/universe/$arch
Server = https://mirror.pascalpuffke.de/artix-universe/$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/$arch
Server = https://ftp.crifo.org/artix-universe/

EOT

pacman -Sy artix-archlinux-support

cat << EOT >> /etc/pacman.conf
[extra]
Include = /etc/pacman.d/mirrorlist-arch

[community]\n' >> /etc/pacman.conf
Include = /etc/pacman.d/mirrorlist-arch

[multilib]\n' >> /etc/pacman.conf
Include = /etc/pacman.d/mirrorlist-arch

EOT

#### Setup backlight controls
echo 'Setting up backlight controls'
pacman -Sy acpid acpid-runit
ln -s /etc/runit/sv/acpid /run/runit/service
sv up acpid
usermod -aG video rb
chgrp video /sys/class/backlight/amdgpu_b10/brightness

cat << EOT > /usr/local/bin/brightness_up
#!/bin/sh

cb=$(cat /sys/class/backlight/amdgpu_bl0/brightness)
nb=$(($cb+25))
echo $nb > /sys/class/backlight/amdgpu_bl0/brightness

EOT
chmod +x /usr/local/bin/brightness_up

cat << EOT > /usr/local/bin/brightness_up
#!/bin/sh

cb=$(cat /sys/class/backlight/amdgpu_bl0/brightness
nb=$((cb - 25))
echo $nb > /sys/class/backlight/amdgpu_bl0/brightness

EOT
chmod +x /usr/local/bin/brightness_down

#### Install alacritty
pacman -S --needed alacritty

#### Set up pavucontrol
pacman -S --needed pulseuadio pavucontrol

#### Set up mpv
pacman -S --needed mpv

# mpv-autosub
pacman -S --needed python python-pip
pip install setuptools subliminal

git clone https://github.com/davidde/mpv-autosub
mkdir -p /home/rb/.config/mpv/scripts
cp mpv-autosub/autosub.lua /home/rb/.config/mpv/scripts/
rm -r mpv-autosub

# autosubsync-mpv
pacman -S --needed ffmpeg
pip install ffsubsync
git clone https://github.com/Ajatt-Tools/autosubsync-mpv /home/rb/.config/mpv/scripts/autosubsync

#### Autostart X at login
cat << EOT >> /home/rb/.bash_profile
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec startx
fi
EOT

#### Setup notifications
pacman -S --needed dunst
sed -i '1 i\exec --no-startup-id dunst &' /home/rb/.xinitrc

# brightness
cat << EOT >> /usr/local/bin/brightness_up
pv=$(echo "scale=2 ; ($nb / 255 * 100)" | bc)
dunstify -a "changebrightness" -h int:value:"$pv" "Brightness"

EOT
cat << EOT >> /usr/local/bin/brightness_down
pv=$(echo "scale=2 ; ($nb / 255 * 100)" | bc)
dunstify -a "changebrightness" -h int:value:"$pv" "Brightness"
EOT

# volume
cat << EOT > /usr/local/bin/volume_up
pactl -- set-sink-mute 0 0
pactl -- set-sink-volume 0 +10%
cv=$(pactl -- get-sink-volume 0 | head -n 1 | awk '{print $5}')
dunstify -a "changevolume" -h int:value:"$cv" "Volume"
EOT
chmod +x /usr/local/bin/volume_up

cat << EOT > /usr/local/bin/volume_down
pactl -- set-sink-mute 0 0
pactl -- set-sink-volume 0 -10%
cv=$(pactl -- get-sink-volume 0 | head -n 1 | awk '{print $5}')
dunstify -a "changevolume" -h int:value:"$cv" "Volume"
EOT
chmod +x /usr/local/bin/volume_down

cat << EOT > /usr/local/bin/volume_mute
pactl -- set-sink-mute 0 toggle
cm=$(pactl -- get-sink-mute 0 | awk '{ print $2}')
if [ "$cm" = "yes" ]; then
  cv="0%"
else
  cv=$(pactl -- get-sink-volume 0 | head -n 1 | awk '{print $5}')
fi

dunstify -a "changevolume" -h int:value:"$cv" "Volume"
EOT

#### Setup dotnet
pacman -S --needed dotnet-sdk dotnet-runtime aspnet-runtime

git clone https://aur.archlinux.org/dotnet-core-6.0-bin.git
cd dotnet-core-6.0-bin && makepkg -si && cd ..
rm -rf dotnet-core-6.0-bin

cat << EOT >> /home/rb/.bashrc
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export PATH="$PATH:/home/rb/.dotnet/tools"
export DOTNET_ROOT=/home/rb/.dotnet
export PATH=$PATH:$DOTNET_ROOT
EOT

#### Setup PS1
cat << EOT >> /home/rb/.bashrc
git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\W\[\033[32m\]\$(git_branch)\[\033[00m\]$ "
EOT

#### Setup mounting shortcuts
cat << EOT > /usr/local/bin/dmenu_mount
#!/bin/sh

mount() {
  DEVS=$(lsblk -rp | tail -n +2 | while read -r -- dev _ _ _ _ type _; do \
    if [ "$type" = part ]; then echo "${dev}\n"; fi; done)

  TO_MOUNT=$(echo -e ${DEVS::-2} | dmenu)
  if [ ! -z "$TO_MOUNT" ]; then
    RESULT=$(udisksctl mount -b $TO_MOUNT)
    dunstify -a "dmenu_mount" $RESULT
  fi
}

unmount() {
  DEVS=$(lsblk -rp | tail -n +2 | while read -r -- dev _ _ _ _ _ mountpoints; do \
    if [ ! -z "$mountpoints" ]; then echo "${dev}\n"; fi; done)

  TO_UNMOUNT=$(echo -e ${DEVS::-2} | dmenu)
  if [ ! -z "$TO_UNMOUNT" ]; then
    RESULT=$(udisksctl unmount -b $TO_UNMOUNT)
    dunstify -a "dmenu_mount" $RESULT
  fi
}

"$@"
EOT
chmod +x /usr/local/bin/dmenu_mount
