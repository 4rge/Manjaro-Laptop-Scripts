## Manjaro Laptop Setup Scripts

To start boot into a live USB of Manjaro linux. Next run **Raid0_Preinstall_Script.sh** in your live instance either by cloning the script or copy/pasting from its url. You will be prompted to select the disks to use and the file system type (i.e. ext4, zfs, btrfs) and the script will configure the RAID device so when you run the basic manjaro installer it should list your RAID partition as the only available device (provided all the disks available were selected, else you will still have access to the others during the install process.)

Next, run **Sysadmin_Tasks.sh** to configure sane optimizations for hardware management.

Finally running **Systemd_Timers.sh** is optional, but it provides a systemd unit for basic sysadmin tasks such as package management and disk backups, ect.

Now reboot and consider running **Unixversal Updater** to finish setup.
