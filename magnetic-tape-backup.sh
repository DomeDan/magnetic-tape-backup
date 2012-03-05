#!/bin/bash

# magnetic-tape-backup v0.1
# Original author: DomeDan
# License: GPLv3
# http://www.gnu.org/licenses/gpl-3.0.txt

#This a script I wrote to backup files to magnetic tape from a network attached storage
#
# HOWTO first run:
# 1. create a file containing the backup number, "echo 0 > backup.count" (or any other name as long as you change the variable)
# 2. find what you want to backup, if its on a network-drive edit /etc/fstab so it will be mounted by this script
#    edit the variables $BACKUPDIRS to point at the directories you want to backup
# 3. do a test-run with the -t flag
# 4. do a real-run with the -r flag
#
# HOWTO restore backup from tape:
# If backup.count contains number 15 and you want the latest backup then do:
# mt -f /dev/nst0 fsf 14
# tar xzvf /dev/nst0
# The tar command will extract all the files in backup number 14 to the current directory
#
 
 
## variables
#device
DEV="/dev/st0"
DEVN="/dev/nst0"
 
#the variable that contains the backup number that is the next in line (e.g.: I have done 2 backups on this tape, then backup.count should contain number 3)
#if the file does not exist, create it, should contain 0 at first backup
COUNTFILE="./backup.count"
 
#latest mysql backup from every database, using automysqlbackup.sh.2.5 (http://sourceforge.net/projects/automysqlbackup/)
BACKUPDIRS1=`dir='/mnt/nas/BACKUP/somehost/backup/daily/*'; for d in $dir; do for f in $d; do echo -n $d/; ls --color=never -rt $f | sed 's/  /\n/' | tail -1 | awk '{USTRING=$1 USTRING" "} END{print USTRING}'; done; done`
#tree example:
#/mnt/nas/BACKUP/somehost/backup/daily/
#|-- mydatabase
#|   |-- mydatabase_2012-01-11_16h49m.onsdag.sql.gz
#|   |-- mydatabase_2012-02-19_02h10m.Sunday.sql.gz
#|   |-- mydatabase_2012-02-20_02h10m.Monday.sql.gz
#|   |-- mydatabase_2012-02-21_02h10m.Tuesday.sql.gz
#|   |-- mydatabase_2012-02-22_02h10m.Wednesday.sql.gz
#|   |-- mydatabase_2012-02-23_02h10m.Thursday.sql.gz
#|   `-- mydatabase_2012-02-24_02h10m.Friday.sql.gz
#|-- testdb
#|   |-- testdb_2012-01-11_16h49m.onsdag.sql.gz
#|   |-- testdb_2012-02-19_02h10m.Sunday.sql.gz
#|   |-- testdb_2012-02-20_02h10m.Monday.sql.gz
#|   |-- testdb_2012-02-21_02h10m.Tuesday.sql.gz
#|   |-- testdb_2012-02-22_02h10m.Wednesday.sql.gz
#|   |-- testdb_2012-02-23_02h10m.Thursday.sql.gz
#|   `-- testdb_2012-02-24_02h10m.Friday.sql.gz
#`-- mysql
#    |-- mysql_2012-01-11_16h49m.onsdag.sql.gz
#    |-- mysql_2012-02-19_02h10m.Sunday.sql.gz
#    |-- mysql_2012-02-20_02h10m.Monday.sql.gz
#    |-- mysql_2012-02-21_02h10m.Tuesday.sql.gz
#    |-- mysql_2012-02-22_02h10m.Wednesday.sql.gz
#    |-- mysql_2012-02-23_02h10m.Thursday.sql.gz
#    `-- mysql_2012-02-24_02h10m.Friday.sql.gz
 
 
#and the latest backup in a directory
BACKUPDIRS2=`dir='/mnt/nas/BACKUP/somehost/something_backup/*'; ls --color=never -rt $dir | sed 's/  /\n/' | tail -1`
#tree example:
#/mnt/nas/BACKUP/somehost/something_backup/
#|-- backup_0.tar.gz
#|-- backup_1.tar.gz
#|-- backup_2.tar.gz
#|-- backup_3.tar.gz
#|-- backup_4.tar.gz
#|-- backup_5.tar.gz
#`-- backup_6.tar.gz
 
 
#all the dirs/files that will be backed up
BACKUPDIRS=${BACKUPDIRS1}" "${BACKUPDIRS2}" /mnt/nas/BACKUP/Evert/documents/ /mnt/nas/BACKUP/Evert/pictures/ /mnt/nas/BACKUP/Börje/ /mnt/nas/BACKUP/DomeDan/www"
 
