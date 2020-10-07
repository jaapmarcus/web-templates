server {
    listen      %ip%:%proxy_port%;
    server_name %domain_idn% %alias_idn%;

    location = /xmlrpc.php {
        deny all;
        access_log off;
    }

    location / {
        proxy_pass      https://%ip%:%web_port%;

        proxy_cache cache;
        proxy_cache_valid 15m;
        proxy_cache_valid 404 15m;
        proxy_no_cache $no_cache;
        proxy_cache_bypass $no_cache;
        proxy_cache_bypass $cookie_session $http_x_update;

	location ~* ^.+\.(mp4|webm|mp3|ogg|ogv)$ {
	     proxy_cache    off;
	     secure_link $arg_md5,$arg_expires;
	     secure_link_md5 "$secure_link_expires$uri %user%";
	     if ($secure_link = "") {
		return 403;
	     }
             if ($secure_link = "0") {
                return 403;
	     }
	     root           %docroot%;
             access_log     /var/log/%web_system%/domains/%domain%.log combined;
             access_log     /var/log/%web_system%/domains/%domain%.bytes bytes;
	}

        location ~* ^.+\.(%proxy_extentions%)$ {
            proxy_cache    off;
            root           %sdocroot%;
            access_log     /var/log/%web_system%/domains/%domain%.log combined;
            access_log     /var/log/%web_system%/domains/%domain%.bytes bytes;
            expires        1h;
            try_files      $uri @fallback;
        }
    }

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location @fallback {
        proxy_pass      https://%ip%:%web_port%;
    }

    location ~ /\.ht    {return 404;}
    location ~ /\.svn/  {return 404;}
    location ~ /\.git/  {return 404;}
    location ~ /\.hg/   {return 404;}
    location ~ /\.bzr/  {return 404;}

    include %home%/%user%/conf/web/%domain%/nginx.conf_*;
}
