#!/bin/bash

# magnetic-tape-backup v0.2
# Date: 2012-12-07
# Original author: DomeDan
# License: GPLv3
# http://www.gnu.org/licenses/gpl-3.0.txt

#This a script I wrote to backup files to magnetic tape from a network attached storage
#
# HOWTO first run:
# 1. create a file containing the backup number, "echo 0 > backup.count" (or any other name as long as you change the variable)
# 2. find what you want to backup, if its on a network-drive edit /etc/fstab so it will be mounted by this script if you set MOUNT_ALL="y"
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
 
################################# 
#####       VARIABLES       #####
################################# 
DEV="/dev/st0"    #set you device here
DEVN="/dev/nst0"  #set you device (no rewind) here
# write you type of Magnetic tape unit, this is only to count how long the backup process will take
MT_TYPE="DAT72"   #types: DDS1 DDS2 DDS3 DDS4 DAT72 DAT160 DAT320
EJECT_TAPE=""    #set "y" to eject by default, "n" to not eject and empty to ask
MOUNT_ALL="n"     #set "y" to make the script try to mount every mountpoint in fstab (this is usefull if your doing backups from a networkdrive and want to make sure it is mounted)
DATE_ARG="%Y-%m-%d %H:%M:%S" #change this to any format you like

#the variable that contains the backup number that is the next in line (e.g.: I have done 2 backups on this tape, then backup.count should contain number 3)
#if the file does not exist, create it, should contain 0 at first backup
COUNTFILE="./backup.count"
 
#all the dirs/files that will be backed up
BACKUPDIRS="$HOME" #to select more directorys/file just separate them with a space, example: "/home /var/www /etc"
################################# 
################################# 

 
 
 
################################# 
#####       FUNCTIONS       #####
################################# 
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
  echo "* Rewinding $DEV"
  mt -f $DEV rewind
  check_dev
}
 
#function to forward space count file
function fsf {
  echo "* Forward space count files to $COUNTER"
  mt -f $DEVN fsf $COUNTER
  if [ $? -ne 0 ]; then
    echo "ERROR: fsf failed, cant forward to $COUNTER, does $(($COUNTER-1)) exist?"
    exit 1
  fi
  check_dev
}
 
#function to ask and eject tape
function eject {
  while true; do
    if [ -n "$EJECT_TAPE" ] && [ "$EJECT_TAPE" == "y" ] || [ "$EJECT_TAPE" == "n" ]; then
      break
    fi
    echo -e "Eject tape? (y/n) \c "
    read EJECT_TAPE
  done

  if [ $EJECT_TAPE == "y" ]; then
    echo "* Ejecting, wait..."
    mt -f $DEVN eject
  fi
}

#funktion to print help
function print_help {
  echo -e "Edit the variables in this script, like what directories/files to backup"
  echo -e "Usage: $0 -t"
  echo -e " -t\tTest-mode, just prints the directory, size and calculate esimated time for the backup"
  echo -e " -r\tReal-mode, Write the data to the tape"
  echo -e " -h\tPrints this help"
}

# function to calculate backup size and how long the backup teoreticly will take and when it will be finnished
function calculate_backup {
  echo "* Calculating size of all data to backup"

  SIZE=`du -c $BACKUPDIRS | tail -1 | cut -f 1`               #total size
  SIZE_MB=`echo "scale=2; $SIZE/1024" | bc`                   #convert to Mb
  TOT_TIME_SEC=`echo "scale=2; ($SIZE_MB/$TEO_SPEED)*2" | bc` #time in seconds for a backup + verification
  TOT_TIME_MIN=`echo "scale=2; $TOT_TIME_SEC/60" | bc`        #convert to minutes
  NOW=`date +"%H:%M:%S"`
  FINNISH_TIME=`date -d "1970-01-01 $NOW $TOT_TIME_SEC seconds" +"%H:%M:%S"` #calculate when backup + verification might be finnish

  # Variable to print when doing a test and before doing a real backup
  INFO="\nSize of backup: $SIZE_MB Mb with a teoretical speed of $TEO_SPEED Mb/s \nthe backup plus backup verification will take $TOT_TIME_MIN min \n\nCalculated teoretical finnish-time: $FINNISH_TIME"
}

#function to print message to user with date in front
function echo_with_date {
  DATE=`date +"$DATE_ARG"`
  echo "$DATE: $1"
}
################################# 
################################# 




#check argumets to the script
while getopts "trh" opt; do
  case $opt in
  t)
    TESTMODE="y"
    ;;
  r)
    REALMODE="y"
    ;;
  h)
    print_help
    exit 0
    ;;
  \?)
    echo "invalid option: $1"
    echo ""
    print_help
    exit 1
    ;;
  esac