#uncomment this to do a backup-test on a directory
#COUNTFILE="./backuptest.count"
#BACKUPDIRS="./backuptest/"
 
 
#this function checks if device is busy, loops and check again every 5 second
function check_dev {
  mt -f $DEVN status &>/dev/null
  #$? = 1 when busy
  #$? = 0 when ready
  until [ $? -eq 0 ]; do
    sleep 5
    check_dev
  done
}
 
#function to rewind tape
function rewind {
  echo "rewinding $DEV"
  mt -f $DEV rewind
  check_dev
}
 
#function to forward space count file
function fsf {
  echo "forward space count files to $COUNTER"
  mt -f $DEVN fsf $COUNTER
  if [ $? -ne 0 ]; then
    echo "fsf failed, cant forward to $COUNTER, does $(($COUNTER-1)) exist?"
    exit 1
  fi
  check_dev
}
 
#check if the script got any argument
if [ -z $1 ]; then
  echo "this script needs an argument, -t for test, -r for real"
  exit 1
fi
 
#mount everything in fstab if it aint automounted at boot
mount -a
 
#test-flag, just check the directorys to backup
if [ $1 == "-t" ]; then
 
  echo -e "Tesing, All files to be backuped and space required\n"
  ls -l $BACKUPDIRS
  echo ""
  du -hc $BACKUPDIRS | tail -1
 
#real-flag, doing a backup
elif [ $1 == "-r" ]; then
 
  if [ -e $COUNTFILE ]; then
    COUNTER=`cat $COUNTFILE`
  else
    echo "could not find $COUNTFILE create it and try again"
    exit 1
  fi
 
  echo "doing backup number $COUNTER"

  rewind
 
  if [ $COUNTER == 0 ]; then
    echo "first backup, wont forward space count files"
  else
    fsf
  fi
 
  # size of backup in kilobytes
  SIZE=`du -c $BACKUPDIRS | tail -1 | cut -f 1`
 
  echo "backing up $BACKUPDIRS"
  TIME1=`date +'%s.%N'` #start-time of backup
  tar czf $DEVN $BACKUPDIRS
  TIME2=`date +'%s.%N'` #end-time of backup
 
  TIME=`echo "scale=2; $TIME2-$TIME1" | bc`      #how long the backup took
  SIZE_MB=`echo "scale=2; $SIZE/1024" | bc`      #size in Mb
  SIZE_SEC=`echo "scale=2; $SIZE_MB/$TIME" | bc` #speed of backup in Mb/s
 
  echo "took $TIME seconds to write $SIZE_MB Mb, speed: $SIZE_SEC Mb/s"
 
  echo "writing End Of File at the end of backup"
  mt -f $DEV weof 1
  check_dev
 
  #verify backup
  echo "verify backup"
 
  rewind
  fsf
 
  echo "start comparing backup with tape"
  tar -dzf $DEVN $BACKUPDIRS &>/dev/null
  if [ $? -eq 1 ]; then
    echo "WARNING: backup does not match files on tape"
  else
    echo "backup OK"
  fi
 
  echo "backup $COUNTER finnish"
 
  echo "writing $((COUNTER+1)) to $COUNTFILE"
  echo $((COUNTER+1)) > $COUNTFILE
 
  rewind
 
  echo -e "eject tape? (y/n) \c "
  read answer
 
  if [ $answer == "y" ]; then
    echo "ejecting, wait..."
    mt -f $DEVN eject
  fi
 
else
  echo "unknown argument, -t for test, -r for real"
fi
