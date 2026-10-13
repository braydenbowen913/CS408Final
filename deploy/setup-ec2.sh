#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo bash deploy/setup-ec2.sh" >&2; exit 1; }
source /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] || {
    echo "ERROR: This script requires Ubuntu 24.04 LTS." >&2; exit 1;
}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
id ubuntu >/dev/null 2>&1 || { echo "ERROR: The ubuntu login user is required." >&2; exit 1; }
for file in nexus.service nginx-nexus.conf; do
    [[ -f "$SCRIPT_DIR/$file" ]] || { echo "ERROR: Missing $SCRIPT_DIR/$file" >&2; exit 1; }
done
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ruby-full ruby-dev ruby-bundler build-essential libssl-dev libyaml-dev zlib1g-dev pkg-config nginx rsync curl ca-certificates
gem install bundler --version 2.5.22 --no-document
install -d -o ubuntu -g ubuntu /opt/nexus
if [[ ! -f /etc/nexus.env ]]; then
    umask 077
    printf 'SECRET_KEY_BASE=%s\n' "$(ruby -rsecurerandom -e 'print SecureRandom.hex(64)')" > /etc/nexus.env
fi
chown root:root /etc/nexus.env
chmod 600 /etc/nexus.env
install -m 644 "$SCRIPT_DIR/nexus.service" /etc/systemd/system/nexus.service
install -m 644 "$SCRIPT_DIR/nginx-nexus.conf" /etc/nginx/sites-available/nexus
ln -sfn /etc/nginx/sites-available/nexus /etc/nginx/sites-enabled/nexus
if [[ -L /etc/nginx/sites-enabled/default ]]; then
    unlink /etc/nginx/sites-enabled/default
fi
nginx -t
systemctl daemon-reload
systemctl enable nexus nginx
systemctl restart nginx
echo "Server prepared. Deploy code from your laptop next; Nexus will start after that deployment and on subsequent boots."
