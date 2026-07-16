#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
fi

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example — edit the passwords, then re-run this script."
  exit 1
fi

set -a; source .env; set +a

# ponytail: uid/gid 1000 hardcoded to match how this project's directories get
# deployed (owned by the first regular Linux user); skip entirely if that
# uid is already taken, per request.
DEPLOY_UID=1000
DEPLOY_GID=1000
if getent passwd "$DEPLOY_UID" &>/dev/null; then
  echo "User with UID $DEPLOY_UID already exists ($(getent passwd "$DEPLOY_UID" | cut -d: -f1)), skipping."
else
  getent group "$DEPLOY_GID" &>/dev/null || groupadd -g "$DEPLOY_GID" "$DEPLOY_USER"
  useradd -m -u "$DEPLOY_UID" -g "$DEPLOY_GID" -s /bin/bash "$DEPLOY_USER"
  usermod -aG docker "$DEPLOY_USER"
  echo "Created user $DEPLOY_USER (uid=$DEPLOY_UID, gid=$DEPLOY_GID) with docker access."
fi

docker network inspect shared_network &>/dev/null || docker network create shared_network

docker compose up -d
