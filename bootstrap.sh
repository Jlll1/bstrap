BOOT_PARTITION="/dev/nvme0n1p1"
ROOT_PARTITION="/dev/nvme0n1p2"

mkfs.fat -F 32 $BOOT_PARTITION
fatlabel $BOOT_PARTITION BOOT
mkfs.ext4 -L ROOT $ROOT_PARTITION

mount $ROOT_PARTITION /mnt
mkdir /mnt/boot
mount $BOOT_PARTITION /mnt/boot

#TODO setup wireless

basestrap /mnt base base-devel runit elogind-runit
basestrap /mnt linux linux-firmware

fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt


