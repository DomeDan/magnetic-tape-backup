#magnetic-tape-backup
This a script I wrote to backup files to magnetic tape from a network attached storage

# HOWTO first run:
  * create a file containing the backup number, "echo 0 > backup.count" (or any other name as long as you change the variable)
  * find what you want to backup, if its on a network-drive edit /etc/fstab so it will be mounted by this script if you set MOUNT_ALL="y"
    edit the variables $BACKUPDIRS to point at the directories you want to backup
  * do a test-run with the -t flag
  * do a real-run with the -r flag

# HOWTO restore backup from tape:
  * If backup.count contains number 15 and you want the latest backup then do:
  * mt -f /dev/nst0 fsf 14
  * tar xzvf /dev/nst0
  * The tar command will extract all the files in backup number 14 to the current directory

# Example

	root@host:~# ./magnetic-tape-backup-bba.sh -r
	* Calculating size of all data to backup
	## Real-mode ##
	* Doing backup number 5
	* Rewinding /dev/st0
	* Forward space count files to 5
	
	Size of backup: 403.39 Mb with a teoretical speed of 3.2 Mb/s 
	the backup plus backup verification will take 4.20 min 
	
	Calculated teoretical finnish-time: 15:23:08
	
	2012-12-07 15:19:23: Backing up /root
	* Writing data to tape
	2012-12-07 15:22:37: Backup took 3.23 min, size: 403.39 Mb, speed: 2.07 Mb/s (acctual write speed was 2.38 Mb/s)
	
	New calculated finnish-time based on the acctual write time: 15:25:51
	
	* Rewinding /dev/st0
	* Forward space count files to 5
	2012-12-07 15:23:01: Start comparing backup with tape using "tar -d"
	* Verifying backup
	* Backup OK
	2012-12-07 15:25:38: Backup 5 finnish
	* Writing 6 to ./backuptest.count
	* Rewinding /dev/st0
	Eject tape? (y/n) y
	* Ejecting, wait...


# links
  * A forum-post I got inspiration from: http://www.unix.com/unix-dummies-questions-answers/9595-multiple-backups-one-tape.html
  * more inspiration http://www.cyberciti.biz/faq/linux-tape-backup-with-mt-and-tar-command-howto/
  * Good info about bash-scripting: http://linuxconfig.org/Bash_scripting_Tutorial
