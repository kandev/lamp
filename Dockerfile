FROM ubuntu:20.04
MAINTAINER Todor Kandev <todor@kandev.com>

RUN \
  apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
    coreutils \
    bash \
    supervisor \
    ca-certificates \
    memcached \
    php \
    php-mysql \
    php-fpm \
    php-gd \
    php-json \
    php-mbstring \
    php-bcmath \
    php-bz2 \
    php-curl \
    php-intl \
    php-apcu \
    php-imagick \
    php-memcached \
    php-sqlite3 \
    mariadb-server \
    mariadb-client \
    apache2 \
    apache2-utils \
    libapache2-mod-security2 \
    libapache2-mod-evasive \
    certbot \
    python3-certbot-apache \
    locales \
    cron \
    curl \
    vim \
    inetutils-syslogd \
    mc

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN /usr/sbin/a2dismod php7.4 mpm_prefork
RUN /usr/sbin/a2enconf php7.4-fpm
RUN /usr/sbin/a2enmod headers http2 rewrite ssl proxy_fcgi evasive mpm_event
RUN mkdir -p /run/php
RUN mkdir -p /var/run/memcached

COPY supervisord.conf /etc/supervisor/

#Apache preconfiguration
RUN sed -i 's/ServerSignature\s*On/ServerSignature Off/' /etc/apache2/conf-available/security.conf
RUN sed -i 's/ServerTokens\s*OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
RUN sed -i 's/^#Header set X-Frame-Options: "sameorigin"$/Header set X-Frame-Options: "sameorigin"\nHeader set X-XSS-Protection "1; mode=block"\nHeader set Referrer-Policy "no-referrer"/' /etc/apache2/conf-available/security.conf
RUN sed -i 's/^#Header set X-Content-Type-Options: "nosniff"$/Header set X-Content-Type-Options: "nosniff"/' /etc/apache2/conf-available/security.conf
RUN sed -i 's/SSLProtocol\s*all\s*-SSLv3$/SSLProtocol TLSv1.2/' /etc/apache2/mods-available/ssl.conf
RUN sed -i 's/#SSLStrictSNIVHostCheck\s*On/SSLStrictSNIVHostCheck On\nSSLUseStapling On\nSSLStaplingCache "shmcb:logs\/ssl_stapling(32768)"\nSSLOpenSSLConfCmd DHParameters \/etc\/apache2\/dhparam/' /etc/apache2/mods-available/ssl.conf
RUN sed -i '/<Directory \/var\/www\/>/,\@</Directory>@s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN sed -i '/<Directory \/var\/www\/>/,\@</Directory>@s/Options Indexes FollowSymLinks/Options -Indexes -FollowSymLinks/' /etc/apache2/apache2.conf
RUN sed -i 's/Include ports.conf/Include ports.conf\nServerName 127.0.0.1\:80/' /etc/apache2/apache2.conf
RUN sed -i 's/LogFormat "%h %l %u %t \\"%r\\" %>s %O \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined/LogFormat "%a %{Host}i %l %u %t \\"%r\\" %>s %O \\"%{Referer}i\\" \\"%{User-Agent}i\\" %D" combined/' /etc/apache2/apache2.conf
#Download the best ever DH params
RUN curl https://ssl-config.mozilla.org/ffdhe4096.txt > /etc/apache2/dhparam

#PHP FPM Optimizations
RUN sed -i 's/session\.save_handler\s*=\s*files/session.save_handler = memcache\nsession.save_path = "127.0.0.1:11211"/' /etc/php/7.4/fpm/php.ini
RUN sed -i 's/pm.max_children\s*=\s*5/pm.max_children = 20/' /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i 's/pm.start_servers\s*=\s*2/pm.start_servers = 5/' /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i 's/pm.min_spare_servers\s*=\s*1/pm.min_spare_servers = 5/' /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i 's/pm.max_spare_servers\s*=\s*3/pm.max_spare_servers = 10/' /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i 's/;pm.max_requests\s*=\s*500/pm.max_requests = 200/' /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i 's/;php_admin_value[error_log]\s*=\s*\/var\/log\/fpm-php.www.log/php_admin_value[error_log] = \/var\/log\/fpm-php.www.log/' /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i 's/;php_admin_flag[log_errors]\s*=\s*on/php_admin_flag[log_errors] = on/' /etc/php/7.4/fpm/pool.d/www.conf
RUN echo '\napc.shm_size=1024M\napc.entries_hint=10000\n' >> /etc/php/7.4/mods-available/apcu.ini

#Mysql Optimizations
RUN openssl req -x509 -newkey rsa:2048 -keyout /etc/mysql/key.pem -out /etc/mysql/cert.pem -nodes -days 42000 -subj "/C=BG/ST=Plovdiv/L=Plovdiv/O=Kamenitza.ORG/OU=IT Department/CN=kamenitza.org"
#Convert private key to PKCS#1
RUN openssl rsa -in /etc/mysql/key.pem -out /etc/mysql/key1.pem
RUN echo "[mysqld]\ninnodb_file_per_table=1\ninnodb_flush_log_at_trx_commit=2\ninnodb_flush_method=O_DIRECT\nskip_name_resolve=OFF\nwait_timeout=60\nbinlog_format=ROW\nquery_cache_type=OFF\nquery_cache_size=0\nssl-ca=/etc/mysql/cert.pem\nssl-cert=/etc/mysql/cert.pem\nssl-key=/etc/mysql/key1.pem\nbind-address=127.0.0.1\nport=3306\n\n[mysql]\nssl" > /etc/mysql/mariadb.conf.d/55-tweaks.cnf

#Renew all certificates
RUN echo '0 3 * * * /usr/bin/certbot renew --apache --agree-tos -n && killall apache2' | crontab

EXPOSE 80 443
VOLUME ["/var/www", "/var/lib/mysql", "/etc/letsencrypt"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
