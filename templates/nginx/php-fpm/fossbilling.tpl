#=========================================================================#
# Default Web Domain Template                                             #
# DO NOT MODIFY THIS FILE! CHANGES WILL BE LOST WHEN REBUILDING DOMAINS   #
# https://docs.hestiacp.com/admin_docs/web.html#how-do-web-templates-work #
#=========================================================================#

server {
    listen      %ip%:%web_port%;
    server_name %domain_idn% %alias_idn%;
    root        %sdocroot%;
    index       index.php index.html index.htm;

    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;
        
        include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;


    location / {
    #try_files $uri $uri/ /index.php;
    rewrite ^/(.*)$ /index.php?_url=/$1;       
 
       location ~* ^.+\.(jpeg|jpg|png|webp|gif|bmp|ico|svg|css|js)$ {
            expires     max;
            fastcgi_hide_header "Set-Cookie";
        }

        location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_pass    %backend_lsnr%;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
            include     %home%/%user%/conf/web/%domain%/nginx.fastcgi_cache.conf*;         
        }
    }
    
    # Block access to sensitive files and return 404 to make it indistinguishable from a missing file
    location ~* .(bak|conf|inc|ini|lock|log|old|sh|sql|twig|yaml|php)$ {
		return 404;
	}
    
    # Disable PHP execution in data and uploads, block public access to log and cache folders
    location ^~ /data/.*\.php$ {
        deny all;
    }
    location ^~ /data/uploads/.*\.php$ { 
        deny all;   
    }
    location ^~ /data/cache/ {
        return 404;
    }
    location ^~ /data/log/ {
        return 404;
    }
    
     location ~* ^/(css|img|js|flv|swf|download)/(.+)$ {
         expires off;
         proxy_no_cache 1;
         proxy_cache_bypass 1;
     }

    location /error/ {
       alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location ~ /\.(?!well-known\/) { 
       deny all; 
       return 404;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
        include %home%/%user%/web/%domain%/stats/auth.conf*;
    }

    include     /etc/nginx/conf.d/phpmyadmin.inc*;
    include     /etc/nginx/conf.d/phppgadmin.inc*;
    include     %home%/%user%/conf/web/%domain%/nginx.conf_*;
}
