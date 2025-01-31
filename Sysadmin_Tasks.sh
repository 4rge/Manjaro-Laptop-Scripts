#!/usr/env sh

set -e  # Exit immediately if a command exits with a non-zero status

# Function to check and install packages
install_package() {
    local package="$1"
    pacman -Qi "$package" &>/dev/null || {
        sudo pacman -Sy "$package" --noconfirm
    }
}

# Function to enable and check services
enable_service() {
    local service="$1"
    sudo systemctl enable "$service" --now && sudo systemctl status "$service"
}

# Function to create swap file if it doesn't exist
create_swap_file() {
    [ -f /swapfile ] || {
        _hibned=$(awk "BEGIN {print $(zramctl | tail -1 | awk -F '[^0-9]*' '{ print $3 }') + $(awk '/MemTotal/ { printf "%.3f \n", $2/1024/1024 }' /proc/meminfo); exit}")
        _roundhibned=$(printf "%.0f\n" "$_hibned")
        sudo mkswap -U clear --size "$_roundhibned"G --file /swapfile
        [ "$(tail -c1 /etc/fstab; printf x)" != $'\nx' ] && printf "\n" | sudo tee -a /etc/fstab
        printf '/swapfile                                 none           swap    defaults,pri=0 0 0\n' | sudo tee -a /etc/fstab
    }
}

# Function to set and persist kernel parameters
set_and_persist_kernel_parameters() {
    {
        echo 5 | sudo tee /proc/sys/vm/swappiness > /dev/null
        echo 20 | sudo tee /proc/sys/vm/dirty_ratio > /dev/null
        echo 10 | sudo tee /proc/sys/vm/dirty_background_ratio > /dev/null
    }

    local sysctl_file="/etc/sysctl.d/99-custom-swap.conf"
    [ ! -f "$sysctl_file" ] && {
        {
            echo "# Custom swappiness and dirty ratios" | sudo tee "$sysctl_file" > /dev/null
            echo "vm.swappiness=5" | sudo tee -a "$sysctl_file" > /dev/null
            echo "vm.dirty_ratio=20" | sudo tee -a "$sysctl_file" > /dev/null
            echo "vm.dirty_background_ratio=10" | sudo tee -a "$sysctl_file" > /dev/null
        }
    }

    sudo sysctl --system
}

# Check for necessary utilities
command -v yay >/dev/null 2>&1 || { echo "yay (Yet Another Yaourt) is not installed. Aborting."; exit 1; }

# Refresh pacman keys
sudo pacman-key --refresh

# Hash table for packages
declare -A packages=(
    ["archlinux-keyring"]=0
    ["mesa"]=0
    ["lib32-mesa"]=0
    ["mesa-vdpau"]=0
    ["lib32-mesa-vdpau"]=0
    ["lib32-vulkan-radeon"]=0
    ["vulkan-radeon"]=0
    ["glu"]=0
    ["lib32-glu"]=0
    ["vulkan-icd-loader"]=0
    ["lib32-vulkan-icd-loader"]=0
    ["thermald"]=0
    ["memcached"]=0
)

# Install necessary packages
for pkg in "${!packages[@]}"; do
    install_package "$pkg"
done

# Hash table for additional packages using yay
declare -A yay_packages=(
    ["preload"]=0
    ["auto-cpufreq"]=0
    ["ananicy-cpp"]=0
)

# Install additional packages using yay
for pkg in "${!yay_packages[@]}"; do
    install_package "$pkg"
done

# Clone ananicy rules
git clone https://github.com/revumber/ananicy-rules
rm ananicy-rules/README.md ananicy-rules/LICENSE
sudo mv ananicy-rules/* /etc/ananicy.d/
rm -rf ananicy-rules

# Hash table for services to enable
declare -A services=(
    ["systemd-oomd.service"]=0
    ["preload"]=0
    ["thermald.service"]=0
    ["auto-cpufreq.service"]=0
    ["ananicy-cpp.service"]=0
    ["memcached.service"]=0
)

# Enable services and check status
for service in "${!services[@]}"; do
    enable_service "$service"
done

# Create swap file
create_swap_file

# Set kernel parameters
set_and_persist_kernel_parameters

# Clean up orphaned packages
sudo pacman -Rns $(pacman -Qtdq) || true  # Ignore error if there are no orphaned packages
