# TP5 Projet Perso SSH Docker

## Objectif :  
L'objectif est de créer un honeypot ssh (sur une machine qu'on appellera "honey"), ou chaque connexion réussi sur un certain *user* est envoyé dans un conteneur (principalement destiné aux bots présent sur le net afin d'étudier leurs actions lors d'une connexion réussi).  

Une snapshot des conteneurs est effectué lorsque ce dernier meurt, puis envoyé sur un point de montage NFS géré par une autre machine (qu'on appellera "serveur NFS") utilisant un service afin de transférer automatique les snapshots vers un point de montage RAID1 (monter avec des options spécifique car il n'y aura que des fichiers non executable) destiné à stocker les snapshots.

## Prérequis :  
OS pour les 2 machines : CentOS
- Honey : 
  - installation docker
  - installation des packets :  
    ```
    dnf install nfs-utils nfs4-acl-tools sshpass
    ```
- Serveur NFS :  
  ```
  dnf install nfs-utils
  ```

## I. Machine honey

### 1. Création image docker :  
Utilisation d'un docker file, possédant les outils nécessaire pour établir une connexion SSH et des outils utile pour rendre la machine un peu plus "réaliste"  
[Dockerfile](./TP5-files/Dockerfile) :  
```
[user@honey build]$ cat Dockerfile
FROM debian

RUN apt update -y && \
    apt install -y iproute2 iputils-ping ssh sudo openssh-server

RUN useradd -m user -s /bin/bash

RUN printf "root\nroot" | passwd user

RUN mkdir /var/run/sshd

RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config

docker run

EXPOSE 22

CMD [ "/usr/sbin/sshd", "-D" ]
```

### 2. Création et mise en place du script s'exécutant à chaque connexion ssh sur *user*

- Le script [redirect_ssh.sh](./TP5-files/redirect_ssh.sh) :  
  ```
  [user@honey ~]$ cat redirect_ssh.sh
  #!/bin/bash


  # Initialisation
  name=( $SSH_CONNECTION )
  docker run --hostname server --name $name -d test2 &> /dev/null
  IP=""
  for ipadd in $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $name )
  do
          IP="$ipadd"
  done

  # Connexion au conteneur
  sshpass -p root ssh -o StrictHostKeyChecking=no user@$IP

  # Close container
  docker kill $(docker ps -aqf "name=$name") &> /dev/null

  # Snapshot
  docker export $name > /mnt/snapshots/$name.tar

  # Cleaning
  docker rm $name &> /dev/null
  exit
  ```
- Exécution automatique du script lors de la connexion ssh :  
   Ajout des lignes suivantes dans /etc/ssh/sshd_config :  
    ```
    Match User user
        ForceCommand /home/user/redirect_ssh.sh
    ```
    Le script s'exécutera à chaque connexion ssh sur l'utilisateur *user*

### 3. Point de montage NFS (client)

La machine 10.104.4.22 est le server NFS
```
[user@honey ~]$ showmount -e 10.104.4.22
Export list for 10.104.4.22:
/mnt/snapshots 10.104.4.0/24
```

- Montage :  
```
[user@honey ~]$ mkdir -p /mnt/snapshots

[user@honey ~]$ mount -t nfs  10.104.4.22:/mnt/snapshots /mnt/snapshots
```

- Vérification :  
```
[user@honey ~]$ mount | grep nfs

10.104.4.22:/mnt/snapshots on /mnt/snapshots type nfs4 (rw,relatime,vers=4.2,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.104.4.11,local_lock=none,addr=10.104.4.22)
```

## II. Machine NFS

### 1. Mise en place serveur NFS 

```
[user@serverNFS ~]$ systemctl start nfs-server.service

[user@serverNFS ~]$ systemctl enable nfs-server.service

[user@serverNFS ~]$ systemctl status nfs-server.service

[user@serverNFS ~]$ mkdir  -p /mnt/snapshots
```

- Edit du fichier /etc/exports :  
```
[user@serverNFS ~]$ cat /etc/exports
/mnt/snapshots          10.104.4.0/24(rw,sync,root_squash)
```

- Lancement NFS :  
```
[user@serverNFS ~]$ exportfs -arv
```

- Vérification :  
```
[user@serverNFS ~]$ sudo exportfs -s
[sudo] password for user:
/mnt/snapshots  10.104.4.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

- Ajout règle de firewall :  
```
[user@serverNFS ~]$ firewall-cmd --permanent --add-service=nfs

[user@serverNFS ~]$ firewall-cmd --permanent --add-service=rpc-bind

[user@serverNFS ~]$ firewall-cmd --permanent --add-service=mountd

