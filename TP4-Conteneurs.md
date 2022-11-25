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