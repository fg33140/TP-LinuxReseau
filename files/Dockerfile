FROM debian

RUN apt update -y

RUN apt install apache2 -y

RUN mkdir /etc/apache2/logs/

COPY super_page.html /var/www/html/index.html

COPY minimal.conf /etc/apache2/apache2.conf

CMD [ "apache2", "-DFOREGROUND" ]
