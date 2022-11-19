# TP2 : Gestion de service

## I. Un premier serveur web

### 1. Installation

- Installer le serveur Apache
 ```
 sudo dnf install httpd -y
 ```
- Démarrer le service Apache

```
[user@db ~]$ sudo systemctl status httpd

○ httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled; vendor preset: disabled)
     Active: inactive (dead)
       Docs: man:httpd.service(8)

[user@db ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success

[user@db ~]$ sudo systemctl start httpd

[user@db ~]$ sudo systemctl enable httpd
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.

[user@db ~]$ sudo systemctl status httpd
● httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
     Active: active (running) since Tue 2022-11-15 10:40:19 CET; 9s ago
       Docs: man:httpd.service(8)
   Main PID: 1025 (httpd)
     Status: "Total requests: 0; Idle/Busy workers 100/0;Requests/sec: 0; Bytes served/sec:   0 B/sec"
      Tasks: 213 (limit: 5907)
     Memory: 39.6M
        CPU: 106ms
     CGroup: /system.slice/httpd.service
             ├─1025 /usr/sbin/httpd -DFOREGROUND
             ├─1026 /usr/sbin/httpd -DFOREGROUND
             ├─1027 /usr/sbin/httpd -DFOREGROUND
             ├─1028 /usr/sbin/httpd -DFOREGROUND
             └─1029 /usr/sbin/httpd -DFOREGROUND

Nov 15 10:40:19 db.localdomain systemd[1]: Starting The Apache HTTP Server...
Nov 15 10:40:19 db.localdomain httpd[1025]: AH00558: httpd: Could not reliably determine the se>
Nov 15 10:40:19 db.localdomain systemd[1]: Started The Apache HTTP Server.
Nov 15 10:40:19 db.localdomain httpd[1025]: Server configured, listening on: port 80
```
  Savoir sur quel port httpd écoute :  
  ```
  [user@web ~]$ sudo ss -lntp

State    Recv-Q   Send-Q     Local Address:Port     Peer Address:Port  Process
LISTEN   0        128              0.0.0.0:22            0.0.0.0:*      users:(("sshd",pid=710,fd=3))
LISTEN   0        128                 [::]:22               [::]:*      users:(("sshd",pid=710,fd=4))
LISTEN   0        511                    *:80                  *:*      users:(("httpd",pid=726,fd=4),("httpd",pid=725,fd=4),("httpd",pid=724,fd=4),("httpd",pid=694,fd=4))
  ```

- Test  
   - depuis la VM
  ```
  [user@web ~]$ curl localhost
    <!doctype html>
    <html>
    <head>
        <meta charset='utf-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <title>HTTP Server Test Page powered by: Rocky Linux</title>
        <style type="text/css">
        /*<![CDATA[*/

  ```
    - à "distance"
    ```
    fg331@LAPTOP-VI1KK0CA MINGW64 ~
    $ curl 10.102.1.11:80

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
    ```
### 2. Avancer vers la maîtrise du service  

Le service Apache ....  
```
[user@web ~]$ cat /etc/httpd/conf/httpd.conf

ServerRoot "/etc/httpd"

Listen 80

Include conf.modules.d/*.conf

User apache
Group apache


ServerAdmin root@localhost


<Directory />
    AllowOverride none
    Require all denied
</Directory>


DocumentRoot "/var/www/html"

<Directory "/var/www">
    AllowOverride None
    Require all granted
</Directory>

<Directory "/var/www/html">
    Options Indexes FollowSymLinks

    AllowOverride None

    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "logs/error_log"

LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>


    CustomLog "logs/access_log" combined
</IfModule>

<IfModule alias_module>


    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"

</IfModule>

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule mime_module>
    TypesConfig /etc/mime.types

    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz



    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

AddDefaultCharset UTF-8

<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>


EnableSendfile on

IncludeOptional conf.d/*.conf
```

