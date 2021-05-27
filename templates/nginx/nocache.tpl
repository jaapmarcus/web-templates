server {
    listen      %ip%:%proxy_port%;
    server_name %domain_idn% %alias_idn%;
        
    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;

    location / {
        proxy_pass      http://%ip%:%web_port%;
        location ~* ^.+\.(%proxy_extensions%)$ {
            root           %docroot%;
            access_log     /var/log/%web_system%/domains/%domain%.log combined;
            access_log     /var/log/%web_system%/domains/%domain%.bytes bytes;
            add_header Cache-Control no-cache;
            expires 1s;
            try_files      $uri @fallback;
        }
    }

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location @fallback {
        proxy_pass      http://%ip%:%web_port%;
    }

    location ~ /\.(?!well-known\/) { 
       deny all; 
       return 404;
    }

    disable_symlinks if_not_owner from=%docroot%;

    include %home%/%user%/conf/web/%domain%/nginx.conf_*;
}

