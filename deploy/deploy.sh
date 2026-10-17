#!/usr/bin/env bash
set -euo pipefail
usage() { echo "Usage: $0 -h PUBLIC-IP [-i SSH-KEY]" >&2; exit 1; }
HOST=""
KEY=""
while getopts ':h:i:' option; do
    case "$option" in
        h) HOST="$OPTARG" ;;
        i) KEY="$OPTARG" ;;
        *) usage ;;
    esac
done
shift "$((OPTIND - 1))"
[[ $# -eq 0 && -n "$HOST" ]] || usage
[[ "$HOST" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] || { echo "ERROR: Invalid host." >&2; exit 1; }
for tool in ruby bundle ssh rsync curl; do
    command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: Missing $tool; see README.md." >&2; exit 1; }
done
cd "$(dirname "${BASH_SOURCE[0]}")/.."
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=15)
if [[ -n "$KEY" ]]; then
    [[ -f "$KEY" ]] || { echo "ERROR: SSH key not found: $KEY" >&2; exit 1; }
    SSH_OPTS+=(-i "$KEY")
fi
TARGET="ubuntu@$HOST"
echo "Installing local dependencies and running tests..."
bundle config set --local path vendor/bundle
bundle install
RAILS_ENV=test bundle exec rails db:create db:prepare
bundle exec rails test
printf -v SSH_COMMAND '%q ' ssh "${SSH_OPTS[@]}"
echo "Copying source to $TARGET:/opt/nexus..."
rsync -az --delete \
    --exclude='.git/' --exclude='.bundle/' --exclude='vendor/' \
    --exclude='log/' --exclude='tmp/' --exclude='storage/' \
    --exclude='.env*' --exclude='.aws/' --exclude='keys/' \
    --exclude='*.pem' --exclude='*.key' --exclude='secrets/' \
    -e "$SSH_COMMAND" ./ "$TARGET:/opt/nexus/"
ssh "${SSH_OPTS[@]}" "$TARGET" 'bash -se' <<'REMOTE'
set -euo pipefail
cd /opt/nexus
bundle config set --local path vendor/bundle
bundle install
mkdir -p log tmp/pids
# Load the root-readable service environment only for database preparation.
sudo bash -c 'set -a; source /etc/nexus.env; set +a; export RAILS_ENV=production; cd /opt/nexus; exec runuser -u ubuntu --preserve-environment -- /usr/bin/bundle exec rails db:prepare'
sudo systemctl restart nexus
sudo systemctl is-active --quiet nexus
REMOTE
echo "Waiting for the health endpoint..."
for attempt in {1..15}; do
    if curl --fail --silent --show-error --connect-timeout 5 --max-time 10 "http://$HOST/api/health"; then
        printf '\nDeployed. Open http://%s/\n' "$HOST"
        exit 0
    fi
    sleep 2
done
echo "ERROR: Health check failed. Check inbound port 80 and sudo journalctl -u nexus -n 50 on EC2." >&2
exit 1
