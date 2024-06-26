#!/bin/bash

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function to kill the process holding the dpkg lock
kill_dpkg_lock() {
    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        log "Waiting for dpkg lock to be released..."
        PID=$(sudo lsof -t /var/lib/dpkg/lock-frontend)
        if [ -n "$PID" ]; then
            log "Killing process $PID holding dpkg lock..."
            sudo kill -9 $PID
            sleep 5
        fi
    done
}

# Fix duplicate docker entries
log "Checking for duplicate entries in docker.list..."
if grep -q "docker.list:1" /etc/apt/sources.list.d/docker.list; then
    sudo sed -i '1,2d' /etc/apt/sources.list.d/docker.list
fi

# Handle interrupted dpkg
log "Ensuring dpkg is configured correctly..."
kill_dpkg_lock
sudo dpkg --configure -a

# Update package list and uninstall existing sqlmap
log "Updating package list..."
kill_dpkg_lock
sudo apt-get update -y

log "Removing existing sqlmap installation..."
kill_dpkg_lock
sudo apt-get remove --purge -y sqlmap

# Install dependencies
log "Installing dependencies..."
kill_dpkg_lock
sudo apt-get install -y git python3 python3-pip

# Clone the latest version of SQLMap from GitHub
if [ -d "/opt/sqlmap" ]; then
    log "Removing existing /opt/sqlmap directory..."
    sudo rm -rf /opt/sqlmap
fi
log "Cloning the latest sqlmap from GitHub..."
git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git /opt/sqlmap

# Create a symbolic link to the sqlmap.py script
log "Creating symbolic link for sqlmap..."
sudo ln -sf /opt/sqlmap/sqlmap.py /usr/local/bin/sqlmap

# Verify the installation
log "Verifying sqlmap installation..."
sqlmap --version

log "SQLMap installation completed successfully."
