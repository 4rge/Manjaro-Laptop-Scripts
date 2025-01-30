#!/bin/bash

# Define variables
MAINTENANCE_SCRIPT="/usr/local/bin/system-maintenance.sh"
SERVICE_FILE="/etc/systemd/system/system-maintenance.service"
TIMER_FILE="/etc/systemd/system/system-maintenance.timer"

# Create the maintenance script
sudo bash -c "cat > $MAINTENANCE_SCRIPT << 'EOF'
#!/bin/bash

# Update system
sudo pacman -Syu --noconfirm

# Clean Pacman cache
sudo pacman -Scc --noconfirm

# Clean orphaned packages
sudo pacman -Rns \$(pacman -Qdtq) --noconfirm

# Clean journal logs older than 2 weeks
sudo journalctl --vacuum-time=2weeks

# Clean AUR cache if using yay
rm -rf ~/.cache/yay/*

# Optional backups
tar -czf /home/\$USER/config-backup-\$(date +%Y%m%d).tar.gz ~/.config

# Optional: Filesystem check
sudo fsck -Af -M

# Optional: Disk Usage report (change email to yours if needed)
du -h / | mail -s "Daily Disk Usage Report" your_email@example.com
EOF
"

# Make the maintenance script executable
sudo chmod +x $MAINTENANCE_SCRIPT

# Create the systemd service file
sudo bash -c "cat > $SERVICE_FILE << 'EOF'
[Unit]
Description=System Maintenance

[Service]
Type=oneshot
ExecStart=$MAINTENANCE_SCRIPT
User=root
EOF
"

# Create the systemd timer file
sudo bash -c "cat > $TIMER_FILE << 'EOF'
[Unit]
Description=Run system maintenance daily

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
"

# Reload systemd to apply changes
sudo systemctl daemon-reload

# Enable and start the timer
sudo systemctl enable system-maintenance.timer
sudo systemctl start system-maintenance.timer

# Print status
echo "Maintenance script and timer installed successfully."
echo "You can check the timer status with: systemctl status system-maintenance.timer"
echo "Logs can be accessed with: journalctl -u system-maintenance.service"