[user@serverNFS ~]$ firewall-cmd --reload
```

### 2. Mise en place d'un point de montage RAID1

- Ajout de 2 disques de stockage de 8Go chacun
```
[user@docker1 ~]$ sudo fdisk -l
[sudo] password for user:
Disk /dev/sda: 8 GiB, 8589934592 bytes, 16777216 sectors
Disk model: VBOX HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xb9546c72

Device     Boot   Start      End  Sectors Size Id Type
/dev/sda1  *       2048  2099199  2097152   1G 83 Linux
/dev/sda2       2099200 16777215 14678016   7G 8e Linux LVM


Disk /dev/sdb: 8 GiB, 8589934592 bytes, 16777216 sectors
Disk model: VBOX HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdc: 8 GiB, 8589934592 bytes, 16777216 sectors
Disk model: VBOX HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/rl-root: 6.2 GiB, 6652166144 bytes, 12992512 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/rl-swap: 820 MiB, 859832320 bytes, 1679360 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```


Création de partition MBR :  
```
[user@docker1 ~]$ sudo parted /dev/sdb mklabel msdos
[sudo] password for user:
Information: You may need to update /etc/fstab.

[user@docker1 ~]$ sudo parted /dev/sdc mklabel msdos
Information: You may need to update /etc/fstab.
```

Création d'une partition pour chaque périphérique formater en type "Linux raid autodetect" :  

```
[user@docker1 ~]$ sudo fdisk /dev/sdb
n - p - 1 - Enter - Enter - t - fd -w

[user@docker1 ~]$ sudo fdisk /dev/sdc
n - p - 1 - Enter - Enter - t - fd -w
```

Création du logical drive RAID 1 :  
```
[user@docker1 ~]$ sudo mdadm --create /dev/md0 --level=mirror --raid-devices=2 /dev/sdb1 /dev/sdc1
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
Continue creating array? y
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.

[user@docker1 ~]$ cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sdc1[1] sdb1[0]
      8382464 blocks super 1.2 [2/2] [UU]
      [====>................]  resync = 23.8% (2001408/8382464) finish=0.4min speed=222378K/sec

unused devices: <none>

[user@docker1 ~]$ cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sdc1[1] sdb1[0]
      8382464 blocks super 1.2 [2/2] [UU]
      [==========>..........]  resync = 54.8% (4601600/8382464) finish=0.2min speed=209163K/sec

unused devices: <none>

[user@docker1 ~]$ cat /proc/mdstat
Personalities : [raid1]
md0 : active raid1 sdc1[1] sdb1[0]
      8382464 blocks super 1.2 [2/2] [UU]

unused devices: <none>
```
Check :  
```
[user@docker1 ~]$ sudo mdadm --examine /dev/sdb1 /dev/sdc1
/dev/sdb1:
          Magic : a92b4efc
        Version : 1.2
    Feature Map : 0x0
     Array UUID : 6a4609fd:3cb66fcb:fad09946:0f6bd5a7
           Name : docker1.tp4.linux:0  (local to host docker1.tp4.linux)
  Creation Time : Sat Dec 10 20:48:13 2022
     Raid Level : raid1
   Raid Devices : 2

 Avail Dev Size : 16764928 sectors (7.99 GiB 8.58 GB)
     Array Size : 8382464 KiB (7.99 GiB 8.58 GB)
    Data Offset : 10240 sectors
   Super Offset : 8 sectors
   Unused Space : before=10160 sectors, after=0 sectors
          State : clean
    Device UUID : e9cd399c:8ec6138a:caa54c5b:ce3753f4

    Update Time : Sat Dec 10 20:48:55 2022
  Bad Block Log : 512 entries available at offset 16 sectors
       Checksum : dc9b7db3 - correct
         Events : 17


   Device Role : Active device 0
   Array State : AA ('A' == active, '.' == missing, 'R' == replacing)
/dev/sdc1:
          Magic : a92b4efc
        Version : 1.2
    Feature Map : 0x0
     Array UUID : 6a4609fd:3cb66fcb:fad09946:0f6bd5a7
           Name : docker1.tp4.linux:0  (local to host docker1.tp4.linux)
  Creation Time : Sat Dec 10 20:48:13 2022
     Raid Level : raid1
   Raid Devices : 2

 Avail Dev Size : 16764928 sectors (7.99 GiB 8.58 GB)
     Array Size : 8382464 KiB (7.99 GiB 8.58 GB)
    Data Offset : 10240 sectors
   Super Offset : 8 sectors
   Unused Space : before=10160 sectors, after=0 sectors
          State : clean
    Device UUID : 4cc5b4d7:4b17179a:513d972c:d98a9d25

    Update Time : Sat Dec 10 20:48:55 2022
  Bad Block Log : 512 entries available at offset 16 sectors
       Checksum : 2aaeb066 - correct
         Events : 17


   Device Role : Active device 1
   Array State : AA ('A' == active, '.' == missing, 'R' == replacing)
