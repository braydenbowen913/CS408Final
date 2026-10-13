#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

for tool in ruby bundle make gcc g++ pkg-config; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "ERROR: Missing $tool. Install the prerequisites listed in README.md." >&2
        exit 1
    }
done
ruby -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.2") && Gem::Version.new(RUBY_VERSION) < Gem::Version.new("4.0") ? 0 : 1)' || {
    echo "ERROR: Ruby 3.2–3.x is required." >&2; exit 1;
}
ruby -rrbconfig -e 'exit(File.file?(File.join(RbConfig::CONFIG["rubyhdrdir"], "ruby.h")) ? 0 : 1)' || {
    echo "ERROR: Ruby development headers are missing (ruby-dev)." >&2; exit 1;
}
pkg-config --exists openssl || { echo "ERROR: OpenSSL development headers are missing (libssl-dev)." >&2; exit 1; }
pkg-config --exists yaml-0.1 || { echo "ERROR: libyaml development headers are missing (libyaml-dev)." >&2; exit 1; }
pkg-config --exists zlib || { echo "ERROR: zlib development headers are missing (zlib1g-dev)." >&2; exit 1; }

echo "Installing project dependencies..."
bundle config set --local path vendor/bundle
bundle install || { echo "ERROR: Dependency installation failed. Check network access and README prerequisites." >&2; exit 1; }
mkdir -p log tmp/pids
echo "Open http://localhost:${PORT:-3000} (Ctrl+C to stop)."
exec bundle exec rails server --binding "${BIND:-0.0.0.0}" --port "${PORT:-3000}"
