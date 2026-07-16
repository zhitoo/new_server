#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# ponytail: whole-stack stop-and-tar backup (a few seconds downtime) instead of
# per-service mysqldump/pg_dump/redis BGSAVE. Simple and covers all volumes
# uniformly; switch to live dumps if downtime becomes unacceptable.

BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
VOLUMES="mysql_data postgres_data redis_data typesense_data npm_data npm_letsencrypt pgadmin_data"

STAMP=$(date +%Y%m%d-%H%M%S)
DEST="$BACKUP_DIR/$STAMP"
mkdir -p "$DEST"

docker compose stop

for vol in $VOLUMES; do
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
