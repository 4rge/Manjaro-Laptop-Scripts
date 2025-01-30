#!/bin/bash

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
