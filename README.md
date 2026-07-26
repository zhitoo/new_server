# new_server

استک داکر برای سرویس‌های مشترک روی سرور: MySQL، Postgres، MongoDB، Redis،
Typesense و پنل‌های وب‌شون. هدف اینه که این سرویس‌ها یک‌بار بالا بیان و
اپ‌های دیگه‌ای که روی همین سرور (به‌صورت کانتینر) اجرا میشن ازشون استفاده کنن.

راهنمای نصب PHP روی خود هاست: [`PHP-INSTALL.md`](PHP-INSTALL.md)

## راه‌اندازی

```bash
./setup.sh
```

اولین اجرا فقط `.env` رو از روی `.env.example` می‌سازه و متوقف میشه — رمزها رو
عوض کن، بعد دوباره اجرا کن. اسکریپت داکر رو نصب می‌کنه (اگه نبود)، یوزری با
UID/GID `1000` و اسم `DEPLOY_USER` (از `.env`) می‌سازه و به گروه `docker`
اضافه‌ش می‌کنه (اگه یوزری با UID 1000 از قبل بود، این مرحله رد میشه)، نتورک
`shared_network` رو می‌سازه (اگه نبود) و `docker compose up -d` می‌زنه.

باید با روت اجرا بشه (`sudo ./setup.sh`) چون ساختن یوزر و نصب داکر نیاز به
دسترسی روت داره.

## سرویس‌ها

| سرویس | پورت (فقط 127.0.0.1) | توضیح |
|---|---|---|
| mysql | 3306 | `MYSQL_DATABASE` ساخته‌شده |
| postgres | 5432 | `POSTGRES_DB` ساخته‌شده |
| mongo | 27017 | با auth (`MONGO_ROOT_USER` / `MONGO_ROOT_PASSWORD`) |
| redis | 6379 | با AUTH (`REDIS_PASSWORD`) |
| typesense | 8108 | با API key (`TYPESENSE_API_KEY`) |
| phpmyadmin | 8585 | وب UI برای mysql |
| pgadmin | 9090 | وب UI برای postgres |
| mongo-express | 8083 | وب UI برای mongo (با Basic Auth) |
| redis-commander | 8082 | وب UI برای redis (با Basic Auth) |
| typesense-dashboard | 8109 | وب UI برای typesense (کلاینت‌ساید، بخش پایین رو بخون) |
| nginx-proxy-manager | — | فعلاً تو `docker-compose.yml` کامنت شده |

پسورد و تنظیمات پرفورمنس (buffer pool، max connections، maxmemory و ...) تو
`.env.example` با توضیح فارسی هست.

## دسترسی به پنل‌های ادمین (phpmyadmin, pgadmin, mongo-express, redis-commander, typesense-dashboard)

همه‌شون فقط رو `127.0.0.1` سرور باز هستن، یعنی از بیرون سرور اصلاً دیده
نمیشن. برای وصل‌شدن از سیستم خودت یه SSH tunnel بزن (همه‌ی پورت‌ها با هم):

```bash
ssh -L 8585:127.0.0.1:8585 -L 9090:127.0.0.1:9090 -L 8082:127.0.0.1:8082 \
    -L 8083:127.0.0.1:8083 -L 8108:127.0.0.1:8108 -L 8109:127.0.0.1:8109 \
    user@your-server
```

بعد تو مرورگر خودت:

- phpMyAdmin: `http://127.0.0.1:8585` — سرور `mysql`، یوزر `root`، رمز
  `MYSQL_ROOT_PASSWORD`
- pgAdmin: `http://127.0.0.1:9090` — لاگین با `PGADMIN_DEFAULT_EMAIL` /
  `PGADMIN_DEFAULT_PASSWORD`، بعد یه سرور جدید اضافه کن با Host `postgres`،
  پورت `5432`، یوزر `postgres`، رمز `POSTGRES_PASSWORD`
- mongo-express: `http://127.0.0.1:8083` — لاگین با `MONGO_EXPRESS_USER` /
  `MONGO_EXPRESS_PASSWORD` (Basic Auth)، از قبل به mongo وصله
- redis-commander: `http://127.0.0.1:8082` — لاگین با `REDIS_COMMANDER_USER` /
  `REDIS_COMMANDER_PASSWORD` (Basic Auth)، از قبل به redis وصله
- typesense-dashboard: `http://127.0.0.1:8109` — این یکی سرور-ساید نیست،
  خودِ جاوااسکریپتِ تو مرورگرت مستقیم به API تایپ‌سنس می‌زنه، برای همین پورت
  `8108` رو هم باید تونل کنی (بالا زدم). موقع اضافه‌کردن Node تو داشبورد:
  Host `127.0.0.1`، Port `8108`، Protocol `http`، API Key = `TYPESENSE_API_KEY`

