#!/bin/bash

SUBDOMAIN="testing-ssl.data-aces.com"
EMAIL="rajagokultest@gmail.com"
WEBROOT="/var/www/certbot"

# Create necessary directories if they do not exist
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
EOF

# Step 2: Create Nginx config (HTTP + placeholder HTTPS)
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

# Step 3: Start webserver container
docker-compose up -d webserver

# Step 4: Request real SSL certificate
echo "Requesting SSL certificate for $SUBDOMAIN..."
docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot -d $SUBDOMAIN --email $EMAIL --agree-tos --no-eff-email --non-interactive --force-renewal

# Check if Certbot successfully issued the certificate
if [ $? -ne 0 ]; then
    echo "❌ Failed to request SSL certificate. Please check the Certbot logs."
    exit 1
fi

# Step 5: Add HTTPS server block to Nginx config
cat >> nginx/conf.d/app.conf <<EOF

server {
    listen 443 ssl;
    server_name $SUBDOMAIN;

    ssl_certificate /etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$SUBDOMAIN/privkey.pem;

    location / {
        return 200 "✅ SSL is working. No app is currently running.\n";
        add_header Content-Type text/plain;
    }
}
EOF

 #location / {
        #proxy_pass http://your_backend_ip_or_container:port/;
        #proxy_set_header Host \$host;
        #proxy_set_header X-Real-IP \$remote_addr;
        #proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        #proxy_read_timeout 600s;
    #}


# Step 6: Reload Nginx to apply HTTPS config
docker-compose exec webserver nginx -s reload

# Step 7: Success message
echo "✅ Real SSL certificate request completed for https://$SUBDOMAIN"

