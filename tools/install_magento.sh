#!/bin/bash

#Country / Lang settings
language="en_US"
currency="GBP"
timezone="Europe/London"
searchengine="elasticsearch7"

source /etc/profile.d/hestia.sh

# magent_keys.sh located in /root/ should contain the ssh files
# format (With out #)
# public='public_key_here';
# private='private_key_here';

if [ ! -e "/root/keys.sh" ]; then
echo "/root/keys.sh missing"
    exit;
fi
source /root/keys.sh
# Version / composer are optional
while [ "$1" != "" ]; do
    case $1 in
        -u | --user )           shift
                                user="$1"
                                ;;
        -d | --domain )		shift
                domain="$1"
                ;;
        -f | --fname )		shift
                fname="$1"
                ;;
         -l | --lname )		shift
                lname="$1"
                ;;       
        
        -a | --admin )		shift
                admin="$1"
                ;;
        -p | --password )		shift
                password="$1"
                ;;
        -e | --email )		shift
                email="$1"
                ;;
        -r | --redis )		shift
                redis="$1"
                ;;
        -b | --backend )		shift
                backend="$1"
                ;;
        -v | --version )     shift
                version="$1"
                ;;
        -c | --composer )    shift
                composer="$1"
                ;;		
        -w | --php )    shift
        php="$1"
        ;;						
    esac
    shift
done

###############

###############

# check php version is set if not set 7.4 as default
if [ -z "$php" ]; then 
    php="7.4"
fi
# Check if user exists
if [ ! -e /usr/local/hestia/data/users/$user/user.conf ]; then
    echo "$user does not exits";
    exit;
fi

test=$(redis-cli INFO | grep ^db$redis:)
if [ ! -z "$test" ]; then
    echo "Redis Database $redis already exists"  
    exit;
fi

test=$(redis-cli INFO | grep ^db$backend:)
if [ ! -z  "$test" ]; then
    echo "Redis Database $backend already exists"  
    exit;
fi

# Create composer folders 
v-add-user-composer $user
rm /home/$user/.composer/composer
if [ -z $composer ]; then
    wget --tries=3 --timeout=15 --read-timeout=15 --waitretry=3 --no-dns-cache https://getcomposer.org/composer-2.phar --quiet -O /home/$user/.composer/composer
else
    wget --tries=3 --timeout=15 --read-timeout=15 --waitretry=3 --no-dns-cache https://getcomposer.org/composer-$composer.phar --quiet -O /home/$user/.composer/composer    
fi
chmod +x /home/$user/.composer/composer
chown $user:$user /home/$user/.composer/composer

v-change-user-shell $user 'bash'


web=$(grep -F -H "DOMAIN='$domain'" /usr/local/hestia/data/users/$user/web.conf);

if [  -z "$web" ]; then 
    #echo "Domain doesn't exits"
    domain2=${domain//www./}
    web=$(grep -F -H "DOMAIN='$domain2'" /usr/local/hestia/data/users/$user/web.conf);
    if [ -z "$web" ]; then
    echo "Domain doesn't exits"
    exit;
    fi
fi
 echo -e "{\n\t\"http-basic\":\n\t\t{\n\t\t\"repo.magento.com\": {\n\t\t\t\"username\": \"$public\",\n\t\t\t\"password\": \"$private\"\n\t\t}\n\t}\n}" > /home/$user/.composer/auth.json
 chown $user:$user /home/$user/.composer/auth.json

domain2=${domain//www./}
echo "$domain2"

runuser -l  $user -c "rm -f -r ~/web/$domain2/public_html/index.html"
runuser -l  $user -c "rm -f -r ~/web/$domain2/public_html/robots.txt"

#cd /home/$user/web/$domain2/public_html/
echo "/home/$user/web/$domain2/public_html/."


if [ -z $version ]; then
    runuser -l  $user -c "/usr/bin/php$php /home/$user/.composer/composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /home/$user/web/$domain2/public_html/"
else
    runuser -l  $user -c "/usr/bin/php$php /home/$user/.composer/composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=$version /home/$user/web/$domain2/public_html/"

fi


db_user=$( head /dev/urandom | tr -dc a-z0-9 | head -c 6);
db_password=$( head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16);
fdb_user=$(echo "$user"_"$db_user");

echo "$user"_"$db_user"

v-add-database $user $db_user $db_user $db_password "mysql" "localhost"

runuser -l $user -c "/home/$user/web/$domain2/public_html/bin/magento setup:install --base-url=https://$domain/ \
--base-url-secure=https://$domain/ \
--db-host=localhost --db-name=$fdb_user --db-user=$fdb_user --db-password=$db_password \
--admin-firstname=$fname --admin-lastname=$lname --admin-email=$email \
--admin-user=$admin --admin-password=$password --language=$language \
--currency=$currency --timezone=$timezone --use-rewrites=1 \
--search-engine=elasticsearch7 --use-secure-admin=1 --use-secure=1 \
--cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=$backend \
--page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=$redis"


v-add-cron-job $user "*/5" "*" "*" "*" "*" "/usr/bin/php$php /home/$user/web/$domain2/public_html/bin/magento cron:run"

if [ "$php" = '7.4' ]; then 
    template="Magento-PHP-7_4"
else
    template="Magento-PHP-8_1"
fi

v-change-web-domain-backend-tpl $user $domain $template
