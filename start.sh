#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] || {
    echo "ERROR: Automated setup requires Ubuntu 24.04 (or Ubuntu 24.04 in WSL)." >&2; exit 1;
}
SUDO=()
if [[ $EUID -ne 0 ]]; then SUDO=(sudo); fi
"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y ruby-full ruby-dev ruby-bundler build-essential pkg-config libssl-dev libyaml-dev zlib1g-dev libpq-dev postgresql postgresql-client ca-certificates git
ruby -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.2") && Gem::Version.new(RUBY_VERSION) < Gem::Version.new("4.1") ? 0 : 1)' || {
    echo "ERROR: Ruby 3.2 through 4.0 is required." >&2; exit 1;
}
"${SUDO[@]}" gem install bundler --version 2.5.22 --no-document
# A supplied DATABASE_URL uses an existing database server instead.
if [[ -z "${DATABASE_URL:-}" ]]; then
    if command -v systemctl >/dev/null && [[ -d /run/systemd/system ]]; then
        "${SUDO[@]}" systemctl start postgresql
    else
        "${SUDO[@]}" service postgresql start
    fi
    # Local peer authentication lets the developer use PostgreSQL without a stored password.
    LOCAL_USER="$(id -un)"
    "${SUDO[@]}" -u postgres psql -v ON_ERROR_STOP=1 -v role="$LOCAL_USER" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN CREATEDB', :'role')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'role') \gexec
SQL
    export PGUSER="${PGUSER:-$LOCAL_USER}"
    export PGHOST="${PGHOST:-/var/run/postgresql}"
fi
bundle _2.5.22_ config set --local path vendor/bundle
bundle _2.5.22_ install
mkdir -p log tmp/pids
bundle _2.5.22_ exec rails db:create db:prepare
echo "Open http://localhost:${PORT:-3000} (Ctrl+C to stop)."
exec bundle _2.5.22_ exec rails server --binding "${BIND:-0.0.0.0}" --port "${PORT:-3000}"
