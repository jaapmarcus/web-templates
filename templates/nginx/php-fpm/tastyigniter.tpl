#=========================================================================#
# Default Web Domain Template                                             #
# DO NOT MODIFY THIS FILE! CHANGES WILL BE LOST WHEN REBUILDING DOMAINS   #
# https://docs.hestiacp.com/admin_docs/web.html#how-do-web-templates-work #
#=========================================================================#

server {
    listen      %ip%:%web_port%;
    server_name %domain_idn% %alias_idn%;
    root        %docroot%;
    index       index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;
        
    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;


        location / { try_files $uri $uri/ /index.php?$query_string; }
        location ~ ^/index.php {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
               return  404;
            }
    
            fastcgi_pass    %backend_lsnr%;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
            include     %home%/%user%/conf/web/%domain%/nginx.fastcgi_cache.conf*;     
        }
        
        ## Whitelist
        location ~ ^/favicon\.ico { try_files $uri /index.php; }
        location ~ ^/sitemap\.xml { try_files $uri /index.php; }
    
        ## Block all .dotfiles except well-known
        location ~ /\.(?!well-known).* { deny all; }
    
        ### Let nginx return 404 if static file does not exists
        location ~ ^/assets/media { try_files $uri 404; }
        location ~ ^/storage/temp/public { try_files $uri 404; }
    
        location ~ ^/app/.*/assets { try_files $uri 404; }
        location ~ ^/app/.*/actions/.*/assets { try_files $uri 404; }
        location ~ ^/app/.*/dashboardwidgets/.*/assets { try_files $uri 404; }
        location ~ ^/app/.*/formwidgets/.*/assets { try_files $uri 404; }
        location ~ ^/app/.*/widgets/.*/assets { try_files $uri 404; }
    
        location ~ ^/extensions/.*/.*/assets { try_files $uri 404; }
        location ~ ^/extensions/.*/.*/actions/.*/assets { try_files $uri 404; }
        location ~ ^/extensions/.*/.*/dashboardwidgets/.*/assets { try_files $uri 404; }
        location ~ ^/extensions/.*/.*/formwidgets/.*/assets { try_files $uri 404; }
        location ~ ^/extensions/.*/.*/widgets/.*/assets { try_files $uri 404; }
        
        location ~ ^/themes/.*/assets { try_files $uri 404; }
    
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