- Déterminer sous quel utilisateur tourne le processus Apache  
  - La ligne dans la conf :   
   ```
   User apache
   ```
  - liste des processus :  
   ```
   [user@web ~]$ ps -ef | grep httpd
    root         694       1  0 11:14 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
    apache       721     694  0 11:14 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
    apache       724     694  0 11:14 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
    apache       725     694  0 11:14 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
    apache       726     694  0 11:14 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
   ```
   - Droits page d'accueil :  
    ```
    [user@web ~]$ ls -al /usr/share/testpage/
    total 12
    drwxr-xr-x.  2 root root   24 Nov 15 09:51 .
    drwxr-xr-x. 81 root root 4096 Nov 15 09:51 ..
    -rw-r--r--.  1 root root 7620 Jul  6 04:37 index.html
    ```
    On remarque que les droits de lectures sont accordé à la catégorie "others", donc l'utilisateur "apache" possède le droit de lecture.

- Changer l'utilisateur utilisé par Apache
  - Création utilisateur "cheval"  
    ```
    [user@web ~]$ sudo useradd -d /usr/share/httpd -s /sbin/nologin cheval

    useradd: warning: the home directory /usr/share/httpd already exists.
    useradd: Not copying any file from skel directory into it.
    Creating mailbox file: File exists
    ```
  - Changement utilisateur de Apache :  
   ```
   [user@web ~]$ sudo cat /etc/httpd/conf/httpd.conf

   User cheval
   ```
   Vérification :  
   ```
   [user@web ~]$ ps -ef |grep httpd
    root        1212       1  0 11:53 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
    cheval      1213    1212  0 11:53 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
    cheval      1214    1212  0 11:53 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
    cheval      1215    1212  0 11:53 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
    cheval      1216    1212  0 11:53 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
   ```

- Faites en sorte que Apache tourne sur un autre port
  - Modification du port d'écoute :  
   ```
   [user@web ~]$ sudo cat /etc/httpd/conf/httpd.conf

   Listen 8888
   ```
  - Mise a jour firewall :  
  ```
  [user@web ~]$ sudo firewall-cmd --add-port=8888/tcp --permanent
    success
  [user@web ~]$ sudo firewall-cmd --remove-port=80/tcp --permanent
    success
  ```
  - Preuve :  
   ```
   [user@web ~]$ ss -lntp
    State      Recv-Q      Send-Q           Local Address:Port           Peer Address:Port     Process
    LISTEN     0           128                    0.0.0.0:22                  0.0.0.0:*
    LISTEN     0           128                       [::]:22                     [::]:*
    LISTEN     0           511                          *:8888                      *:*
   ```

   - Accès en local :  
   ```
   [user@web ~]$ curl localhost:8888
    <!doctype html>
    <html>
    <head>
        <meta charset='utf-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <title>HTTP Server Test Page powered by: Rocky Linux</title>
        <style type="text/css">
        /*<![CDATA[*/

        html {
            height: 100%;
            width: 100%;
        }
   ```
   - Accès à "distance" :  
   ```
   fg331@LAPTOP-VI1KK0CA MINGW64 ~
    $ curl 10.102.1.11:8888
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
            height: 100%;
            width: 100%;
        }
   ```

   Le [fichier de conf](./files/httpd.conf) httpd.conf

## II. Une stack web plus avancée

### 2. Setup

A. Base de données
 - install de MariaDB  
  Listes des commandes d'install :  
