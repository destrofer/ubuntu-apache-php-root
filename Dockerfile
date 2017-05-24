FROM ubuntu:16.04
ENV SERVER_DOMAIN=localhost
ENV SERVER_ADMIN_EMAIL=webmaster@localhost
RUN apt-get update && apt-get install -y ssl-cert apache2 php7.0-cgi libapache2-mod-fastcgi php-fpm
RUN a2enmod actions fastcgi alias rewrite ssl
RUN a2ensite default-ssl
RUN mkdir -p /cert/
RUN cp /etc/ssl/certs/ssl-cert-snakeoil.pem /cert/default-cert.pem
RUN cp /etc/ssl/private/ssl-cert-snakeoil.key /cert/default-cert.key
RUN cp /etc/ssl/certs/ssl-cert-snakeoil.pem /cert/default-ca.pem
RUN cp /etc/ssl/certs/ssl-cert-snakeoil.pem /cert/default-ca-bundle.pem
ADD /run.sh /run.sh
RUN chmod +x /run.sh
ADD /etc/apache2/apache2.conf /etc/apache2/apache2.conf
ADD /etc/apache2/ports.conf /etc/apache2/ports.conf
ADD /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
ADD /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
CMD /run.sh
