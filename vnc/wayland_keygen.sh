openssl genrsa -out /home/user/tls.key 2048
openssl req -new -key /home/user/tls.key -out /home/user/tls.csr -subj "/C=IT/ST=Veneto/L=Santa Giustina in Colle/O=Your Organization/OU=Your Unit/CN=yourdomain.com"
openssl x509 -req -days 365 -signkey /home/user/tls.key -in /home/user/tls.csr -out /home/user/tls.crt