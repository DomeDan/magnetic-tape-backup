#magnetic-tape-backup
This a script I wrote to backup files to magnetic tape from a network attached storage

# HOWTO first run:
  * create a file containing the backup number, "echo 0 > backup.count" (or any other name as long as you change the variable)
  * find what you want to backup, if its on a network-drive edit /etc/fstab so it will be mounted by this script
    edit the variables $BACKUPDIRSX to point at the directories you want to backup
  * do a test-run with the -t flag
  * do a real-run with the -r flag

# HOWTO restore backup from tape:
  * If backup.count contains number 15 and you want the latest backup then do:
  * mt -f /dev/nst0 fsf 14
  * tar xzvf /dev/nst0
  * The tar command will extract all the files in backup number 14 to the current directory

# Example
root@host:~# ./backup_sql_spcs_database.sh -r
doing backup number 4
rewinding /dev/st0
forward space count files to 4
backing up /mnt/nas/BACKUP/somehost/backup/daily/mysql/mysql_2012-03-08_02h10m.Thursday.sql.gz 
/mnt/nas/BACKUP/somehost/something_backup/backup_4.tar.gz /mnt/nas/BACKUP/Evert/documents/ 
/mnt/nas/BACKUP/Evert/pictures/ /mnt/nas/BACKUP/Börje/ /mnt/nas/BACKUP/DomeDan/www
tar: Tar bort inledande "/" från namnen i arkivet
took 241.068256914 seconds to write 682.08 Mb, speed: 2.82 Mb/s
writing End Of File at the end of backup
verify backup
rewinding /dev/st0
forward space count files to 4
start comparing backup with tape
backup OK
backup 4 finnish
writing 5 to ./backup.count
eject tape? (y/n) y
ejecting, wait...


links
* A forum-post I got inspiration from: http://www.unix.com/unix-dummies-questions-answers/9595-multiple-backups-one-tape.html
* more inspiration http://www.cyberciti.biz/faq/linux-tape-backup-with-mt-and-tar-command-howto/
* Good info about bash-scripting: http://linuxconfig.org/Bash_scripting_Tutorial
