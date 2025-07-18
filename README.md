# webserver

This repository contains helper scripts for deploying Apache2 virtual hosts with WordPress.

## WP-vhost.sh
`WP-vhost.sh` automates setting up a WordPress site on an Apache server. It:

- Creates a system user for the domain
- Downloads WordPress to `/var/www/<domain>/public_html`
- Generates database credentials and a `wp-config.php`
- Creates an Apache virtual host configuration
- Enables the site and reloads Apache

### Usage
Run the script with sudo privileges:

```bash
sudo ./WP-vhost.sh
```

When prompted, provide the domain name (e.g., `example.com`). The script outputs the database credentials and location of the site after setup.

### Requirements
- Apache2 installed and running
- MySQL or MariaDB server
- `curl`, `openssl`, and `rsync` available
- User running the script must have sudo privileges