done



#determine what speed in Mb/s your tape drive should theoretically read/write at
case $MT_TYPE in
  "DDS1") TEO_SPEED="0.18";;
  "DDS2") TEO_SPEED="0.6";;
  "DDS3") TEO_SPEED="1.1";;
  "DDS4") TEO_SPEED="3.2";;
  "DAT72") TEO_SPEED="3.2";;
  "DAT160") TEO_SPEED="6.9";;
  "DAT320") TEO_SPEED="12"
esac


#check if the script got any argument
if [ -z $1 ]; then
  echo "ERROR: This script needs an argument!"
  echo ""
  print_help
  exit 1
fi
 
#mount everything in fstab if it aint automounted at boot
if [ "$MOUNT_ALL" == "y" ]; then
  echo "* Trying mount -a"
  mount -a
fi
 
# calculate backup, this created the variable $INFO
calculate_backup

#test-flag, just check the directorys to backup
if [ "$TESTMODE" == "y" ]; then
 
  echo "## Test-mode ##"
  ls -l $BACKUPDIRS
  echo -e $INFO

#real-flag, doing a backup
elif [ $REALMODE == "y" ]; then
 
  echo "## Real-mode ##"

  if [ -e $COUNTFILE ]; then
    COUNTER=`cat $COUNTFILE`
  else
    echo "ERROR: Could not find $COUNTFILE create it or change the varriable COUNTFILE and try again"
    exit 1
  fi
 
  echo "* Doing backup number $COUNTER"

  rewind
 
  if [ $COUNTER == 0 ]; then
    echo "* First backup, wont forward space count files"
  else
    fsf
  fi
 
  # print info about the backup and how long it might take
  echo -e $INFO
  echo ""

  echo_with_date "Backing up $BACKUPDIRS"
  echo "* Writing data to tape"

  TIME1=`date +'%s.%N'` #start-time of backup
  tar czf $DEVN $BACKUPDIRS &>/dev/null
  if [ $? -eq 1 ]; then
    echo "ERROR: Writing data to the tape failed"
    echo "       try to manually run the backup-commando if you want to find out whats happening:"
    echo "tar czf $DEVN $BACKUPDIRS"
    exit 1
  fi
  TIME2=`date +'%s.%N'` #time when only writing is done
  mt -f $DEV weof 1 #writing End Of File at the end of backup
  check_dev
  TIME3=`date +'%s.%N'` #end-time of backup
 
  TIME_SEC=`echo "scale=2; $TIME3-$TIME1" | bc`      #how long the backup took
  TIME_MIN=`echo "scale=2; $TIME_SEC/60" | bc`       #how long the backup took in minutes
  SIZE_SEC=`echo "scale=2; $SIZE_MB/$TIME_SEC" | bc` #calculate speed of backup in Mb/s
  WRITE_TIME_SEC=`echo "scale=2; $TIME2-$TIME1" | bc`            #how long the writing took
  WRITE_SIZE_SEC=`echo "scale=2; $SIZE_MB/$WRITE_TIME_SEC" | bc` #calculate actuall write speed of backup in Mb/s
 
  echo_with_date "Backup took $TIME_MIN min, size: $SIZE_MB Mb, speed: $SIZE_SEC Mb/s (acctual write speed was $WRITE_SIZE_SEC Mb/s)"

  NOW=`date +"%H:%M:%S"`
  FINNISH_TIME=`date -d "1970-01-01 $NOW $TIME_SEC seconds" +"%H:%M:%S"`
  echo ""
  echo "New calculated finnish-time based on the acctual write time: $FINNISH_TIME"
  echo ""
 
  #verify backup
  rewind
  fsf
 
  echo_with_date "Start comparing backup with tape using \"tar -d\""
  echo "* Verifying backup"
  tar -dzf $DEVN $BACKUPDIRS &>/dev/null
  if [ $? -eq 1 ]; then
    echo "ERROR: Backup does not match files on tape"
    echo "       maybe you reached the end of the tape or just got a bad tape"
    echo "       check the tape and re-run the script or change tape and write 0 to $COUNTFILE to start all over"
    exit 1
  else
    echo "* Backup OK"
  fi
 
  echo_with_date "Backup $COUNTER finnish"
 
  echo "* Writing $((COUNTER+1)) to $COUNTFILE"
  echo $((COUNTER+1)) > $COUNTFILE
 
  rewind
 
  eject
 
else
  echo "ERROR: unknown argument"
  echo ""
  print_help
  exit 1
fi

exit 0
