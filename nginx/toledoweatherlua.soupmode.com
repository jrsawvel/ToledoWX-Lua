
##########
# toledoweatherlua.soupmode.com
##########

 server {

	listen   80; ## listen for ipv4; this line is default and implied

	root /home/toledoweatherlua/root;
        index index.html;

	# Make site accessible from http://localhost/
	server_name toledoweatherlua.soupmode.com;

        location ~ ^/(css/|images/) {
          root /home/toledoweatherlua/root;
          access_log off;
          # expires max;
          expires -1;
        }

    location /alexa.json {
        charset_types application/json;
        charset UTF-8;
        root /home/toledoweatherlua/root;
    }
}
