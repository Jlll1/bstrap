mkfs.fat -F 32 /dev/nvme0n1p1
fatlabel /dev/nvme0n1p1 BOOT
mkfs.ext4 -L ROOT /dev/nvme0n1p2

mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

#TODO setup wireless

basestrap /mnt base base-devel runit elogind-runit
basestrap /mnt linux linux-firmware

fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt


