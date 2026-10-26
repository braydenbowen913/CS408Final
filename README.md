# Nexus — Checkpoint 2

Ruby on Rails 7.2 personal productivity workspace for CS408. Checkpoint 2 adds private notes with create/edit/delete forms, a plain-text editor, folders, categories, and title/content search to the PostgreSQL and Bootstrap foundation. Fitness, finances, goals, global workspace search, and uploads belong to later checkpoints.

## Start from a fresh clone

Supported automated environment: **Ubuntu 24.04 LTS**, including Ubuntu 24.04 in WSL. Use a normal user with sudo access and internet access to Ubuntu packages and RubyGems:

```bash
git clone <YOUR-REPOSITORY-URL>
cd CS408Final
chmod +x start.sh
./start.sh
```

The script installs Ruby, Bundler 2.5.22, PostgreSQL, and build dependencies; starts PostgreSQL; creates a local database role matching your login using peer authentication; installs gems; prepares the development database; and starts Rails at **http://localhost:3000**. Repeated runs preserve accounts. Stop Rails with Ctrl+C. Use `PORT=3001 ./start.sh` to change the port.

Bootstrap 5.3.3 is loaded from jsDelivr with an integrity check; browser internet access is required for Bootstrap styles. Forms and navigation use ordinary server-rendered HTML and require no JavaScript build.

Register at `/signup` with a username, email, and matching password of 12–72 characters. Registration opens `/dashboard`. Log out in the header, then log back in at `/login`. Only signed-in users can access the dashboard, which displays their own account details. Passwords use bcrypt hashes; sessions reset on login/logout and Rails protects forms against CSRF.

## Notes and search (Checkpoint 2)

After logging in, choose **Notes** in the header or **Open notes** on the dashboard:

- `/notes`: browse your notes, newest updated first, with folder/category filters and 20 notes per page.
- `/notes/new`: create a note with a required title, optional text, and optional folder and category.
- `/notes/:id`: read a note, open its editor, or expand the delete section to permanently remove it.
- `/notes/:id/edit`: edit and explicitly save; there is no autosave or rich-text/HTML editor.
- `/folders` and `/categories`: create and rename your flat organization lists. Deleting either keeps its notes and clears only that assignment.
- `/search`: case-insensitive title/content search, optionally combined with folder and category filters. A blank query lists all your notes; `%` and `_` are treated literally. This searches notes only.

Every notes, folder, category, and search route requires login. Lookups and results are scoped to the signed-in account, and notes cannot be assigned another user's folder or category. User-supplied text is escaped when rendered; note text and search terms are filtered from Rails parameter logs.

For an existing installation, install dependencies and run `bundle exec rails db:prepare` before restarting Rails. The new migration adds folders, categories, and notes without modifying existing accounts. `start.sh` and `deploy/deploy.sh` already prepare the database automatically. To deploy manually on EC2, upload the updated source and run the production database preparation command with `/etc/nexus.env` loaded, then `sudo systemctl restart nexus`.

The Checkpoint 2 tests cover note CRUD, invalid forms and retained drafts, owner-only access, forged assignments, HTML escaping, folder/category management, note preservation on group deletion, search/filter combinations, literal wildcards, and pagination.

Verification on this Windows machine is limited: Windows Application Control blocks Ruby's `strscan.so`, preventing Rails boot, migrations, and the automated suite from executing. Ruby and Rails ERB syntax checks can run separately. Run the complete suite in the supported Ubuntu environment or GitHub Actions before deployment; do not treat the new tests as passed until that run succeeds.

## Manual setup and tests

Ruby **3.2 through 4.0**, PostgreSQL 16, and the dependencies installed by `start.sh` are required. If running Rails directly after using the script, set your local peer connection:

```bash
export PGUSER="$(id -un)"
export PGHOST=/var/run/postgresql
bundle exec rails db:create db:prepare
RAILS_ENV=test bundle exec rails db:create db:prepare
bundle exec rails test
bundle exec rails zeitwerk:check
for script in start.sh deploy/setup-ec2.sh deploy/deploy.sh; do bash -n "$script"; done
```

The suite tests account validation, password hashing, normalized/unique email, registration, invalid credentials, login/logout, private dashboard access, account isolation, CSRF, navigation, and health JSON. GitHub Actions runs these checks against PostgreSQL 16. No sample accounts or default passwords are created.

For an existing PostgreSQL server, use `PGHOST`, `PGPORT`, `PGUSER`, and `PGPASSWORD`, or `DATABASE_URL`. Development and test databases default to `nexus_development` and `nexus_test`; the local development role needs database creation permission for `db:prepare`. Use separate development and test databases. To use Windows directly, install compatible Ruby/PostgreSQL, set those environment variables, run `bundle install`, `bundle exec rails db:create db:prepare`, and `bundle exec rails server`.

## Server configuration script

The EC2 instance already exists. **No instance creation or live deployment is part of this checkpoint's implementation.** The repository includes scripts ready to use when server setup or deployment is requested.

`deploy/setup-ec2.sh` supports Ubuntu 24.04 with the standard `ubuntu` user. It installs Ruby/Bundler, PostgreSQL, Git, Nginx and build dependencies; creates `/opt/nexus` and a local PostgreSQL production database owned by `ubuntu`; configures Nginx/Puma and systemd; and enables services at boot. PostgreSQL uses local peer authentication. Rails secrets are generated in root-readable `/etc/nexus.env` and preserved on repeat runs. The application first starts after code is deployed.

When ready to configure the existing server:

```bash
scp -i ~/keys/mykey.pem -r deploy ubuntu@<PUBLIC-IP>:~
ssh -i ~/keys/mykey.pem ubuntu@<PUBLIC-IP>
sudo bash deploy/setup-ec2.sh
```

The security group needs TCP 80 for web traffic and 22 from your IP for SSH. Puma binds to loopback, so port 3000 needs no public rule.

The existing `deploy/deploy.sh` helper requires Linux/WSL, local Ruby, PostgreSQL test access, OpenSSH, rsync and curl. It runs local tests, mirrors source (including deletion of remotely removed source files), installs server gems, prepares the production database, restarts Nexus, and checks `/api/health`:

```bash
./deploy/deploy.sh -h <PUBLIC-IP> -i ~/keys/mykey.pem
```

It preserves server gems, runtime files, and secrets. Do not run deployment until you intend to update the server. Live deployment, reboot verification, HTTPS, and other Checkpoint 6 work remain outside this implementation.
