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
(C) 2022 Gianmarco Gargiulo - GPL v3

WARNING: this script is experimental.
Use at your own risk!

-------------------------------------
"


# Main installation
echo "Starting the main installation..."
reflector --latest 20 --sort rate --country Italy --save /etc/pacman.d/mirrorlist --protocol http --download-timeout 5
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
loadkeys it
timedatectl set-ntp true

lsblk
echo "You'll be asked for where to install your OS. Use cfdisk to partition the drive.
These are some reccommended partition schemes.
For a UEFI system:
    Part. 1 = EFI, min 300M
    Part. 2 = root (where the actual system will be installed)
    Part. 3 = swap (optional), min 512M
For a traditional BIOS / MBR system:
    Part. 1 = BIOS Boot, 1M
    Part. 2 = EFI, 256MB
    Part. 3 = root (where the actual system will be installed)
    Part. 4 = swap (optional), min 512M
For more information go RTFM at wiki.archlinux.org.
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
read -p "Do you want to do a manual review of the fstab? [y/n] " answer
if [[ $answer = y ]] ; then
  nano /mnt/etc/fstab
fi

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

echo "Type a hostname for your system: "
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

pacman -S --noconfirm xorg sddm bspwm sxhkd dunst ark audiocd-kio dolphin dolphin-plugins ffmpegthumbs gwenview kate kcalc kcharselect kdegraphics-thumbnailers kdenetwork-filesharing kdialog kio-extras konsole markdownpart okular partitionmanager spectacle svgpart yakuake git mpv pipewire-pulse zsh rsync pavucontrol-qt opendoas networkmanager htop ttf-roboto ttf-roboto-mono python-dbus unzip exa rofi zsh-autosuggestions nano kwallet-pam breeze qlipper slop vlc

systemctl enable NetworkManager.service
echo "permit persist keepenv :wheel as root" > /etc/doas.conf
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo "Create your own user account. It will have administrative privileges (wheel)."
echo "Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
passwd $username

sed '1,/^# Extra configuration$/d' /gais_part2.sh > /home/$username/gais_part3.sh
chown $username /home/$username/gais_part3.sh
chmod +x /home/$username/gais_part3.sh
echo "
----------------------------------------------------------------------------------------------------

Now for the last part of the installation you must reboot into your installed system, login to a tty as the $username user and run the gais_part3.sh script.
"
exit 0

# Extra configuration
cd && mkdir Git && cd Git && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si && yay -S betterlockscreen picom-jonaburg-fix librewolf-bin librewolf-extension-dark-reader librewolf-extension-localcdn librewolf-ublock-origin opendoas-sudo polybar pfetch pywal-git pulseaudio-control zsh-theme-powerlevel10k-git qt5ct-kde polkit-dumb-agent-git

cd && git init --bare dotfiles
alias dots="/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME"
dots config --local status.showUntrackedFiles no
dots remote add origin https://git.gianmarco.ga/gianmarco/dotfiles.git
dots pull origin master

wget https://github.com/zavoloklom/material-design-iconic-font/releases/download/2.2.0/material-design-iconic-font.zip && unzip material-design-iconic-font.zip && doas cp fonts/Material-Design-Iconic-Font.ttf /usr/share/fonts/TTF && rm -r fonts css material-design-iconic-font.zip

sudo systemctl enable sddm.service
sudo sed -i "s/^Exec=bspwm$/Exec=bash $HOME/Scripts/bspwm.sh/" /usr/share/xsessions/bspwm.desktop

echo "
----------------------------------------------------------------

Installation completed! Enjoy your freshly installed Arch Linux.
(C) 2021 Gianmarco Gargiulo - GPL v3 - www.gianmarco.ga
"