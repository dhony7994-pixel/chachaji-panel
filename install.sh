#!/bin/bash

# Chachaji Panel Automated Installer
clear
echo -e "\033[1;36m==================================================\033[0m"
echo -e "\033[1;32m       CHACHAJI PANEL AUTOMATED INSTALLER         \033[0m"
echo -e "\033[1;36m==================================================\033[0m"

if [ "$EUID" -ne 0 ]; then
  echo -e "\033[1;31m[-] Error: Please run this script as root (sudo bash install.sh)\033[0m"
  exit 1
fi

echo -e "\n\033[1;33m[1/5] Updating system packages...\033[0m"
apt update && apt upgrade -y > /dev/null 2>&1
echo -e "\033[1;32m[✓] System updated successfully.\033[0m"

echo -e "\n\033[1;33m[2/5] Installing required dependencies (Node.js, Nginx, Docker, Certbot)...\033[0m"
apt install -y curl git nodejs npm nginx certbot python3-certbot-nginx docker.io > /dev/null 2>&1
systemctl enable --now docker > /dev/null 2>&1
echo -e "\033[1;32m[✓] Dependencies installed successfully.\033[0m"

echo -e "\n\033[1;36m--------------------------------------------------\033[0m"
echo -e "\033[1;33m[3/5] Setup Admin Account Credentials\033[0m"
echo -e "\033[1;36m--------------------------------------------------\033[0m"
read -p "Enter Admin Username: " ADMIN_USER
read -s -p "Enter Admin Password: " ADMIN_PASS
echo ""
read -p "Enter your Cloudflare Domain (e.g., panel.yourdomain.com): " DOMAIN_NAME

APP_DIR="/var/www/chachaji-panel"
mkdir -p $APP_DIR

cat << EOF > $APP_DIR/.env
PORT=3000
DB_HOST=localhost
ADMIN_USER=$ADMIN_USER
ADMIN_PASS=$ADMIN_PASS
DOMAIN=$DOMAIN_NAME
EOF

echo -e "\n\033[1;33m[4/5] Configuring Nginx Reverse Proxy & Port Setup...\033[0m"
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
nginx -t > /dev/null 2>&1 && systemctl restart nginx

echo -e "\n\033[1;33m[5/5] Generating SSL Certificate via Certbot...\033[0m"
certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m admin@$DOMAIN_NAME > /dev/null 2>&1

CLEAR_PORT=$(grep PORT $APP_DIR/.env | cut -d '=' -f2)

clear
echo -e "\033[1;32m==================================================\033[0m"
echo -e "\033[1;32m       INSTALLATION COMPLETED SUCCESSFULLY!       \033[0m"
echo -e "\033[1;32m==================================================\033[0m"
echo -e " Panel Local Port: \033[1;33m$CLEAR_PORT\033[0m"
echo -e " Access via Domain (Cloudflare Tunnel/Proxy): \033[1;36mhttps://$DOMAIN_NAME\033[0m"
echo -e "\033[1;32m==================================================\033[0m"
