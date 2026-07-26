# نصب PHP روی سرور

> **این سرور:** Ubuntu 26.04 LTS (codename: `resolute`)

## وضعیت

| راه | نتیجه |
|---|---|
| `apt install php8.5-*` از مخزن خود Ubuntu | ✅ کار می‌کنه، ولی فقط **8.5** |
| `add-apt-repository ppa:ondrej/php` | ❌ برای `resolute` بیلد نداره (404) |
| PPA با codename پین‌شده روی `noble` | ✅ کار می‌کنه — با دو کتابخونه‌ی اضافه (پایین) |
| کانتینر `php:X.Y-fpm` | ✅ هر نسخه‌ای، بدون دست‌زدن به هاست |

اگه اپت با 8.5 مشکل دارد (اکستنشن یا پکیج composer که hard-cap روی `<8.5` گذاشته)، **گزینه ۲** رو برو.

---

## گزینه ۱ — PHP 8.5 از مخزن Ubuntu (ساده‌ترین)

Ubuntu 26.04 با PHP 8.5 و ۷۵ پکیج اکستنشن میاد. `pgsql` و `mongodb` هم داخلشن.

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  php8.5-cli php8.5-common php8.5-fpm \
  php8.5-mysql php8.5-pgsql php8.5-sqlite3 php8.5-mongodb php8.5-redis \
  php8.5-curl php8.5-gd php8.5-mbstring php8.5-xml php8.5-zip php8.5-intl
```

---

## گزینه ۲ — PHP 8.4 (یا 7.4 تا 8.3) روی هاست از PPA

`ppa:ondrej/php` برای `resolute` بیلد نداره. آخرین dist پایدارش `noble` (24.04) است — حتی dist به‌اسم `devel` هم alias همون noble است:

```
$ curl -s .../dists/devel/Release | head -4
Origin: LP-PPA-ondrej-php
Suite: noble
Version: 24.04
```

پس باید codename رو دستی روی `noble` پین کنیم. از ۱۴ پکیجی که می‌خوایم، ۱۲ تاش با کتابخونه‌های موجود در resolute کار می‌کنه؛ فقط این دو تا کتابخونه‌ی قدیمی می‌خوان که 26.04 نداره:

| پکیج | نیاز دارد به | resolute دارد |
|---|---|---|
| `php8.4-intl` | `libicu74` | `libicu77` |
| `php8.4-zip` | `libzip4t64` | `libzip5` |

خبر خوب: soname هاشون فرق داره، پس نسخه‌ی noble رو می‌شه **کنار** نسخه‌ی resolute نصب کرد بدون تعارض.

### ۱. دو کتابخونه‌ی لازم

```bash
cd /tmp
curl -fLO http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu74_74.2-1ubuntu3.1_amd64.deb
curl -fLO http://archive.ubuntu.com/ubuntu/pool/universe/libz/libzip/libzip4t64_1.7.3-1.1ubuntu2_amd64.deb
sudo apt install -y ./libicu74_74.2-1ubuntu3.1_amd64.deb ./libzip4t64_1.7.3-1.1ubuntu2_amd64.deb
```

هر دو فقط به `libc6` / `libstdc++6` / `zlib1g` / `libssl3` وابسته‌ن که resolute نسخه‌ی جدیدترشون رو داره. `libssl3` هم مستقیم وجود ندارد ولی `libssl3t64` با `Provides: libssl3` پوشش می‌ده، پس apt راضی می‌شه.

### ۲. اضافه‌کردن PPA با پین روی noble

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php     # کلید GPG رو نصب می‌کنه
sudo sed -i 's/resolute/noble/g' /etc/apt/sources.list.d/ondrej-*.sources
```

### ۳. محدود کردن PPA فقط به پکیج‌های php ‏(مهم)

این PPA فقط php نمی‌ده؛ `libgd3` و `libmpdec4` و `libgd-dev` نسخه‌ی noble هم داره. بدون پین، apt می‌تونه `libgd3` سیستم رو **دانگرید** کنه و هر چیزی که بهش وابسته است بشکنه.

```bash
sudo tee /etc/apt/preferences.d/ondrej-php.pref >/dev/null <<'EOF'
Package: *
Pin: release o=LP-PPA-ondrej-php
Pin-Priority: -1

Package: php*
Pin: release o=LP-PPA-ondrej-php
Pin-Priority: 600
EOF

sudo apt update
```

الان فقط چیزهایی که با `php` شروع می‌شن از PPA میان؛ بقیه از مخزن resolute.

### ۴. نصب

