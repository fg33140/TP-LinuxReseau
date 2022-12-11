#!/bin/bash

if [ $(find /mnt/snapshots -maxdepth 1 -name '*.tar' -type f -print | wc -l) -eq 0 ]; then
        echo "test"
        exit
fi
mv /mnt/snapshots/*.tar /mnt/backups/