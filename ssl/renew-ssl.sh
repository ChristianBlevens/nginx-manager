#!/bin/bash
# SSL Certificate Renewal Script for nginx-manager

DOMAIN="${SSL_DOMAIN:-christianblevens.me}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== SSL Certificate Renewal ==="
echo "Domain: $DOMAIN"

# Stop nginx-manager to free up port 80
echo "Stopping nginx-manager container..."
cd "$PROJECT_DIR"
docker-compose stop nginx

# Run certbot renewal
echo "Running certbot renewal..."
certbot renew --quiet

if [ $? -eq 0 ]; then
    echo "Certificate renewal successful"

    # Copy certificates to nginx-manager ssl directory
    echo "Copying certificates..."
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem "$SCRIPT_DIR/"
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem "$SCRIPT_DIR/"
    cp /etc/letsencrypt/live/$DOMAIN/chain.pem "$SCRIPT_DIR/"

    chmod 644 "$SCRIPT_DIR/fullchain.pem"
    chmod 644 "$SCRIPT_DIR/chain.pem"
    chmod 600 "$SCRIPT_DIR/privkey.pem"

    echo "Certificates copied successfully"
else
    echo "Certificate renewal failed"
fi

# Start nginx-manager again
echo "Starting nginx-manager container..."
docker-compose start nginx

echo "=== Renewal complete ==="
