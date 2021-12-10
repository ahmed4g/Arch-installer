#!/bin/bash
# Gianmarco's Arch Installer Script
# Inspired by BugsWriter's arch-linux-magic
# Licensed under the GNU General Public License v3


# Intro text
echo "
 ██████╗  █████╗ ██╗███████╗
██╔════╝ ██╔══██╗██║██╔════╝
██║  ███╗███████║██║███████╗
██║   ██║██╔══██║██║╚════██║
╚██████╔╝██║  ██║██║███████║
 ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝
                            
Gianmarco's Arch Installer Script
(C) 2021 Gianmarco Gargiulo - GPL v3

------------------------------------
"


# Main installation
echo "Starting the main installation..."
reflector --latest 20 --sort rate --country Italy --save /etc/pacman.d/mirrorlist --protocol http --download-timeout 5
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
loadkeys it
timedatectl set-ntp true

lsblk
echo "You'll be asked for where to install your OS.
Make an EFI partition (min 300M) if you're on UEFI, optionally a swap partition (min 512M) and a root partition (rest of the space). If you're on traditional BIOS (MBR) make a 1MB 'BIOS Boot' partition and a 256MB EFI partition. For more info go RTFM at wiki.archlinux.org.
Type drives/partitions as full paths (e.g. '/dev/sda' or '/dev/sda1').
Target drive: "
read drive
cfdisk $drive

lsblk
echo "Target root partition (MUST BE FORMATTED so make sure you have nothing important on it): "
read partition
mkfs.ext4 $partition

read -p "Did you make an EFI partition for UEFI? [y/n] " answer
if [[ $answer = y ]] ; then
  echo "Target EFI partition: "
  read efipartition
  mkfs.vfat -F 32 $efipartition
fi

read -p "Did you make a swap partition? [y/n] " answer
if [[ $answer = y ]] ; then
  echo "Target swap partition: "
  read swappartition
  swapon $swappartition
fi

mount $partition /mnt 
pacstrap /mnt base base-devel linux-zen linux-zen-headers
genfstab -U /mnt >> /mnt/etc/fstab

sed '1,/^# Configuration$/d' gais.sh > /mnt/gais_part2.sh
chmod +x /mnt/gais_part2.sh
arch-chroot /mnt ./gais_part2.sh
exit


# Configuration
echo "Starting the configuration..."
pacman -Sy
pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf

ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
hwclock --systohc

echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=it_IT.UTF-8" > /etc/locale.conf
echo "KEYMAP=it" > /etc/vconsole.conf

echo "Hostname: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts

mkinitcpio -P
echo "You will now be asked to input a password for the root user."
passwd
pacman --noconfirm -S grub efibootmgr os-prober
read -p "Did you make an EFI partition for UEFI? [y/n] " answer
if [[ $answer = y ]] ; then
lsblk
echo "Enter EFI partition: " 
read efipartition
mkdir /boot/efi
mount $efipartition /boot/efi
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
else
lsblk
echo "Enter boot drive for MBR: "
read bootdrive
grub-install --target=i386-pc $bootdrive
fi
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm xorg-server sddm plasma akregator ark audiocd-kio dolphin dolphin-plugins elisa ffmpegthumbs filelight gwenview k3b kaddressbook kate kcalc kcharselect kcolorchooser kdeconnect kdegraphics-thumbnailers kdenetwork-filesharing kdenlive kdialog kio-extras kleopatra kmail konsole konversation krdc krfb krita ktorrent markdownpart okular partitionmanager spectacle svgpart yakuake
pacman -R pulseaudio
pacman -S mpv pipewire-pulse zsh rsync pavucontrol-qt opendoas

systemctl enable NetworkManager.service
echo "permit persist keepenv :wheel as root" > /etc/doas.conf
echo "Create your own user account. It will have administrative privileges (wheel)."
echo "Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
passwd $username
runuser -l $username -c 'cd && mkdir Git && cd Git && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si && yay -S --noconfirm librewolf-bin librewolf-extension-dark-reader librewolf-extension-localcdn librewolf-extension-plasma-integration librewolf-extension-return-youtube-dislike-git librewolf-ublock-origin opendoas-sudo'

echo "
----------------------------------------------------------------------------------

Installation completed! You may now reboot into your freshly installed Arch Linux.
(C) 2021 Gianmarco Gargiulo - GPL v3 - www.gianmarco.ga
"