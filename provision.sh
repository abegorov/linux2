#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.
set -u  # Treat unset variables as an error when substituting.
set -x  # Print commands and their arguments as they are executed.

LINUX_VER="6.10-rc6"
VBOX_VER="7.0.18"

echo 'Changing GRUB_TIMEOUT=1 to GRUB_TIMEOUT=10':
sudo sed 's/^\(GRUB_TIMEOUT=\).*/\110/' -i /etc/default/grub
sudo grub2-editenv - set menu_auto_hide=0
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

echo 'Install latest kernel from elrepo':
sudo dnf install -y \
  "https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm"
sudo dnf --enablerepo elrepo-kernel install -y kernel-ml kernel-ml-devel

echo 'Install kernel build dependencies:'
sudo dnf install -y bc dwarves rpm-build

echo 'Download kernel sources:'
mkdir linux
cd linux
wget -O - "https://git.kernel.org/torvalds/t/linux-${LINUX_VER}.tar.gz" \
  | tar xfz - --strip-components=1

echo 'Build kernel RPM packages:'
make olddefconfig
sed 's/^\(CONFIG_DEBUG_INFO_BTF=\).*/\1n/' -i .config
sed 's/^\(CONFIG_SYSTEM_TRUSTED_KEYS=\).*/\1""/' -i .config
make -j $(grep processor /proc/cpuinfo | wc -l)
make binrpm-pkg

echo 'Install kernel RPM packages:'
sudo dnf install -y ./rpmbuild/RPMS/x86_64/*.rpm

echo 'Update VirtualBox Guest Additions'
echo '(installed version incompatible with new kernels):'
wget -O "/tmp/VBoxGuestAdditions.iso" \
  "https://download.virtualbox.org/virtualbox/${VBOX_VER}/VBoxGuestAdditions_${VBOX_VER}.iso"
sudo mount -o loop,ro "/tmp/VBoxGuestAdditions.iso" /mnt
sudo /mnt/VBoxLinuxAdditions.run || true
sudo umount /mnt
rm "/tmp/VBoxGuestAdditions.iso"

echo 'Build VirtualBox kernel modules for all kernels:'
sudo rcvboxadd quicksetup all

echo 'Rebooting:'
sudo reboot
