#!/bin/sh
if [ ! -f /var/www/html/wp-config.php ]; then
	wp core download --path=/var/www/html --allow-root
	wp config create --path=/var/www/html --dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" \
		--dbhost="$MYSQL_HOST" --allow-root
	wp core install --path=/var/www/html --url="$WP_URL" \
		--title="$WP_TITLE" --admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" --allow-root
	wp user create "$WP_USER2" "$WP_USER2_EMAIL" --role=author \
		--user_pass="$WP_USER2_PASSWORD" --path=/var/www/html --allow-root
fi
exec php-fpm83 -a
