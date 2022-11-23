# TP3 : Amélioration de la solution NextCloud

## Sommaire

- [TP3 : Amélioration de la solution NextCloud](#tp3--amélioration-de-la-solution-nextcloud)
  - [Stack Web](#stack-web)
    - [Module 1 Reverse Proxy](#module-1-reverse-proxy)
  - [Base de Données](#base-de-données)
    - [Module 2 Réplication de base de données](#module-2-réplication-de-base-de-données) Avec 1 bonus
    - [Module 3 Sauvegarde de base de données](#module-3-sauvegarde-de-base-de-données) Avec 2 bonus
  - [Système](#système)
    - [Module 7 Fail2ban](#module-7-fail2ban)

## Module 1 Reverse Proxy

### II. Setup

- Installation Nginx :  
  ```
  [proxy@proxy ~]$ sudo dnf install nginx

  [proxy@proxy ~]$ sudo systemctl start nginx

  [proxy@proxy ~]$ sudo systemctl enable nginx

  [proxy@proxy ~]$ sudo ss -lntp
  [sudo] password for proxy:
  State  Recv-Q Send-Q  Local Address:Port   Peer Address:Port Process
  LISTEN 0      511           0.0.0.0:80          0.0.0.0:*     users:(("nginx",pid=898,fd=6),("nginx",pid=897,fd=6))
  LISTEN 0      128           0.0.0.0:22          0.0.0.0:*     users:(("sshd",pid=716,fd=3))
  LISTEN 0      511              [::]:80             [::]:*     users:(("nginx",pid=898,fd=7),("nginx",pid=897,fd=7))
  LISTEN 0      128              [::]:22             [::]:*     users:(("sshd",pid=716,fd=4))

  [proxy@proxy ~]$ sudo firewall-cmd --zone=public --add-port=80/tcp
  success

  [proxy@proxy ~]$ sudo ps -ef | grep nginx
  root         897       1  0 08:49 ?        00:00:00 nginx: master process /usr/sbin/nginx
  nginx        898     897  0 08:49 ?        00:00:00 nginx: worker process
  ```

  Vérification :  
   ```
   fg331@LAPTOP-VI1KK0CA MINGW64 ~
    $ curl 10.102.1.13:80
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
      0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0<!doctype html>
    <html>
      <head>
        <meta charset='utf-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <title>HTTP Server Test Page powered by: Rocky Linux</title>
        <style type="text/css">
          /*<![CDATA[*/

          html {
    ....
    ....
   ```
- Configurer NGINX

```
[proxy@proxy ~]$ sudo cat /etc/nginx/nginx.conf
....
....
    # Load modular configuration files from the /etc/nginx/conf.d directory.
    include /etc/nginx/conf.d/*.conf;
....
....
```
Création fichier conf :  
```
[proxy@proxy ~]$ sudo cat /etc/nginx/conf.d/reverse_proxy.conf
server {
        server_name web.tp2.linux;

        listen 80;

        location / {
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-Proto https;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

                proxy_pass http://web.tp2.linux:80;
        }

        location /.well-known/carddav {
                return 301 $scheme://$host/remote.php/dav;
        }

        location /.well-know/carddav {
                return 301 $scheme://$host/remote.php/dav;
        }

}
```
Modification de conf.php sur le server web en ajoutant la ligne "'trusted_proxies'='10.102.1.13'" :  
```
[user@web ~]$ sudo cat /var/www/tp2_nextcloud/config/config.php
<?php
$CONFIG = array (
  'instanceid' => 'oc1hm0x0usbz',
  'passwordsalt' => 'GOudWCWIPCNoBfxhH77u5B3MHNyC6x',
  'secret' => 'dxMqIGeNpEAF8F/',I1YkxzsrPCt3WCCvITeLU2Xtwlh4rhZhZ',
  'trusted_domains' =>
  array (
    0 => 'web.tp2.linux',
  ),
  'datadirectory' => '/var/www/tp2_nextcloud/data',
  'dbtype' => 'mysql',
  'version' => '25.0.0.15',
  'overwrite.cli.url' => 'http://web.tp2.linux',
  'dbname' => 'nextcloud',
  'dbhost' => '10.102.1.12:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => 'pewpewpew',
  'installed' => true,
  'trusted_proxies' => '10.102.1.13',
);
```
Vérification (curl depuis PC physique):  
```
fg331@LAPTOP-VI1KK0CA MINGW64 ~
$ curl web.tp2.linux
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   156  100   156    0     0  22162      0 --:--:-- --:--:-- --:--:-- 26000<!DOCTYPE html>
<html>
<head>
        <script> window.location.href="index.php"; </script>
        <meta http-equiv="refresh" content="0; URL=index.php">
</head>
</html>
```
Configuration Hosts : 
```
fg331@LAPTOP-VI1KK0CA MINGW64 ~
$ cat /c/Windows/System32/Drivers/etc/hosts
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#       127.0.0.1       localhost
#       ::1             localhost

10.102.1.13 web.tp2.linux

127.0.0.1 kubernetes.docker.internal
```

### III. HTTPS  

- Création de la clef privé et du certificat :  
```
[proxy@proxy ~]$ sudo openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/nginx/private/privateKey.key -out /etc/pki/nginx/certificate.crt
....+.....+.+...+..+.+............+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+..................+..+....+...+...........+............+...+......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+...............+.....+............+.+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.................+.+..+.......+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+.+......+.....+....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*............+......+............+..+.......+...+...........+..........+............+..+......+................+...+.....+.......+...+....................+.......+.....................+...+..+....+.....+.+...+...........+..........+.....+......+..........+...............+.....+.......+......+..+.......+.....+......+.+.....................+..+.+......+...............+..................+.....+...............+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
```
Changement dans le fichier conf de nginx :  
```
 server {
            # On indique le nom que client va saisir pour accéder au service
            # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
            server_name web.tp2.linux;

            # Port d'écoute de NGINX
            listen 443 ssl;

            ssl_certificate /etc/pki/nginx/certificate.crt;
            ssl_certificate_key /etc/pki/nginx/private/privateKey.key;
```
Ouverture port 443 :  
```
[proxy@proxy ~]$ sudo firewall-cmd --add-port=443/tcp --permanent
[sudo] password for proxy:
success
```

Dans la machine web on modifie la ligne suivant dans le fichier config.php :
```
'overwrite.cli.url' => 'https://web.tp2.linux',
```





## Module 2 Réplication de base de données

IP du 2ème serveur DB : 10.102.1.22

### Configuration du master :  
 - Paramètre :  
   - Le dossier des logs binaire sera :  
     ```
     [userDB@db ~]$ sudo ls -al /var/log/mariadb/
        [sudo] password for userDB:
        total 12
        drwxr-x---. 2 mysql mysql   25 Nov 17 09:27 .
        drwxr-xr-x. 8 root  root  4096 Nov 17 09:24 ..
        -rw-rw----. 1 mysql mysql 6363 Nov 18 09:27 mariadb.log
     ```
  - Modification du fichier de conf :  
    ```
    [userDB@db ~]$ sudo cat /etc/my.cnf.d/mariadb-server.cnf

    ....
    ....
    #
    # Allow server to accept connections on all interfaces.
    #
    bind-address=0.0.0.0

    [embedded]

    [mariadb]

    [mariadb-10.5]
    server-id=1
    log-bin=/var/log/mariadb/mysql-bin.log
    max_binlog_size=100M
    relay_log=/var/log/mariadb/mysql-relay-bin
    relay_log_index=/var/log/mariadb/mysql-relay-bin.index
    ```
  - Modification de la DB pour ajouter le user du slave et qu'il soit utilisable uniquemenent par le serveur Slave (10.102.1.22) :  
    ```
    [userDB@db ~]$ mysql -u root -p
    Enter password:
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 4
    Server version: 10.5.16-MariaDB-log MariaDB Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> CREATE USER 'replication'@'10.102.1.22' identified by 'securepassword';
    Query OK, 0 rows affected (0.003 sec)

    MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO 'replication'@'10.102.1.22';
    Query OK, 0 rows affected (0.003 sec)

    MariaDB [(none)]> FLUSH PRIVILEGES;
    Query OK, 0 rows affected (0.001 sec)
    ```
### Configuration du Slave :  
 - Modification du fichier de conf :  
  ```
  [userDB2@db2 ~]$ sudo cat /etc/my.cnf.d/mariadb-server.cnf
    ...
    ...
    #
    # Allow server to accept connections on all interfaces.
    #
    bind-address=0.0.0.0

    [embedded]

    [mariadb]


    [mariadb-10.5]
    server-id=2
    log_bin=/var/log/mariadb/mysql-bin.log
    max_binlog_size=100M
    relay_log=/var/log/mariadb/mysql-relay-bin
    relay_log_index=/var/log/mariadb/mysql-relay-bin.index
  ```

 - Modification DB :  
  ```
  [userDB2@db2 ~]$ mysql -u root -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 4
Server version: 10.5.16-MariaDB-log MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> STOP SLAVE;
Query OK, 0 rows affected, 1 warning (0.001 sec)

MariaDB [(none)]> CHANGE MASTER TO MASTER_HOST='10.102.1.12', MASTER_USER='replication',MASTER_PASSWORD='securepassword', MASTER_LOG_FILE='mysql-bin.000001',MASTER_LOG_POS=806;
Query OK, 0 rows affected (0.016 sec)

MariaDB [(none)]> START SLAVE;
Query OK, 0 rows affected (0.002 sec)
  ```

- Vérification :  
  - Création d'une table avec des données dans Master :  
   ```
   [userDB@db ~]$ mysql -u root -p
    Enter password:
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 6
    Server version: 10.5.16-MariaDB-log MariaDB Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> CREATE DATABASE schooldb;
    Query OK, 1 row affected (0.001 sec)

    MariaDB [(none)]> USE schooldb;
    Database changed
    MariaDB [schooldb]> CREATE TABLE students (id int, name varchar(20), surname varchar(20));
    Query OK, 0 rows affected (0.010 sec)

    MariaDB [schooldb]> INSERT INTO students VALUES (1,"john","drake");
    Query OK, 1 row affected (0.006 sec)

    MariaDB [schooldb]> INSERT INTO students VALUES (2,"nashor","baron");
    Query OK, 1 row affected (0.004 sec)

    MariaDB [schooldb]> SELECT * FROM students
        -> ;
    +------+--------+---------+
    | id   | name   | surname |
    +------+--------+---------+
    |    1 | john   | drake   |
    |    2 | nashor | baron   |
    +------+--------+---------+
    2 rows in set (0.001 sec)
   ```
   - Check que le Slave à bien répliqué la DB du Master :  
    ```
    [userDB2@db2 ~]$ mysql -u root -p
    Enter password:
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 8
    Server version: 10.5.16-MariaDB-log MariaDB Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> SELECT * FROM schooldb.students;
    +------+--------+---------+
    | id   | name   | surname |
    +------+--------+---------+
    |    1 | john   | drake   |
    |    2 | nashor | baron   |
    +------+--------+---------+
    ```
### Synchronisation des DB du Master et du Slave  

- Sur le Master :  
Etape 1 : mysql -u root -p  
Etape 2 : FLUSH PRIVILEGES WITH READ LOCK;  
**Dans un autre terminal**  
Etape 3 : mysqldump -u root -p nextcloud > nextcloudDUMP.dump  
Etape 4 : scp nextcloudDUMP.dump userDB2@10.102.1.22:/home/userDB2/  

- Sur le Slave :  
**Terminal 1**  
Etape 5 : mysql -u root -p  
Etape 6 : STOP SLAVE;  
**Terminal 2**  
Etape 7 : mysql -u root -p nextcloud < nextcloudDUMP.dump  
**Terminal 1**  
Etape 8 : RESET SLAVE;  
Etape 9 : CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=328;  (les 2 valeurs sont obtenue grâce à la commande 'SHOW MASTER STATUS' sur le Master)  
Etape 10 : START SLAVE;  
- Sur le Master :  
Etape 11 : UNLOCK TABLES;

Les 2 Bases de données sont maintenant syncro, tout peut bien fonctionner :)  

### Bonus1 : Connexion seulement dispo pour la DB slave 
 - Preuve : 
   - connexion depuis le Slave :  
     ```
      [userDB2@db2 ~]$ mysql -u replication -h 10.102.1.12 -p
        Enter password:
        Welcome to the MariaDB monitor.  Commands end with ; or \g.
        Your MariaDB connection id is 7
        Server version: 10.5.16-MariaDB-log MariaDB Server

        Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

        Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

        MariaDB [(none)]> SHOW DATABASES
            -> ;
        +--------------------+
        | Database           |
        +--------------------+
        | information_schema |
        +--------------------+
     ```
   - Connexion depuis le serveur web :  
     ```
     [user@web ~]$ mysql -u replication -h 10.102.1.12 -p
        Enter password:
        ERROR 1045 (28000): Access denied for user 'replication'@'10.102.1.11' (using password: YES)
     ```
### Bonus2 :  Master-Master replication 

Principe : Chaque serveur est le Slave de l'autre (ils se copient mutuellement leurs données) mais ont la possibilité de traiter les requêtes du serveur Web (Master).

## Module 3 Sauvegarde de base de données

### I. Script dump  
 - Création d'un user pour dump avec juste les droits nécessaire (LOCK TABLES, SELECT) pour pouvoir dump la DB nextcloud:  
  ```
  MariaDB [(none)]> CREATE USER 'arnold'@'localhost' IDENTIFIED BY 'captaindata';
  Query OK, 0 rows affected (0.005 sec)

  MariaDB [(none)]> GRANT LOCK TABLES,SELECT ON nextcloud.* TO 'arnold'@'localhost';
  Query OK, 0 rows affected (0.002 sec)

  MariaDB [(none)]> FLUSH PRIVILEGES;
  Query OK, 0 rows affected (0.001 sec)
  ```

### II. Clean it   
 - Script clean avec commentaires :  
   ```bash
   [userDB@db srv]$ sudo cat /srv/tp3_db_dump.sh
    [sudo] password for userDB:
    #!/bin/bash
    # 22/11/22
    # Author : GARCIA Fabien
    # Dump the $dumped_dabase using $user and $password and compress it in .tar.gz

    path=$(pwd)
    cd $path/db_dumps/

    user="arnold"
    password='captaindata'
    dumped_database="nextcloud"

    date=$(date '+%y%m%d%H%M%S')
    file_name="Dump_${dumped_database}_${date}.sql"

    server="localhost"

    mysqldump -u $user -p$password -h $server $dumped_database > $file_name

    tar -czvf $file_name.tar.gz $file_name
    rm $file_name
   ```
 - Création du nouveau user :  
 ```
 [userDB@db srv]$ sudo useradd -m -d /srv/db_dumps/ db_dumps

 [userDB@db srv]$ sudo chown db_dumps tp3_db_dump.sh

[userDB@db srv]$ ls -al
total 4
drwxr-xr-x.  3 root     root      44 Nov 22 14:55 .
dr-xr-xr-x. 18 root     root     235 Sep 30 10:35 ..
drwx------.  2 db_dumps db_dumps  62 Nov 22 14:55 db_dumps
-rwxr-----.  1 db_dumps     root     485 Nov 22 14:53 tp3_db_dump.sh
 ```
 - Verification :  
 ```
 [userDB@db srv]$ sudo -u db_dumps /srv/tp3_db_dump.sh
Dump_nextcloud_221122145852.sql

[userDB@db srv]$ sudo ls db_dumps/
Dump_nextcloud_221122145852.sql.tar.gz
 ```
- Bonus gestion d'options :  
  Ajout des options D (nom de DB), h (IP serveur cible), u (user), p (password), f (nom de fichier). Les valeurs par défault sont celles écrite dans la première partie.
```
[userDB@db srv]$ sudo cat tp3_db_dump.sh
#!/bin/bash
# 22/11/22
# Author : GARCIA Fabien
# Dump the $dumped_dabase using $user and $password and compress it in .tar.gz

path=$(pwd)
cd $path/db_dumps/

user="arnold"
password='captaindata'
dumped_database="nextcloud"

date=$(date '+%y%m%d%H%M%S')
file_name="Dump_${dumped_database}_${date}.sql"

server="localhost"

while getopts "D:h:u:p:f:" option
do
        case $option in
                D)
                        dumped_database=$OPTARG
                        file_name="Dump_${dumped_database}_${date}.sql"
                        ;;
                h)
                        server=$OPTARG
                        ;;
                u)
                        user=$OPTARG
                        ;;
                p)
                        password=$OPTARG
                        ;;
                f)
                        file_name=$OPTARG
                        ;;
        esac
done
echo "User used : $user"
echo "Database : $dumped_database"
echo "File name : $file_name"
echo "Server : $server"

mysqldump -u $user -p$password -h $server $dumped_database > $file_name #|tar -czvf $file_name.tar.gz
#$file_name

tar -czf $file_name.tar.gz $file_name
rm $file_name
```

  Vérif :
  - Sans arguments :    
      ```
      [userDB@db srv]$ sudo -u db_dumps ./tp3_db_dump.sh
      User used : arnold
      Database : nextcloud
      File name : Dump_nextcloud_221122155145.sql
      Server : localhost
      ```
  - Avec arguments :  
      ```
      [userDB@db srv]$ sudo -u db_dumps ./tp3_db_dump.sh -D newDB -u john
      User used : john
      Database : newDB
      File name : Dump_newDB_221122155331.sql
      Server : localhost
      mysqldump: Got error: 1698: "Access denied for user 'john'@'localhost'" when trying to connect
      ```

- Bonus 2 : Stocker le mot de passe dans un fichier séparé :  

  - Création fichier db_pass avec les droits 600 :  
  ```
  [userDB@db srv]$ ls -al
  total 12
  drwxr-xr-x.  3 root     root       59 Nov 22 15:59 .
  dr-xr-xr-x. 18 root     root      235 Sep 30 10:35 ..
  drwx------.  2 db_dumps db_dumps 4096 Nov 22 15:53 db_dumps
  -rw-------.  1 db_dumps root       18 Nov 22 15:59 db_pass
  -rwxr-----.  1 db_dumps root      879 Nov 22 15:50 tp3_db_dump.sh

  [userDB@db srv]$ sudo cat db_pass
  var="captaindata" 
  ```
  - Modification du script
  ```
  ....
  source db_pass
  ...
  password=$var
  ....
  ```
  - Vérif :  
  ```
  [userDB@db srv]$ sudo -u db_dumps ./tp3_db_dump.sh

  User used : arnold
  Database : nextcloud
  File name : Dump_nextcloud_221122160215.sql
  Server : localhost
  ```
### III. Service et timer  

 - Création du service :  
  ```
  [userDB@db srv]$ sudo cat /etc/systemd/system/db_dump.service
  [Unit]
  Description=Dump and compress DataBase

  [Service]
  User=db_dumps
  ExecStart=/srv/tp3_db_dump.sh
  Type=oneshot


  [Install]
  WantedBy=multi-user.target
  ```
  Vérif :  
   ```
   [userDB@db srv]$ sudo systemctl start db-dump.service

  [userDB@db srv]$ sudo systemctl status db-dump.service

  ● db-dump.service - Dump and compress DataBase
      Loaded: loaded (/etc/systemd/system/db-dump.service; disabled; vendor preset: disabled)
      Active: active (exited) since Tue 2022-11-22 16:47:08 CET; 3min 32s ago
    Main PID: 4057 (code=exited, status=0/SUCCESS)
          CPU: 7ms

  Notice: journal has been rotated since unit was started, output may be incomplete.
  [userDB@db srv]$ sudo systemctl stop db-dump.service
  [userDB@db srv]$ sudo systemctl start db-dump.service
  [userDB@db srv]$ sudo systemctl status db-dump.service
  ○ db-dump.service - Dump and compress DataBase
      Loaded: loaded (/etc/systemd/system/db-dump.service; disabled; vendor preset: disabled)
      Active: inactive (dead)

  Nov 22 16:50:52 db.tp2.linux systemd[1]: Stopped Dump and compress DataBase.
  Nov 22 16:50:54 db.tp2.linux systemd[1]: Starting Dump and compress DataBase...
  Nov 22 16:50:54 db.tp2.linux bash[4149]: ./srv/tp3_db_dump.sh: line 6: db_pass: No such file or directo
  Nov 22 16:50:54 db.tp2.linux bash[4149]: User used : arnold
  Nov 22 16:50:54 db.tp2.linux bash[4149]: Database : nextcloud
  Nov 22 16:50:54 db.tp2.linux bash[4149]: File name : Dump_nextcloud_221122165054.sql
  Nov 22 16:50:54 db.tp2.linux bash[4149]: Server : localhost
  Nov 22 16:50:54 db.tp2.linux systemd[1]: db-dump.service: Deactivated successfully.
  Nov 22 16:50:54 db.tp2.linux systemd[1]: Finished Dump and compress DataBase.
   ```
  - Création du timer : 
  ```
  [userDB@db srv]$ sudo cat /etc/systemd/system/db-dump.timer
  [Unit]
  Description=Run service X

  [Timer]
  OnCalendar=*-*-* 4:00:00

  [Install]
  WantedBy=timers.target
  ```
 - Activation du timer : 
 ```
 [userDB@db srv]$ sudo systemctl daemon-reload

  [userDB@db srv]$ sudo systemctl start db-dump.timer

  [userDB@db srv]$ sudo systemctl enable db-dump.timer
  Created symlink /etc/systemd/system/timers.target.wants/db-dump.timer → /etc/systemd/system/db-dump.timer.
  [userDB@db srv]$ sudo systemctl status db-dump.timer
  ● db-dump.timer - Run service X
      Loaded: loaded (/etc/systemd/system/db-dump.timer; enabled; vendor preset: disabled)
      Active: active (waiting) since Tue 2022-11-22 17:08:28 CET; 12s ago
        Until: Tue 2022-11-22 17:08:28 CET; 12s ago
      Trigger: Wed 2022-11-23 04:00:00 CET; 10h left
    Triggers: ● db-dump.service

  Nov 22 17:08:28 db.tp2.linux systemd[1]: Started Run service X.

  [userDB@db srv]$ sudo systemctl list-timers
NEXT                        LEFT         LAST                        PASSED       UNIT                         ACTIVATES                   >
Tue 2022-11-22 18:15:33 CET 1h 5min left Tue 2022-11-22 16:16:58 CET 53min ago    dnf-makecache.timer          dnf-makecache.service
Wed 2022-11-23 00:00:00 CET 6h left      Tue 2022-11-22 00:11:58 CET 16h ago      logrotate.timer              logrotate.service
Wed 2022-11-23 04:00:00 CET 10h left     n/a                         n/a          db-dump.timer                db-dump.service
Wed 2022-11-23 13:15:33 CET 20h left     Tue 2022-11-22 13:15:33 CET 3h 54min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.servi>

4 timers listed.
 ```
### IV. Restauration de la DB  
La suite de commande à utiliser :  
```
[root@db db_dumps]# ls
Dump_nextcloud_221122171332.sql.tar.gz

[root@db db_dumps]# tar -xvf Dump_nextcloud_221122171332.sql.tar.gz
Dump_nextcloud_221122171332.sql

[root@db db_dumps]# mysql -u root -p nextcloud < Dump_nextcloud_221122171332.sql
```

## Module 7 Fail2Ban  

### 1. Installation des packages nécessaire :  
 ```
 [user@web ~]$ sudo dnf install epel-release

 [user@web ~]$ sudo dnf install fail2ban fail2ban-firewalld
 ```
### 2. Activation fail2ban :  
```
[user@web ~]$ sudo systemctl start fail2ban

[user@web ~]$ sudo systemctl enable fail2ban
Created symlink /etc/systemd/system/multi-user.target.wants/fail2ban.service → /usr/lib/systemd/system/fail2ban.service.

[user@web ~]$ sudo systemctl status fail2ban
● fail2ban.service - Fail2Ban Service
     Loaded: loaded (/usr/lib/systemd/system/fail2ban.service; enabled; vendor >
     Active: active (running) since Mon 2022-11-21 12:29:24 CET; 13s ago
       Docs: man:fail2ban(1)
   Main PID: 1474 (fail2ban-server)
      Tasks: 3 (limit: 5907)
     Memory: 12.3M
        CPU: 71ms
     CGroup: /system.slice/fail2ban.service
             └─1474 /usr/bin/python3 -s /usr/bin/fail2ban-server -xf start

Nov 21 12:29:24 web.tp2.linux systemd[1]: Starting Fail2Ban Service...
Nov 21 12:29:24 web.tp2.linux systemd[1]: Started Fail2Ban Service.
Nov 21 12:29:24 web.tp2.linux fail2ban-server[1474]: 2022-11-21 12:29:24,740 fa>
Nov 21 12:29:24 web.tp2.linux fail2ban-server[1474]: Server ready
```

### 3. Configuration fail2ban

Création du fichier suivant pour permettre a fail2ban d'agir sur le service ssh : 
```
[user@web ~]$ sudo cat /etc/fail2ban/jail.d/sshd.local
[sudo] password for user:
[sshd]
enabled = true


# Override the default global configuration for specific jail sshd
bantime = 5m
findtime= 1m
maxretry = 3
```

### 4. Vérification :  
- Test de connexion avec 3 essaies loupé :  
```
[userDB2@db2 ~]$ ssh user@10.102.1.11
user@10.102.1.11's password:
Permission denied, please try again.
user@10.102.1.11's password:
Permission denied, please try again.
user@10.102.1.11's password:
user@10.102.1.11: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).

[userDB2@db2 ~]$ ssh user@10.102.1.11
ssh: connect to host 10.102.1.11 port 22: Connection refused
```
- Visualisation de la règle ajouté au firewall :  
```
[user@web ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client ssh
  ports: 8888/tcp 80/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
        rule family="ipv4" source address="10.102.1.22" port port="ssh" protocol="tcp" reject type="icmp-port-unreachable"
```
### 5. Unban l'ip :  

```
[user@web ~]$ sudo fail2ban-client set sshd unbanip 10.102.1.22
1

[user@web ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client ssh
  ports: 8888/tcp 80/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```