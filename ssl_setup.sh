#!/bin/bash

SUBDOMAIN="app.cvaultco.com"
EMAIL="admin@cvaultco.com"
WEBROOT="/var/www/certbot"

# Create necessary directories
mkdir -p certbot/www certbot/conf nginx/conf.d

# Step 1: Create docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3'

services:
  webserver:
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    restart: always
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./certbot/www:/var/www/certbot:ro
      - ./certbot/conf:/etc/letsencrypt:ro

  certbot:
    image: certbot/certbot:latest
    container_name: certbot
    volumes:
      - ./certbot/www:/var/www/certbot:rw
      - ./certbot/conf:/etc/letsencrypt:rw
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait \$!'"
EOF

# Step 2: Create initial Nginx config for HTTP challenge
cat > nginx/conf.d/app.conf <<EOF
server {
    listen 80;

    server_name $SUBDOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

# Step 3: Start Nginx and Certbot containers
docker-compose up -d webserver certbot

# Step 4: Obtain SSL certificate (live)
docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot -d $SUBDOMAIN --email $EMAIL --agree-tos --no-eff-email --non-interactive

# Step 5: Update Nginx config with HTTPS
cat >> nginx/conf.d/app.conf <<EOF

server {
    listen 443 ssl http2;

    server_name $SUBDOMAIN;

    ssl_certificate /etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$SUBDOMAIN/privkey.pem;

    location / {
        proxy_pass http://your_backend_ip_or_container:port/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 600s;
    }
}
EOF

# Step 6: Reload Nginx with HTTPS config
docker-compose exec webserver nginx -s reload

echo "✅ Setup complete. SSL configured for https://$SUBDOMAIN"

