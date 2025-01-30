## Manjaro Laptop Setup Scripts

To start boot into a live USB of Manjaro linux. Next run **Raid0_Preinstall_Script.sh** in your live instance either by cloning the script or copy/pasting from its url. You will be prompted to select the disks to use and the file system type (i.e. ext4, zfs, btrfs) and the script will configure the RAID device so when you run the basic manjaro installer it should list your RAID partition as the only available device (provided all the disks available were selected, else you will still have access to the others during the install process.)

Once install is completed and you reboot into the fresh install run **Install_Zen_Kernel.sh** (again, either copy/paste or, at this step go ahead and clone the folder so you dont need to copy the rest of the scripts.) This will update your linux keyring and install the Zen kernel.

Once the new kernel is installed run **Configure_Virtual_Memory.sh** to set the disk write and memory writes to sane optimizations.

Next, run **Sysadmin_Tasks.sh** to configure sane optimizations for hardware management.

Finally running **Systemd_Timers.sh** is optional, but it provides a systemd unit for basic sysadmin tasks such as package management and disk backups, ect.

Now reboot and consider running **Unixversal Updater** to finish setup.