```
[userDB@db ~]$ sudo systemctl enable mariadb
[sudo] password for userDB:
Created symlink /etc/systemd/system/mysql.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/mysqld.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service → /usr/lib/systemd/system/mariadb.service.

[userDB@db ~]$ sudo systemctl status mariadb
○ mariadb.service - MariaDB 10.5 database server
     Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; vendor p>
     Active: inactive (dead)
       Docs: man:mariadbd(8)
             https://mariadb.com/kb/en/library/systemd/
[userDB@db ~]$ systemctl start mariadb
Failed to start mariadb.service: Access denied
See system logs and 'systemctl status mariadb.service' for details.

[userDB@db ~]$ sudo systemctl start mariadb

[userDB@db ~]$ sudo systemctl status mariadb
● mariadb.service - MariaDB 10.5 database server
     Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; vendor p>
     Active: active (running) since Thu 2022-11-17 09:27:21 CET; 3s ago
       Docs: man:mariadbd(8)
             https://mariadb.com/kb/en/library/systemd/
    Process: 12801 ExecStartPre=/usr/libexec/mariadb-check-socket (code=exited,>
    Process: 12823 ExecStartPre=/usr/libexec/mariadb-prepare-db-dir mariadb.ser>
    Process: 12916 ExecStartPost=/usr/libexec/mariadb-check-upgrade (code=exite>
   Main PID: 12904 (mariadbd)
     Status: "Taking your SQL requests now..."
      Tasks: 11 (limit: 5907)
     Memory: 75.7M
        CPU: 183ms
     CGroup: /system.slice/mariadb.service
             └─12904 /usr/libexec/mariadbd --basedir=/usr

Nov 17 09:27:21 db.localdomain mariadb-prepare-db-dir[12862]: you need t>
Nov 17 09:27:21 db.localdomain mariadb-prepare-db-dir[12862]: After conn>
Nov 17 09:27:21 db.localdomain mariadb-prepare-db-dir[12862]: able to co>
Nov 17 09:27:21 db.localdomain mariadb-prepare-db-dir[12862]: See the Ma>
Nov 17 09:27:21 db.localdomain mariadb-prepare-db-dir[12862]: Please rep>
Nov 17 09:27:21 db.localdomain mariadb-prepare-db-dir[12862]: The latest>
Nov 17 09:27:21 db.localdomain mariadb-prepare-db-dir[12862]: Consider j>

[userDB@db ~]$ sudo mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, .......
```
  Vérif avec la commande ss :  
  ```
  [userDB@db ~]$ sudo ss -lntp
[sudo] password for userDB:
State    Recv-Q    Send-Q       Local Address:Port       Peer Address:Port   Process
LISTEN   0         128                0.0.0.0:22              0.0.0.0:*       users:(("sshd",pid=715,fd=3))
LISTEN   0         80                       *:3306                  *:*       users:(("mariadbd",pid=12904,fd=19))
LISTEN   0         128                   [::]:22                 [::]:*       users:(("sshd",pid=715,fd=4))
  ```

- Préparation de la base pour NextCloud

```
[userDB@db ~]$ sudo mysql -u root -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 11
Server version: 10.5.16-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE USER 'nextcloud'@'10.102.1.11' IDENTIFIED BY 'pewpewpew';
Query OK, 0 rows affected (0.005 sec)

MariaDB [(none)]> CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.102.1.11';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.000 sec)
```

- Exploration de base de données

```
[user@web ~]$ mysql -u nextcloud -h 10.102.1.12 -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 4
Server version: 5.5.5-10.5.16-MariaDB MariaDB Server

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> SHOW DATABASES
    -> ;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
2 rows in set (0.00 sec)

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
2 rows in set (0.00 sec)

mysql> USE nextcloud;
Database changed

mysql> SHOW TABLES;
Empty set (0.00 sec)

mysql> USE information_schema;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

mysql> SHOW TABLES;
+---------------------------------------+
| Tables_in_information_schema          |
+---------------------------------------+
| ALL_PLUGINS                           |
| APPLICABLE_ROLES                      |
| CHARACTER_SETS                        |
| CHECK_CONSTRAINTS                     |
| COLLATIONS                            |
| COLLATION_CHARACTER_SET_APPLICABILITY |
| COLUMNS                               |
```

- Trouver une commande SQL qui permet de lister tous les utilisateurs de la base de données  

```
[userDB@db ~]$ sudo mysql -u root -p
[sudo] password for userDB:
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 5
Server version: 10.5.16-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> SELECT user FROM mysql.user;
+-------------+
| User        |
+-------------+
| nextcloud   |
| mariadb.sys |
| mysql       |
| root        |
+-------------+
4 rows in set (0.001 sec)
```

B. Serveur Web de NextCloud  
- Install de PHP  
 **j'ai fais toutes les commandes**
