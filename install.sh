#!/bin/bash

# Chachaji Panel Automated Installer
# Run as root on a fresh Ubuntu/Debian VPS

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo bash install.sh)"
  exit 1
fi

echo "=========================================="
echo "      Installing Chachaji Panel           "
echo "=========================================="

# Update system & install dependencies
apt update && apt upgrade -y
apt install -y curl git nodejs npm nginx certbot python3-certbot-nginx docker.io

# Enable and start Docker
systemctl enable --now docker

# Clone or set up application directory
APP_DIR="/var/www/chachaji-panel"
mkdir -p $APP_DIR
# (Assuming files are copied or cloned here)

echo "------------------------------------------"
echo "Setup Admin Account Credentials"
echo "------------------------------------------"
read -p "Enter Admin Username: " ADMIN_USER
read -s -p "Enter Admin Password: " ADMIN_PASS
echo ""
read -p "Enter your Cloudflare Domain (e.g., panel.yourdomain.com): " DOMAIN_NAME

# Create .env configuration
cat << EOF > $APP_DIR/.env
PORT=3000
DB_HOST=localhost
ADMIN_USER=$ADMIN_USER
ADMIN_PASS=$ADMIN_PASS
DOMAIN=$DOMAIN_NAME
EOF

# Configure Nginx Reverse Proxy
cat << EOF > /etc/nginx/sites-available/chachaji
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/chachaji /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# SSL Setup via Certbot
certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m admin@$DOMAIN_NAME

echo "=========================================="
echo " Installation Complete! Panel is live at: "
echo " https://$DOMAIN_NAME                        "
echo "=========================================="
