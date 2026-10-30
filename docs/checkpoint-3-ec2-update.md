# Update the existing Checkpoint 2 EC2 deployment

These commands assume the existing Ubuntu deployment uses `/opt/nexus`, the `nexus` systemd service, and `/etc/nexus.env`, as configured by `deploy/setup-ec2.sh`. Keep your existing environment file and database. Checkpoint 3 adds four fitness tables; it does not replace accounts or notes. No new gems, asset build, Nginx settings, or security group rules are required.

The examples use your previously documented address, `34.215.193.101`. Substitute the current address if it has changed, and replace the SSH key path. Run only one deployment method below. The implementation work does not update the live instance automatically.

## 1. Validate the source

Run in Ubuntu/WSL from the updated project directory (with local PostgreSQL running and a database role configured):

```bash
bundle install
export PGUSER="$(id -un)"
export PGHOST=/var/run/postgresql
RAILS_ENV=test bundle exec rails db:create db:prepare
bundle exec rails test
bundle exec rails zeitwerk:check
```

All checks must pass before deploying. If your local PostgreSQL uses different credentials, use those instead of the two exports. Never point the tests at production.

## 2. Back up the current deployment

SSH from PowerShell, Ubuntu, or WSL:

```bash
ssh -i ~/keys/mykey.pem ubuntu@34.215.193.101
```

On EC2, stop application writes, back up the database and current code outside `/opt/nexus`, and restart the existing app. This backup command assumes the local `nexus_production` database created by the setup script. If you changed production to use an external database through `DATABASE_URL`, back up that database using its configured connection instead before continuing.

```bash
set -euo pipefail
backup_dir="$HOME/nexus-backups/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"
sudo systemctl stop nexus
# Restart the old application even if the backup fails.
trap 'sudo systemctl start nexus' EXIT
sudo -u postgres pg_dump -Fc nexus_production > "$backup_dir/database.dump"
test -s "$backup_dir/database.dump"
sudo tar --exclude=./vendor --exclude=./log --exclude=./tmp --exclude=./.git -czf "$backup_dir/source.tar.gz" -C /opt/nexus .
sudo chown ubuntu:ubuntu "$backup_dir/source.tar.gz"
chmod 600 "$backup_dir/"*
sudo systemctl start nexus
trap - EXIT
printf 'Backup saved in %s\n' "$backup_dir"
exit
```

Keep the printed directory path for recovery. Protect backups: they contain private account data. `/etc/nexus.env` stays on the server and is not copied into the source archive.

## 3A. Deploy with the existing helper (Ubuntu/WSL)

From the local project root:

```bash
chmod +x deploy/deploy.sh
./deploy/deploy.sh -h 34.215.193.101 -i ~/keys/mykey.pem
```

The helper reruns tests, synchronizes local source, installs gems, prepares the production database, restarts Nexus, and checks `/api/health`. It deploys the files currently on disk, including uncommitted changes, and removes server source files absent locally while preserving excluded runtime directories. No Git push is needed for this method.

## 3B. Upload from Windows PowerShell

Use this alternative if deploying directly from Windows. First complete the validation step in Ubuntu/WSL or CI. From the local project root, package current source without local gems, secrets, or runtime files:

```powershell
$ec2Key = "$HOME\keys\mykey.pem"
$ec2HostName = "ubuntu@34.215.193.101"
$sourceArchive = Join-Path $env:TEMP "nexus-checkpoint-3.tar.gz"
tar --exclude=.git --exclude=.bundle --exclude=vendor --exclude=tmp --exclude=log --exclude=storage --exclude=.aws --exclude=.codex --exclude=.agents --exclude=.env* --exclude=keys --exclude=secrets --exclude=*.pem --exclude=*.key --exclude=ubuntu@* -czf $sourceArchive .
if ($LASTEXITCODE -ne 0) { throw "Packaging failed" }
scp -i $ec2Key $sourceArchive "${ec2HostName}:~/nexus-checkpoint-3.tar.gz"
if ($LASTEXITCODE -ne 0) { throw "Upload failed" }
ssh -i $ec2Key $ec2HostName
```

Then on EC2:

```bash
set -euo pipefail
test -f /etc/nexus.env
cd /opt/nexus
sudo systemctl stop nexus
tar -xzf "$HOME/nexus-checkpoint-3.tar.gz" -C /opt/nexus
bundle config set --local path vendor/bundle
bundle install
mkdir -p log tmp/pids
sudo bash -c 'set -a; source /etc/nexus.env; set +a; export RAILS_ENV=production; cd /opt/nexus; exec runuser -u ubuntu --preserve-environment -- /usr/bin/bundle exec rails db:prepare'
sudo bash -c 'set -a; source /etc/nexus.env; set +a; export RAILS_ENV=production; cd /opt/nexus; exec runuser -u ubuntu --preserve-environment -- /usr/bin/bundle exec rails db:migrate:status'
sudo systemctl restart nexus
sudo systemctl is-active nexus
curl --fail --retry 10 --retry-connrefused --retry-delay 2 http://127.0.0.1/api/health
```

The fitness migration `20261030000000` should show `up`. Uploading this checkpoint over Checkpoint 2 does not require deleting old files. If any command fails, stop and inspect the error before proceeding; the app may remain stopped until fixed or recovered.

## 4. Verify in a browser

Open `http://34.215.193.101`, sign in with an existing account, and confirm your previous notes still exist. Choose **Fitness**, create an exercise, then record a workout with multiple exercises/sets and a zero-weight bodyweight set. Edit it, add and remove a set, filter history by exercise, and delete a test workout. Log in with a second account and confirm the first account's exercises and workouts are absent.

For troubleshooting on EC2:

```bash
sudo journalctl -u nexus -n 100 --no-pager
sudo systemctl status nexus nginx postgresql --no-pager
```

If the app must be rolled back, stop `nexus` and restore the backed-up source into `/opt/nexus` (preserving the environment file and runtime directories), run `bundle install`, and restart it. Checkpoint 2 code can run with the additional fitness tables still present; do not drop those tables or restore an old database unless you intend to discard newer data. A database restore should be a separate, deliberate recovery action using your saved dump.