- Install de tous les modules PHP nécessaires pour NextCloud  
 **Commande effectué**

- Récupérer NextCloud
 
  - Création arborescence :  
    ```
    [user@web ~]$ sudo mkdir /var/www/tp2_nextcloud/
    ```
  - récupération du .zip :  
    ```
    [user@web tp2_nextcloud]$ sudo wget https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip
    --2022-11-17 12:09:54--  https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip
    Resolving download.nextcloud.com (download.nextcloud.com)... 95.217.64.181, 2a01:4f9:2a:3119::181
    Connecting to download.nextcloud.com (download.nextcloud.com)|95.217.64.181|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 176341139 (168M) [application/zip]
    Saving to: ‘nextcloud-25.0.0rc3.zip’

    nextcloud-25.0.0rc3.zip   100%[====================================>] 168.17M  4.36MB/s    in 42s

    2022-11-17 12:10:36 (4.02 MB/s) - ‘nextcloud-25.0.0rc3.zip’ saved [176341139/176341139]
    ```
    - Récupérer NextCloud  
    ```
    [user@web tp2_nextcloud]$ pwd
    /var/www/tp2_nextcloud

    [user@web tp2_nextcloud]$ ls -al
    total 172344
    drwxr-xr-x. 14 apache root        4096 Nov 17 12:31 .
    drwxr-xr-x.  5 root   root          54 Nov 17 12:27 ..
    drwxr-xr-x. 47 apache apache      4096 Oct  6 14:47 3rdparty
    drwxr-xr-x. 50 apache apache      4096 Oct  6 14:44 apps
    -rw-r--r--.  1 apache apache     19327 Oct  6 14:42 AUTHORS
    drwxr-xr-x.  2 apache apache        67 Oct  6 14:47 config
    -rw-r--r--.  1 apache apache      4095 Oct  6 14:42 console.php
    -rw-r--r--.  1 apache apache     34520 Oct  6 14:42 COPYING
    drwxr-xr-x. 23 apache apache      4096 Oct  6 14:47 core
    -rw-r--r--.  1 apache apache      6317 Oct  6 14:42 cron.php
    drwxr-xr-x.  2 apache apache      8192 Oct  6 14:42 dist
    -rw-r--r--.  1 apache apache       156 Oct  6 14:42 index.html
    -rw-r--r--.  1 apache apache      3456 Oct  6 14:42 index.php
    drwxr-xr-x.  6 apache apache       125 Oct  6 14:42 lib
    -rw-r--r--.  1 apache root   176341139 Oct  6 14:49 nextcloud-25.0.0rc3.zip
    -rw-r--r--.  1 apache apache       283 Oct  6 14:42 occ
    drwxr-xr-x.  2 apache apache        23 Oct  6 14:42 ocm-provider
    drwxr-xr-x.  2 apache apache        55 Oct  6 14:42 ocs
    drwxr-xr-x.  2 apache apache        23 Oct  6 14:42 ocs-provider
    -rw-r--r--.  1 apache apache      3139 Oct  6 14:42 public.php
    -rw-r--r--.  1 apache apache      5426 Oct  6 14:42 remote.php
    drwxr-xr-x.  4 apache apache       133 Oct  6 14:42 resources
    -rw-r--r--.  1 apache apache        26 Oct  6 14:42 robots.txt
    -rw-r--r--.  1 apache apache      2452 Oct  6 14:42 status.php
    drwxr-xr-x.  3 apache apache        35 Oct  6 14:42 themes
    drwxr-xr-x.  2 apache apache        43 Oct  6 14:44 updater
    -rw-r--r--.  1 apache apache       387 Oct  6 14:47 version.php
    ```
  - Adapter la configuration d'Apache :  
    ```
    [user@web tp2_nextcloud]$ sudo cat /etc/httpd/conf.d/TP2_nextcloud.conf
    <VirtualHost *:80>
      # on indique le chemin de notre webroot
      DocumentRoot /var/www/tp2_nextcloud/
      # on précise le nom que saisissent les clients pour accéder au service
      ServerName  web.tp2.linux

      # on définit des règles d'accès sur notre webroot
      <Directory /var/www/tp2_nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
        <IfModule mod_dav.c>
          Dav off
        </IfModule>
      </Directory>
    </VirtualHost>
    ```
  - Redémarrer le service Apache :  
   ```
   [user@web tp2_nextcloud]$ sudo systemctl restart httpd
   ```
