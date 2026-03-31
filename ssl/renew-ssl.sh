#!/bin/bash
# SSL Certificate Renewal Script for nginx-manager

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DOMAINS=("christianblevens.me" "voluhaus.com")

echo "=== SSL Certificate Renewal ==="

# Stop nginx-manager to free up port 80
echo "Stopping nginx-manager container..."
cd "$PROJECT_DIR"
docker-compose stop nginx

# Run certbot renewal
echo "Running certbot renewal..."
certbot renew --quiet

if [ $? -eq 0 ]; then
    echo "Certificate renewal successful"

    # Copy certificates for each domain
    for DOMAIN in "${DOMAINS[@]}"; do
        CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
        if [ -d "$CERT_DIR" ]; then
            if [ "$DOMAIN" = "christianblevens.me" ]; then
                PREFIX=""
            else
                # Use domain prefix for additional domains
                SHORT_NAME="${DOMAIN%%.*}"
                PREFIX="${SHORT_NAME}-"
            fi

            echo "Copying certificates for $DOMAIN (prefix: '${PREFIX}')..."
            cp "$CERT_DIR/fullchain.pem" "$SCRIPT_DIR/${PREFIX}fullchain.pem"
            cp "$CERT_DIR/privkey.pem" "$SCRIPT_DIR/${PREFIX}privkey.pem"
            cp "$CERT_DIR/chain.pem" "$SCRIPT_DIR/${PREFIX}chain.pem"

            chmod 644 "$SCRIPT_DIR/${PREFIX}fullchain.pem"
            chmod 644 "$SCRIPT_DIR/${PREFIX}chain.pem"
            chmod 600 "$SCRIPT_DIR/${PREFIX}privkey.pem"

            echo "Certificates copied for $DOMAIN"
        else
            echo "WARNING: No certificates found for $DOMAIN at $CERT_DIR"
        fi
    done
else
    echo "Certificate renewal failed"
fi

# Start nginx-manager again
echo "Starting nginx-manager container..."
docker-compose start nginx

echo "=== Renewal complete ==="
