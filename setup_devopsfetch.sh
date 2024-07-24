#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install dependencies
apt-get update
apt-get install -y nginx jq

# Enable and start Nginx service
systemctl enable nginx
systemctl start nginx

# For Docker dependencies
# Check Docker installation
if ! command -v docker &>/dev/null; then
    echo "Docker not installed on this device"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
else
    echo "Docker already installed on this device"
fi

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Copy the main script to /usr/local/bin
cp devopsfetch.sh /usr/local/bin/devopsfetch
chmod +x /usr/local/bin/devopsfetch

# Create a log directory
mkdir -p /var/log/devopsfetch
touch /var/log/devopsfetch/devopsfetch.log

# Set up systemd service
cat << EOF > /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOps Information Retrieval Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch -t now now
Restart=always
User=root

StandardOutput=append:/var/log/devopsfetch/devopsfetch.log
StandardError=append:/var/log/devopsfetch/devopsfetch.log

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable devopsfetch.service
systemctl start devopsfetch.service

# Set up log rotation
cat << EOF > /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root adm
    postrotate
        systemctl reload devopsfetch.service > /dev/null 2>/dev/null || true
    endscript
}
EOF

echo "Installation completed successfully!"