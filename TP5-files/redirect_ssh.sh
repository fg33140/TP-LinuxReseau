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