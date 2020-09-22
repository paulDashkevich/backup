#!/usr/bin/env bash
set -o allexport
REPOSITORY="root@backup:/var/backup"
echo $REPOSITORY
export REPOSITORY
export BORG_PASSPHRASE=123123

LOG="/var/log/backup/backup.log"

#Backup all of "/etc"
echo "Transfer files..."
borg create -v --stats --compression lz4                 \
        $REPOSITORY::'{hostname}-{now:%Y-%m-%d-%H:%M}' /etc

# Route the normal process logging to journalctl
exec > ${LOG}
exec 2>&1

borg prune -v $REPOSITORY --prefix '{hostname}-'         \
    --keep-minutely=10                                   \
    --keep-hourly=5                                      \
    --keep-daily=2                                       \
    --keep-weekly=2                                      \
    --keep-monthly=3                                     \
    --keep-yearly=1                                      \

borg list $REPOSITORY

# Unset the password
# export BORG_PASSPHRASE=123123
exit 0
