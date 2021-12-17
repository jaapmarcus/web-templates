#=======================================================================#
# Default Web Domain Template                                           #
# DO NOT MODIFY THIS FILE! CHANGES WILL BE LOST WHEN REBUILDING DOMAINS #
#=======================================================================#

server {
    listen      %ip%:%web_port%;
    server_name %domain_idn% %alias_idn%;
    index       index.php index.html index.htm;
        
    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;

    location / {
    return 301 https://%domain_idn%/;
    }

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location @fallback {
        proxy_pass      http://%ip%:%web_port%;
    }
    
    location ~ /\.(?!well-known\/|file) {
       deny all; 
       return 404;
    }
    
    include     /etc/nginx/conf.d/phpmyadmin.inc*;
    include     /etc/nginx/conf.d/phppgadmin.inc*;

    include %home%/%user%/conf/web/%domain%/nginx.conf_*;
}