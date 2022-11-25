# TP4 Conteneurs

## I. Docker

### 1. Install

```
[user@docker1 ~]$ sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

[user@docker1 ~]$ sudo dnf install docker-ce docker-ce-cli containerd.io
[....]
Complete!

[user@docker1 ~]$ sudo systemctl start docker

[user@docker1 ~]$ sudo usermod -aG docker user
```

### 3. Lancement de conteneurs

```
[user@docker1 ~]$ docker run --memory=500m --name=coolos --cpus=0.5 -p 4444:90 -v /home/user/newnginx.conf:/etc/nginx/conf.d/default.conf -v /home/user/super_page.html:/usr/share/nginx/html/index.html nginx
```

Vérif depuis l'host :  
```
[user@docker1 ~]$ curl localhost:4444
Coucou vous ! :D
```
Vérif depuis vrai PC :  
```
fg331@LAPTOP-VI1KK0CA MINGW64 ~
$ curl 10.102.1.41:4444
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    16  100    16    0     0   5191      0 --:--:-- --:--:-- --:--:--  8000Coucou vous ! :D
```

## II. Images

### Contruire votre propre image :  

Le fichier [Dockerfile](./files/Dockerfile)  

```
[user@docker1 build]$ cat Dockerfile
FROM debian

RUN apt update -y

RUN apt install apache2 -y

RUN mkdir /etc/apache2/logs/

COPY super_page.html /var/www/html/index.html

COPY minimal.conf /etc/apache2/apache2.conf

CMD [ "apache2", "-DFOREGROUND" ]
```

Commande à effectué :  
```
[user@docker1 build]$ docker run -d -p 4444:80 my_apache
```

Vérif :  
  - Depuis localhost :  
   ```
   [user@docker1 build]$ curl localhost:4444
   Coucou vous ! :D
   ```
  - Depuis le PC :  
  ```
  fg331@LAPTOP-VI1KK0CA MINGW64 ~
$ curl 10.102.1.41:4444
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  100    16  100    16    0     0  11602      0 --:--:-- --:--:-- --:--:-- 16000Coucou vous ! :D
  ```

## III. docker-compose

### 2. Make your own meow

- [Dockerfile](./app/Dockerfile)
```
[user@docker1 app]$ cat Dockerfile
FROM debian

RUN apt update -y && \
    apt install -y golang git

RUN mkdir /app

WORKDIR /app

RUN git clone https://github.com/fg33140/GroupieTracker.git

WORKDIR /app/GroupieTracker

CMD [ "go", "run", "main.go" ]
```

- [docker-compose.yml](./app/docker-compose.yml)
```
[user@docker1 app]$ cat docker-compose.yml
version: "3.3"


services:
  go:
    image: my_go_serv
    ports:
      - "8888:8080"
    restart: always
```

- Comment lancer l'application :  
   ```
   git clone https://github.com/fg33140/TP-LinuxReseau.git
   cd TP-LinuxReseau/app
   docker build . -t my_go_serv
   docker-compose up -d
   ```
  Pour accéder au site, il faut se connecter sur le port 8888 :  
   ```
   [user@docker1 app]$ curl localhost:8888
  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link rel="stylesheet" href="/view/css/style_index.css">
      <link rel="icon" href="/view/img/favicon.png">
      <link rel="preconnect" href="https://fonts.googleapis.com/%22%3E">
      <link rel="preconnect" href="https://fonts.gstatic.com/" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300&display=swap" rel="stylesheet">
      <script type="text/javascript" src="/view/js/script_index.js"></script>
      <script type="text/javascript" src="/view/js/script_searchbar.js"></script>
      <script src='https://kit.fontawesome.com/a076d05399.js' crossorigin='anonymous'></script>
      <title>Groupie Tracker</title>
  </head>
  <body>
   ```