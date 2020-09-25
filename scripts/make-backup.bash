#!/usr/bin/env bash
# make-backup.bash --- make remote backup

# bash strict mode
set -euo pipefail
IFS=$'\n\t'

say(){
    echo $(date) $@
}

host="pi@pi.local"
backup_source_dir="/igk/"
backup_target_dir="/Backups"
backup_luks_uuid="9bd8a97f-227e-4e81-8a8e-146aa7af1c27"
backup_part_label="igk-attic"

say Starting backup process on $(hostname), target host: $host
say Unlocking LUKS container partition $backup_luks_uuid

ssh -t "$host" sudo udisksctl unlock -b "/dev/disk/by-uuid/$backup_luks_uuid"
ssh "$host" sudo mount -osync "/dev/disk/by-label/$backup_part_label" /mnt/

say Unlocked LUKS and mounted $backup_part_label, attempting backup

export BORG_REPO="$host:/mnt$backup_target_dir"
borg create --stats --progress --compression lz4 ::{user}-{now} \
     "$backup_source_dir"

say Backup was successful, unmount backup partition and lock LUKS

ssh "$host" sudo umount /mnt/
ssh "$host" sudo udisksctl lock -b "/dev/disk/by-uuid/$backup_luks_uuid"

say Done
