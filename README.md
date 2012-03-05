magnetic-tape-backup
==========
This a script I wrote to backup files to magnetic tape (DAT) from a network attached storage

 HOWTO first run:
====================
  1. create a file containing the backup number, "echo 0 > backup.count" (or any other name as long as you change the variable)
  2. find what you want to backup, if its on a network-drive edit /etc/fstab so it will be mounted by this script
     edit the variables $BACKUPDIRSX to point at the directories you want to backup
  3. do a test-run with the -t flag
  4. do a real-run with the -r flag

 HOWTO restore backup from tape:
====================
  1. If backup.count contains number 15 and you want the latest backup then do:
  2. mt -f /dev/nst0 fsf 14
  3. tar xzvf /dev/nst0
  The tar command will extract all the files in backup number 14 to the current directory

A forum-post I got inspiration from: http://www.unix.com/unix-dummies-questions-answers/9595-multiple-backups-one-tape.html
Good info about bash-scripting: http://linuxconfig.org/Bash_scripting_Tutorial