# Docker containers
Sharing some of my cooking recipes
## lamp1 ##
This is container optimized for web hosting. Contains Apache, MariaDB and PHP7.2 built on top of Ubuntu Server. Initial idea was to use Alpine Linux, but Apache package there is quite bad and buggy and I didn't want to compile from source.
### Folder structure ###
Please make sure to have all folders required for volume before you start the containers.
For example:
```
mkdir -p /volumes/lamp1/letsencrypt
mkdir -p /volumes/lamp1/log
mkdir -p /volumes/lamp1/mysql
mkdir -p /volumes/lamp1/sites-enabled
mkdir -p /volumes/lamp1/www
```
### Sample apache configuration file ###
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

## Network ##
Please have in mind there are no preconfigured NAT translations or any port to port translations. This is something you should decide how to configure as all environments are uique.

Example for port forwarding:
```
iptables -t nat -A PREROUTING -d 123.123.123.123 -p tcp --dport 80 -j DNAT --to 172.20.0.2
iptables -t nat -A PREROUTING -d 123.123.123.123 -p tcp --dport 443 -j DNAT --to 172.20.0.2
```
Assuming that your host' public ip is 123.123.123.123, this rule will redirect tcp ports 80 and 443 to (supposedly) container's IP.

Having NAT for accessing Internet might be needed too:

`iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -j MASQUERADE`
Will provide NAT for the entire subnet.

## Building ##
`docker-compose build`

## Starting ##
`docker-compose up`