C. Finaliser l'installation de NextCloud
 - Modification fichier Hosts sur le PC :  
 ```
 fg331@LAPTOP-VI1KK0CA MINGW64 ~
$ cat /c/Windows/System32/drivers/etc/hosts

10.102.1.11 web.tp2.linux

# Added by Docker Desktop
10.33.19.104 host.docker.internal
10.33.19.104 gateway.docker.internal
# To allow the same kube context to work on the host and the container:
127.0.0.1 kubernetes.docker.internal
# End of section
 ```
 - Exploration de la base de données :  
  ```
  MariaDB [nextcloud]> SHOW TABLES;
+-----------------------------+
| Tables_in_nextcloud         |
+-----------------------------+
| oc_accounts                 |
| oc_accounts_data            |
| oc_activity                 |
| oc_activity_mq              |
| oc_addressbookchanges       |
| oc_addressbooks             |
| oc_appconfig                |
| oc_authorized_groups        |
| oc_authtoken                |
| oc_bruteforce_attempts      |
| oc_calendar_invitations     |
| oc_calendar_reminders       |
| oc_calendar_resources       |
| oc_calendar_resources_md    |
| oc_calendar_rooms           |
| oc_calendar_rooms_md        |
| oc_calendarchanges          |
| oc_calendarobjects          |
| oc_calendarobjects_props    |
| oc_calendars                |
| oc_calendarsubscriptions    |
| oc_cards                    |
| oc_cards_properties         |
| oc_circles_circle           |
| oc_circles_event            |
| oc_circles_member           |
| oc_circles_membership       |
| oc_circles_mount            |
| oc_circles_mountpoint       |
| oc_circles_remote           |
| oc_circles_share_lock       |
| oc_circles_token            |
| oc_collres_accesscache      |
| oc_collres_collections      |
| oc_collres_resources        |
| oc_comments                 |
| oc_comments_read_markers    |
| oc_dav_cal_proxy            |
| oc_dav_shares               |
| oc_direct_edit              |
| oc_directlink               |
| oc_federated_reshares       |
| oc_file_locks               |
| oc_file_metadata            |
| oc_filecache                |
| oc_filecache_extended       |
| oc_files_trash              |
| oc_flow_checks              |
| oc_flow_operations          |
| oc_flow_operations_scope    |
| oc_group_admin              |
| oc_group_user               |
| oc_groups                   |
| oc_jobs                     |
| oc_known_users              |
| oc_login_flow_v2            |
| oc_migrations               |
| oc_mimetypes                |
| oc_mounts                   |
| oc_notifications            |
| oc_notifications_pushhash   |
| oc_notifications_settings   |
| oc_oauth2_access_tokens     |
| oc_oauth2_clients           |
| oc_photos_albums            |
| oc_photos_albums_files      |
| oc_photos_collaborators     |
| oc_preferences              |
| oc_privacy_admins           |
| oc_profile_config           |
| oc_properties               |
| oc_ratelimit_entries        |
| oc_reactions                |
| oc_recent_contact           |
| oc_schedulingobjects        |
| oc_share                    |
| oc_share_external           |
| oc_storages                 |
| oc_storages_credentials     |
| oc_systemtag                |
| oc_systemtag_group          |
| oc_systemtag_object_mapping |
| oc_text_documents           |
| oc_text_sessions            |
| oc_text_steps               |
| oc_trusted_servers          |
| oc_twofactor_backupcodes    |
| oc_twofactor_providers      |
| oc_user_status              |
| oc_user_transfer_owner      |
| oc_users                    |
| oc_vcategory                |
| oc_vcategory_to_object      |
| oc_webauthn                 |
| oc_whats_new                |
+-----------------------------+
  ```