## اضافه‌کردن اپ‌های دیگه به Nginx Proxy Manager

> سرویس `nginx-proxy-manager` فعلاً تو `docker-compose.yml` کامنت شده. برای
> استفاده، اون بلاک و ولوم‌های `npm_data` / `npm_letsencrypt` رو از کامنت
> دربیار، و اون دو ولوم رو به `VOLUMES` تو `backup.sh` هم اضافه کن. بعد پنل
> ادمینش روی `127.0.0.1:81` بالا میاد (`-L 8181:127.0.0.1:81` تونل کن).

اپ دیگه (با compose جدا) باید عضو `shared_network` بشه، دقیقاً مثل اتصال به
دیتابیس‌ها (بخش بالا):

```yaml
networks:
  shared_network:
    external: true
services:
  myapp:
    networks: [shared_network]
```

بعد تو پنل NPM → **Proxy Hosts** → **Add Proxy Host**:

- Domain Name: `myapp.example.com`
- Forward Hostname/IP: اسم سرویس اپ (مثلاً `myapp`) — نه IP و نه `localhost`
- Forward Port: پورتی که اپ داخلش گوش می‌ده (مثلاً `3000`)
- SSL: تب SSL → Request a new SSL Certificate (Let's Encrypt)

نیازی نیست پورت اپ رو تو compose خودش `ports:` کنی؛ NPM از تو نتورک داخلی
بهش وصل میشه.

## اتصال اپ‌های دیگه به این سرویس‌ها

همه‌ی سرویس‌ها روی نتورک external به اسم `shared_network` هستن. برای اینکه
یه اپ دیگه (با compose جدا) به‌جای پورت 127.0.0.1 مستقیم با هاست‌نیم بهشون
وصل بشه، تو compose اون اپ:

```yaml
networks:
  shared_network:
    external: true

services:
  myapp:
    networks: [shared_network]
    environment:
      DB_HOST: mysql       # یا postgres / mongo / redis / typesense
```

هاست‌نیم همون اسم سرویسه (`mysql`, `postgres`, `mongo`, `redis`, `typesense`)،
نه `127.0.0.1` و نه پورت پابلیش‌شده.

## لاگ

هر سرویس با `max-size: 10m` و `max-file: 5` محدود شده (حداکثر ۵۰ مگابایت لاگ
به ازای هر سرویس) تا لاگ‌های بی‌سقف دیسک رو پر نکنن.

## بکاپ

```bash
./backup.sh
```

استک رو چند ثانیه متوقف می‌کنه، هر ولوم (`mysql_data`, `postgres_data`,
`redis_data`, `typesense_data`, `mongo_data`, `pgadmin_data`) رو به‌صورت
`tar.gz` تو `backups/<تاریخ-ساعت>/` می‌ریزه، دوباره استک رو بالا میاره و
بکاپ‌های قدیمی‌تر از ۷ روز رو پاک می‌کنه. ولومی که وجود نداشته باشه رد میشه
(با پیام روی stderr) تا بکاپ خالی تولید نشه.

تنظیم با متغیر محیطی:

```bash
BACKUP_DIR=/mnt/backups RETENTION_DAYS=14 ./backup.sh
```

### ارسال به سرور دیگه (off-site)

اگه بکاپ فقط رو همین سرور بمونه، با از دست رفتن سرور خود بکاپ هم از بین
می‌ره. با ست‌کردن `REMOTE_HOST` (نیاز به SSH key بدون پسورد بین دو سرور)،
اسکریپت بعد از هر بکاپ با `rsync` یه نسخه می‌فرسته اونجا:

```bash
REMOTE_HOST=user@backup-server REMOTE_DIR=backups/new_server ./backup.sh
```

برای اجرای خودکار (مثلاً هر شب ساعت ۳)، تو crontab:

```
0 3 * * * REMOTE_HOST=user@backup-server /path/to/new_server/backup.sh >> /var/log/new_server-backup.log 2>&1
```

برای بازگردانی یک ولوم:

```bash
docker run --rm -v mysql_data:/data -v "$PWD/backups/<تاریخ>:/backup" alpine \
  sh -c "rm -rf /data/* && tar xzf /backup/mysql_data.tar.gz -C /data"
```

این روش کل استک رو دان‌تایم می‌ده تا دیتا موقع بکاپ کنسیستنت باشه؛ اگه
دان‌تایم مشکل شد باید بره سمت `mysqldump`/`pg_dump`/`redis BGSAVE` جدا جدا.
