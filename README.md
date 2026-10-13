# CS408Final
# Nexus

A single **Hello World** landing page built with Ruby on Rails 7.2 and Puma.
`GET /` serves the page; `GET /api/health` returns HTTP 200 with `{"status":"ok"}`.
No database, Node.js, JavaScript build, migrations, or sample data are needed.

## Run from a fresh clone

Use Linux with Bash, Ruby **3.2–3.x**, Bundler **2.5.22**, a C/C++ compiler, Make,
pkg-config, and OpenSSL, libyaml, and zlib development headers. Internet access
to RubyGems is needed for dependency installation. Ubuntu 24.04 is recommended:

```bash
sudo apt-get update
sudo apt-get install -y ruby-full ruby-dev ruby-bundler build-essential pkg-config libssl-dev libyaml-dev zlib1g-dev ca-certificates
sudo gem install bundler --version 2.5.22 --no-document
git clone <YOUR-REPOSITORY-URL>
cd CS408Final
./start.sh
```

Open **http://localhost:3000**. Stop with Ctrl+C. Run `./start.sh` again whenever
needed: it checks prerequisites, installs dependencies into `vendor/bundle`,
creates runtime directories, and starts Rails. Override the port with
`PORT=3001 ./start.sh`. These Bash scripts should be run in Linux/WSL on Windows.

## Tests

After installing dependencies with `start.sh`, run:

```bash
bundle exec rails test
```

The integration tests check the landing page and JSON health endpoint.

## Prepare EC2 once

Create an **Ubuntu 24.04 LTS** instance with the default `ubuntu` login. Allow
inbound TCP **80** for visitors and **22** from your IP for SSH in its security
group. Puma binds to loopback; port 3000 does not need an inbound rule.

From your computer:

```bash
chmod 600 ~/keys/mykey.pem
scp -i ~/keys/mykey.pem -r deploy ubuntu@<PUBLIC-IP>:~
ssh -i ~/keys/mykey.pem ubuntu@<PUBLIC-IP>
sudo bash deploy/setup-ec2.sh
exit
```

Setup installs Ruby and nginx, creates `/opt/nexus`, configures nginx to proxy
port 80 to `127.0.0.1:3000`, and enables `nexus.service` on boot. It creates
a root-readable secret in `/etc/nexus.env` and preserves it on repeated setup.
The app first starts when you deploy its code; nginx may return 502 beforehand.

## Deploy each update

Your computer needs the local runtime prerequisites above plus OpenSSH, rsync,
and curl (`sudo apt-get install -y openssh-client rsync curl` on Ubuntu).

```bash
./deploy/deploy.sh -h <PUBLIC-IP> -i ~/keys/mykey.pem
```

The script installs local dependencies, runs tests, mirrors source into
`/opt/nexus`, installs server dependencies, restarts Nexus, and retries
`http://<PUBLIC-IP>/api/health`. It preserves server gems and runtime directories.
Files removed locally are removed from the remote source directory by rsync.
The ubuntu account needs sudo access, as provided by the standard EC2 image.
If you change nginx or the service file, copy `deploy/` again and rerun setup
before deploying.

```bash
# On the server: diagnose startup or verify boot behavior
sudo systemctl status nexus nginx
sudo journalctl -u nexus -n 50 --no-pager
sudo systemctl is-enabled nexus
# After an EC2 reboot, check the public page and /api/health again.
```
