#!/bin/bash

echo "Début de la sauvegarde : $(date)" >> /home/debian/backup_debug.log

# Charger les variables Restic
if [ -f /home/debian/.restic_env ]; then
    source /home/debian/.restic_env
    echo "Variables Restic chargées." >> /home/debian/backup_debug.log
else
    echo "Erreur : fichier .restic_env non trouvé." >> /home/debian/backup_debug.log
    exit 1
fi

# Dossier à sauvegarder
BACKUP_TARGET=/

# Exclusions
EXCLUDES="--exclude /proc --exclude /sys --exclude /dev --exclude /run --exclude /tmp --exclude /var/tmp --exclude /mnt --exclude /media --exclude /var/cache --exclude /var/lib/docker"

# Lancer la sauvegarde
restic backup $BACKUP_TARGET $EXCLUDES --verbose --tag vps-backup-$(date +%F)
if [ $? -eq 0 ]; then
    echo "Sauvegarde réussie." >> /home/debian/backup_debug.log
else
    echo "Erreur lors de la sauvegarde." >> /home/debian/backup_debug.log
    exit 1
fi

# Vérification du dépôt
restic check
if [ $? -eq 0 ]; then
    echo "Vérification du dépôt réussie." >> /home/debian/backup_debug.log
else
    echo "Erreur lors de la vérification du dépôt." >> /home/debian/backup_debug.log
    exit 1
fi

# Nettoyer les anciennes sauvegardes
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
if [ $? -eq 0 ]; then
    echo "Nettoyage des anciennes sauvegardes terminé." >> /home/debian/backup_debug.log
else
    echo "Erreur lors du nettoyage des anciennes sauvegardes." >> /home/debian/backup_debug.log
    exit 1
fi

echo "Sauvegarde terminée à $(date)" >> /home/debian/backup_debug.log

