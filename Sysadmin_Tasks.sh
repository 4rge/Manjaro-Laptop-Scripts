#!/usr/env sh

sudo pacman-key --refresh
sudo pacman -Sy archlinux-keyring mesa lib32-mesa mesa-vdpau lib32-mesa-vdpau lib32-vulkan-radeon vulkan-radeon glu lib32-glu vulkan-icd-loader lib32-vulkan-icd-loader thermald --noconfirm
yay -Sy preload auto-cpufreq ananicy-cpp --noconfirm

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

# Function to set and persist kernel parameters
set_and_persist_kernel_parameters() {
    # Set swappiness
    echo "Setting vm.swappiness to 5"
    echo 5 | sudo tee /proc/sys/vm/swappiness > /dev/null
    
    # Set dirty ratios
    echo "Setting vm.dirty_ratio to 20"
    echo 20 | sudo tee /proc/sys/vm/dirty_ratio > /dev/null
    echo "Setting vm.dirty_background_ratio to 10"
    echo 10 | sudo tee /proc/sys/vm/dirty_background_ratio > /dev/null

    # Make changes persistent
    echo "Making the changes persistent across reboots"

    # Check if the parameters already exist in sysctl.conf
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=5" | sudo tee -a /etc/sysctl.conf > /dev/null
    fi
    if ! grep -q "vm.dirty_ratio" /etc/sysctl.conf; then
        echo "vm.dirty_ratio=20" | sudo tee -a /etc/sysctl.conf > /dev/null
    fi
    if ! grep -q "vm.dirty_background_ratio" /etc/sysctl.conf; then
        echo "vm.dirty_background_ratio=10" | sudo tee -a /etc/sysctl.conf > /dev/null
    fi

    # Alternatively, apply settings to a separate file in sysctl.d
    local sysctl_file="/etc/sysctl.d/99-custom-swap.conf"
    if [ ! -f "$sysctl_file" ]; then
        echo "Creating $sysctl_file for persistent settings"
        echo "# Custom swappiness and dirty ratios" | sudo tee "$sysctl_file" > /dev/null
        echo "vm.swappiness=5" | sudo tee -a "$sysctl_file" > /dev/null
        echo "vm.dirty_ratio=20" | sudo tee -a "$sysctl_file" > /dev/null
        echo "vm.dirty_background_ratio=10" | sudo tee -a "$sysctl_file" > /dev/null
    fi

    # Apply changes immediately
    echo "Applying changes immediately"
    sudo sysctl --system

    echo "Swappiness set to 5, dirty_ratio set to 20, and dirty_background_ratio set to 10."
}

# Execute the function
set_and_persist_kernel_parameters

sudo pacman -Rns $(pacman -Qtdq)
