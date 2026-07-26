#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# ponytail: whole-stack stop-and-tar backup (a few seconds downtime) instead of
# per-service mysqldump/pg_dump/redis BGSAVE. Simple and covers all volumes
# uniformly; switch to live dumps if downtime becomes unacceptable.

BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
VOLUMES="mysql_data postgres_data redis_data typesense_data mongo_data pgadmin_data"
# ponytail: npm_data/npm_letsencrypt are only real while nginx-proxy-manager is
# uncommented in docker-compose.yml — add them back here if you enable it.

STAMP=$(date +%Y%m%d-%H%M%S)
DEST="$BACKUP_DIR/$STAMP"
mkdir -p "$DEST"

docker compose stop

for vol in $VOLUMES; do
  # ponytail: -v on a missing volume silently creates an empty one, so an
  # out-of-date VOLUMES list would produce empty tarballs that look fine.
  if ! docker volume inspect "$vol" >/dev/null 2>&1; then
    echo "Skipping ${vol}: no such volume" >&2
    continue
  fi
  docker run --rm -v "${vol}:/data:ro" -v "$DEST:/backup" alpine \
    tar czf "/backup/${vol}.tar.gz" -C /data .
  tar tzf "$DEST/${vol}.tar.gz" >/dev/null   # sanity check: archive isn't corrupt
done

docker compose start

find "$BACKUP_DIR" -maxdepth 1 -mindepth 1 -type d -mtime +"$RETENTION_DAYS" -exec rm -rf {} +

# ponytail: off-site copy only runs if REMOTE_HOST is set (needs passwordless SSH key auth)
if [ -n "${REMOTE_HOST:-}" ]; then
  rsync -az "$DEST" "${REMOTE_HOST}:${REMOTE_DIR:-backups/new_server}/"
  echo "Synced to ${REMOTE_HOST}:${REMOTE_DIR:-backups/new_server}/"
fi

echo "Backup done: $DEST"
