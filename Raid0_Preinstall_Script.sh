#!/bin/bash

# Check if the user is running the script as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root (use sudo)."
    exit 1
fi

# List available drives
echo "Listing available drives..."
lsblk -d -n -o NAME,SIZE | awk '{ printf "%s (%s GB)\n", $1, $2/1024/1024 }'

# Prompt for user input for drives
echo "Please select drives for your RAID 0 setup (e.g., sda sdb sdc)."
read -p "Enter drives separated by space: " -a drives

# Validate drives input
if [ ${#drives[@]} -lt 2 ]; then
    echo "You must specify at least two drives."
    exit 1
fi

# Check if the drives exist
for drive in "${drives[@]}"; do
    if [[ ! -b "/dev/$drive" ]]; then
        echo "Drive /dev/$drive does not exist."
        exit 1
    fi
done

echo "You selected: ${drives[@]}"

# Create partitions on the selected drives
for drive in "${drives[@]}"; do
    echo "Creating partition on /dev/$drive..."
    (echo n; echo p; echo 1; echo ""; echo ""; echo w) | fdisk /dev/"$drive"
done

# Create the RAID 0 array
raid_device="/dev/md0"
echo "Creating RAID 0 array at $raid_device..."
mdadm --create --verbose "$raid_device" --level=0 --raid-devices=${#drives[@]} /dev/"${drives[0]}"1 /dev/"${drives[1]}"1 "${drives[@]:2:$((${#drives[@]} - 2))}" 

# Wait for the array to be created
echo "Waiting for RAID array to sync..."
watch cat /proc/mdstat

# Prompt for filesystem type
echo "Select filesystem type (ext4, xfs, btrfs): "
read -p "Filesystem type: " fs_type

# Validate filesystem type
if [[ "$fs_type" != "ext4" && "$fs_type" != "xfs" && "$fs_type" != "btrfs" ]]; then
    echo "Unsupported filesystem type. Please choose ext4, xfs, or btrfs."
    exit 1
fi

# Create filesystem on the RAID device
echo "Creating filesystem on $raid_device with type $fs_type..."
mkfs."$fs_type" "$raid_device"

# Mount the filesystem
mount_point="/mnt/manjaro"
echo "Mounting the filesystem to $mount_point..."
mkdir -p "$mount_point"
mount "$raid_device" "$mount_point"

# Display RAID statistics
echo "RAID device statistics for $raid_device:"
mdadm --detail "$raid_device"

# Update the system clock
echo "Updating system clock..."
timedatectl set-ntp true

# Preparing for Manjaro installation
echo "Manjaro installation can now be started."
echo "Follow the prompts in the Manjaro installer."

# Launch the installer (this may vary based on your environment)
exec /usr/bin/manjaro-installer
