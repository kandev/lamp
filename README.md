# LAMP Server #
Optimized for flexibility and security
## Folder structure ##
Please make sure to have all folders required for volume before you start the containers.
For example:
```
mkdir -p /volumes/lamp1/letsencrypt
mkdir -p /volumes/lamp1/log
mkdir -p /volumes/lamp1/mysql
mkdir -p /volumes/lamp1/sites-enabled
mkdir -p /volumes/lamp1/www
```
## Sample apache configuration file ##
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
