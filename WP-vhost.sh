#!/bin/bash

# Prompt for domain
read -p "Enter domain name (e.g., example.com): " domain

# Strip domain extension for DB and user
dbname=$(echo $domain | sed 's/\..*//')
dbuser=$dbname
dbpass=$(openssl rand -base64 16)

# Directories
webroot="/var/www/$domain/public_html"

# Create user with no shell and home set
username=$dbname
sudo useradd -d /var/www/$domain -s /usr/sbin/nologin -m $username
sudo usermod -a -G www-data $username

# Create web root
sudo mkdir -p $webroot
sudo chown -R $username:www-data /var/www/$domain
sudo chmod -R 750 /var/www/$domain

# Download and extract WordPress
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz
sudo rsync -av wordpress/ $webroot
sudo chown -R $username:www-data $webroot

# Create MySQL DB and user
sudo mysql -e "CREATE DATABASE $dbname DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Generate wp-config.php
cd $webroot
sudo -u $username cp wp-config-sample.php wp-config.php
sudo -u $username sed -i "s/database_name_here/$dbname/" wp-config.php
sudo -u $username sed -i "s/username_here/$dbuser/" wp-config.php
sudo -u $username sed -i "s/password_here/$dbpass/" wp-config.php
echo "define('FS_METHOD', 'direct');" | sudo -u $username tee -a wp-config.php

# Create Apache virtual host
vhost_file="/etc/apache2/sites-available/$domain.conf"
sudo bash -c "cat > $vhost_file" <<EOL
<VirtualHost *:80>
    ServerName www.$domain
    ServerAlias $domain
    DocumentRoot $webroot

    <Directory /var/www/>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
    <Directory /usr/lib/cgi-bin>
        AllowOverride None
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined

    Alias /doc/ /usr/share/doc/
    <Directory /usr/share/doc/>
        Options Indexes MultiViews FollowSymLinks
        AllowOverride None
        Require local
    </Directory>
</VirtualHost>
EOL

# Enable site and reload Apache
sudo a2ensite $domain.conf
sudo systemctl reload apache2

# Output credentials
echo "----------------------------------------"
echo "Site setup completed for: $domain"
echo "MySQL Database: $dbname"
echo "MySQL User: $dbuser"
echo "MySQL Password: $dbpass"
echo "Web Root: $webroot"
echo "Linux User: $username (no shell, home: /var/www/$domain)"
echo "Apache Config: /etc/apache2/sites-available/$domain.conf"
echo "----------------------------------------"