```bash
sudo apt install -y \
  php8.4-cli php8.4-common php8.4-fpm \
  php8.4-mysql php8.4-pgsql php8.4-sqlite3 php8.4-mongodb php8.4-redis \
  php8.4-curl php8.4-gd php8.4-mbstring php8.4-xml php8.4-zip php8.4-intl
```

برای نسخه‌های دیگه فقط `8.4` رو عوض کن — `7.4` / `8.0` / `8.1` / `8.2` / `8.3` همه تو dist noble هستن.

> **هشدار:** PHP 7.4 و 8.0 و 8.1 به End of Life رسیده‌ن و آپدیت امنیتی نمی‌گیرن. فقط برای اپ لگاسی که چاره‌ای نیست.

### ۵. انتخاب نسخه‌ی پیش‌فرض CLI

اگه چند نسخه نصب کردی:

```bash
sudo update-alternatives --install /usr/bin/php php /usr/bin/php7.4 74
sudo update-alternatives --install /usr/bin/php php /usr/bin/php8.0 80
sudo update-alternatives --install /usr/bin/php php /usr/bin/php8.1 81
sudo update-alternatives --install /usr/bin/php php /usr/bin/php8.2 82
sudo update-alternatives --install /usr/bin/php php /usr/bin/php8.3 83
sudo update-alternatives --install /usr/bin/php php /usr/bin/php8.4 84

sudo update-alternatives --config php
```

`update-alternatives` فقط `php` تو ترمینال رو عوض می‌کنه؛ روی pool های FPM (اون PHP ای که nginx واقعاً صدا می‌زنه) هیچ اثری نداره.

### بررسی

```bash
php8.4 -v
php8.4 -m | grep -E 'intl|zip|pgsql|redis|mongodb'
systemctl status php8.4-fpm
```

### نکته‌های نگهداری

- هر نسخه FPM سرویس جدای خودش داره. اونهایی که استفاده نمی‌کنی رو خاموش کن:
  ```bash
  systemctl list-units 'php*-fpm*'
  sudo systemctl disable --now php7.4-fpm
  ```
- وقتی ondrej بالاخره `resolute` رو اضافه کرد، پین رو بردار و دو تا `.deb` دستی رو پاک کن:
  ```bash
  sudo sed -i 's/noble/resolute/g' /etc/apt/sources.list.d/ondrej-*.sources
  sudo apt update && sudo apt full-upgrade
  sudo apt autoremove --purge libicu74 libzip4t64
  ```

---

## گزینه ۳ — نسخه‌های PHP با Docker

اگه چند نسخه‌ی PHP هم‌زمان می‌خوای و ترجیح می‌دی هاست تمیز بمونه، این تمیزترین راهه — این پروژه از قبل docker-compose هست.

### Dockerfile

```dockerfile
ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-fpm

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
      pdo_mysql pdo_pgsql pgsql \
      redis mongodb \
      gd intl zip \
      mbstring xml curl \
      opcache
```

### سرویس در docker-compose.yml

```yaml
  php84:
    build:
      context: .
      args:
        PHP_VERSION: "8.4"
    container_name: php84
    restart: unless-stopped
    logging: *default-logging
    volumes:
      - /home/deploy/apps:/var/www
    networks:
      - shared_network
```

برای هر نسخه‌ی دیگه همین بلاک رو با `PHP_VERSION` متفاوت کپی کن.

### وصل کردن nginx

```nginx
fastcgi_pass php84:9000;
```

مسیر فایل‌ها باید **از دید کانتینر php** درست باشه نه nginx — اگه volume رو `/var/www` مپ کردی، `SCRIPT_FILENAME` هم باید `/var/www/...` باشه.

---

## اتصال به دیتابیس‌های این استک

بستگی داره PHP کجا اجرا می‌شه:

| PHP کجاست | host | مثال |
|---|---|---|
| کانتینر روی `shared_network` | اسم سرویس | `postgres`, `mysql`, `mongo`, `redis` |
| روی خود هاست | `127.0.0.1` | پورت پابلیش‌شده (جدول `README.md`) |

اسم سرویس فقط از داخل شبکه‌ی داکر resolve می‌شه، و کانتینرها پورت‌هاشون رو فقط روی `127.0.0.1` باز کرده‌ن — پس هیچ‌کدوم از بیرون سرور دیده نمی‌شن.

## Composer

```bash
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
composer --version
```

اگه چند نسخه PHP داری و می‌خوای composer رو با یکی خاص اجرا کنی:

```bash
php8.4 /usr/local/bin/composer install
```
