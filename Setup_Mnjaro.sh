#!/usr/env sh

sudo pacman-key --refresh
sudo pacman -Sy archlinux-keyring mesa lib32-mesa mesa-vdpau lib32-mesa-vdpau lib32-vulkan-radeon vulkan-radeon glu lib32-glu vulkan-icd-loader lib32-vulkan-icd-loader thermald --noconfirm
yay -Sy preload auto-cpufreq ananicy-cpp waydroid-git --noconfirm

git clone https://github.com/revumber/ananicy-rules
rm ananicy-rules/README.md ananicy-rules/LICENSE
sudo mv ananicy-rules/* /etc/ananicy.d/
rm -rf ananicy-rules

sudo systemctl enable systemd-oomd.service --now
sudo systemctl enable preload --now
sudo systemctl enable thermald.service --now
sudo systemctl enable auto-cpufreq.service --now
sudo systemctl enable ananicy-cpp.service --now

# configure swap
printf '\nFinding optimal swapfile size.\n'; _hibned=$(awk "BEGIN {print $(zramctl | tail -1 | awk -F '[^0-9]*' '{ print $3 }')+$(awk '/MemTotal/ { printf "%.3f \n", $2/1024/1024 }' /proc/meminfo); exit}"); _roundhibned=$(printf "%.0f\n" "$_hibned"); printf "\n%s""$_roundhibned"" GB\n\n"
: 1734983545:0;printf '\nCreating swap file.\n\n'; sudo mkswap -U clear --size "$_roundhibned"G --file /swapfile; printf '\nDone.\n\n'
: 1734983559:0;printf '\nAdding line to /etc/fstab.\n\n'; if [ "$(tail -c1 /etc/fstab; printf x)" != $'\nx' ]; then printf "\n" | sudo tee -a /etc/fstab; fi; printf '/swapfile                                 none           swap    defaults,pri=0 0 0\n' | sudo tee -a /etc/fstab; printf '\nDone.\n\nTime to REBOOT.\n\n'

sudo pacman -R $(pacman -Qtdq)