```

Montage avec l'utilisation des options "noexec,nouser,nodev" car le montage ne va accueillir que des .tar (les snapshots des conteneurs) :  
```
[user@docker1 ~]$ sudo mkfs.ext4 /dev/md0
[sudo] password for user:
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 2095616 4k blocks and 524288 inodes
Filesystem UUID: 10e72eaa-1833-4c18-bac1-b740baa04e85
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

[user@docker1 ~]$ sudo mount -o async,auto,noexec,nouser,nodev,suid /dev/md0 /mnt/backups/
[sudo] password for user:

[user@docker1 ~]$ df -h /mnt/backups/
Filesystem      Size  Used Avail Use% Mounted on
/dev/md0        7.8G   24K  7.4G   1% /mnt/backups
```
Sauvegarde RAID1 configuration :  
```
[user@docker1 ~]$ sudo mdadm --detail --scan --verbose | sudo tee -a /etc/mdadm/mdadm.conf
[sudo] password for user:
tee: /etc/mdadm/mdadm.conf: No such file or directory
ARRAY /dev/md0 level=raid1 num-devices=2 metadata=1.2 name=docker1.tp4.linux:0 UUID=6a4609fd:3cb66fcb:fad09946:0f6bd5a7
   devices=/dev/sdb1,/dev/sdc1
```

Ajout de la ligne suivant dans le fichier /etc/fstab pour sauvegarder le montage :  
```
/dev/md0        /mnt/backups/           ext4    async,auto,noexec,nouser,nodev,suid     0 0
```

### 3. Création d'un service avec timer
Ici on va créer un service oneshot, exécuté toutes les minutes, pour transférer automatiquement les snapshots provenant du montage NFS, vers le point de montage RAID1.  

- Le script [transfer.sh](./TP5-files/transfer.sh) :  
```
[root@serverNFS ~]# cat transfer.sh
#!/bin/bash

if [ $(find /mnt/snapshots -maxdepth 1 -name '*.tar' -type f -print | wc -l) -eq 0 ]; then
        echo "test"
        exit
fi
mv /mnt/snapshots/*.tar /mnt/backups/
```

- Création des fichiers .service et .timer dans /etc/systemd/system/ :  
[transfer.service](./TP5-files/transfer.service) :  
```
[root@serverNFS ~]# cat /etc/systemd/system/transfer.service
[Unit]
Description=Transfer .tar files from NFS mount to RAID1 mount
Wants=transfer.timer

[Service]
Type=oneshot
ExecStart=/bin/bash ./root/transfer.sh

[Install]
WantedBy=multi-user.target
```
[transfer.timer](./TP5-files/transfer.timer) :  
```
[root@serverNFS ~]# cat /etc/systemd/system/transfer.timer
[Unit]
Description=Timer for transfer.service (every minute)
Requires=transfer.service

[Timer]
Unit=transfer.service
OnCalendar=*-*-* *:*:00

[Install]
WantedBy=timers.target
```

- Activation :  
```
[root@serverNFS ~]# systemctl start transfer.service

[root@serverNFS ~]# systemctl enable transfer.service
Created symlink /etc/systemd/system/multi-user.target.wants/transfer.service → /etc/systemd/system/transfer.service.

[root@serverNFS ~]# systemctl status transfer.service
○ transfer.service - Transfer .tar files from NFS mount to RAID1 mount
     Loaded: loaded (/etc/systemd/system/transfer.service; enabled; vendor preset: disabled)
     Active: inactive (dead) since Sun 2022-12-11 22:56:27 CET; 22s ago
TriggeredBy: ● transfer.timer
   Main PID: 1595 (code=exited, status=0/SUCCESS)
        CPU: 2ms

Dec 11 22:56:27 serverNFS systemd[1]: Starting Transfer .tar files from NFS mount to RAID1 mount...
Dec 11 22:56:27 serverNFS bash[1595]: test
Dec 11 22:56:27 serverNFS systemd[1]: transfer.service: Deactivated successfully.
Dec 11 22:56:27 serverNFS systemd[1]: Finished Transfer .tar files from NFS mount to RAID1 mount.
```

- Vérif :  
```
[root@serverNFS ~]# touch /mnt/snapshots/otertest.tar

[root@serverNFS ~]# ls /mnt/snapshots/
otertest.tar
```
 1 minutes plus tard :  
 ```
 [root@serverNFS ~]# ls /mnt/snapshots/

 [root@serverNFS ~]# ls /mnt/backups/
 lost+found otertest.tar
 ```