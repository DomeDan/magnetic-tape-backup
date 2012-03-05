magnetic-tape-backup
==========
This a script I wrote to backup files to magnetic tape (DAT) from a network attached storage

 HOWTO first run:
====================
  * create a file containing the backup number, "echo 0 > backup.count" (or any other name as long as you change the variable)
  * find what you want to backup, if its on a network-drive edit /etc/fstab so it will be mounted by this script
    edit the variables $BACKUPDIRSX to point at the directories you want to backup
  * do a test-run with the -t flag
  * do a real-run with the -r flag

 HOWTO restore backup from tape:
====================
  * If backup.count contains number 15 and you want the latest backup then do:
  * mt -f /dev/nst0 fsf 14
  * tar xzvf /dev/nst0
  * The tar command will extract all the files in backup number 14 to the current directory

* A forum-post I got inspiration from: http://www.unix.com/unix-dummies-questions-answers/9595-multiple-backups-one-tape.html
* Good info about bash-scripting: http://linuxconfig.org/Bash_scripting_Tutorial