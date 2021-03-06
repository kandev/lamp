# Ready for use LAMP server #
Optimized for flexibility and security. Best practices included.

## Key ingredients ##
* Based on Ubuntu 20.04
* MariaDB 10.3
* PHP 7.4
* Apache 2.4.41
* Memcached 1.5.22

*Initially I've started it with Alpine Linux, but Apache package is quite bad there and was causing issues, so switched to Ubuntu.*

## Main details ##

* All website, database, certificates and log files are stored locally (outside of the container). Done via volume mounts.
* PHP implementation is done via *php-fpm*. Some process optimizations are done in the available pool.
* MariaDB is SSL capable and is binded to 127.0.0.1. Basic performance and usability optimizations.
* Apache is optimized for security and best practices. Some http headers are filtered, some are added. Improved SSL configuration.
* Cron is running daily *Certbot* task to check and renew all SSL certificates used in Apache.
* Docker host machine timezone is inherited.

## Installation ##
You can either download the source and build it yourself or use the latest already built image to create container:
### Build image from source ###
```
git clone https://github.com/kandev/lamp
cd lamp
```
Edit docker-compose.yml file and fill the path tou your volume mounts. We're keeping all important files out of the container.
```
docker-compose build
docker-compose up -d
```

### Pull the latest image and create container ###

```
docker create -h lamp01 --network dmz --ip 172.20.0.3 --name lamp01 -v /volumes/lamp1/www:/var/www:rw -v /volumes/lamp1/mysql:/var/lib/mysql:rw -v /volumes/lamp1/sites-enabled:/etc/apache2/sites-enabled:rw -v /volumes/lamp1/letsencrypt:/etc/letsencrypt:rw -v /etc/localtime:/etc/localtime:ro kandev/lamp:latest`
```

* *lamp01* will be the name of the container and the hostname for the virtual OS.
* *dmz* is the name of the network to connect the container to. You can use *docker network ls* and *docker network inspect ...* for details.
* *ip* is followed by the static IP address for the container. Your subnet might be different!

This config also expect you to have all local volume folders created:
```
mkdir -p /volumes/lamp1/letsencrypt
mkdir -p /volumes/lamp1/mysql
mkdir -p /volumes/lamp1/sites-enabled
mkdir -p /volumes/lamp1/www
```
## Sample Apache website configuration file ##
**/etc/apahce2/sites-enabled/domain.tld.conf** (or use volume path, it's makes no difference)
```
<VirtualHost *:80>
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
</VirtualHost>
<VirtualHost *:443>
    ServerName domain.tld
    ServerAlias www.domain.tld
    DocumentRoot /var/www/domain.tld
    ErrorLog ${APACHE_LOG_DIR}/domain.tld-error.log
    CustomLog ${APACHE_LOG_DIR}/domain.tld-access.log combined
    SSLEngine on
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory /usr/lib/cgi-bin>
        SSLOptions +StdEnvVars
    </Directory>
    Include /etc/letsencrypt/options-ssl-apache.conf
    SSLCertificateFile /etc/mysql/cert.pem
    SSLCertificateKeyFile /etc/mysql/key.pem
    SSLProtocol TLSv1.2
    Protocols h2 http/1.1
    SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256
    Header set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
</VirtualHost>
```
This configuration will give you some green badges in most pentest/security scanners.

For the sake of passing the configcheck, this example uses the certificate generated for MariaDB during the creation of this image. It will be replaced by *Certbot* later.

You should restart the container after each configuration update.

## Connecting to the container ##
From the host server run
```
docker exec -ti lamp01 bash
```
Assuming you named the container *lamp01*.

## Add letsencrypt SSL certificate ##
You should run this after the virtual host in Apache is configured.

```
certbot certonly --agree-tos --apache -n -d domain.tld,www.domain.tld
```
Then restart the container.
Cron task will take care of regular renewing all installed certificates.
