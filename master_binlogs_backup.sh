#!/bin/bash

MYSQLLOG_BIN="/data/lnmp/mysql/bin/mysqlbinlog"
MYSQL_BIN="/data/lnmp/mysql/bin/mysql"
MASTER_HOST="10.16.1.75"
MYSQL_PORT=3306
MYSQL_USER="root"
MYSQL_PASS="123456"
BACKUP_DIR="/data/backup/binlogs/LESHU_MDB_NO_12_75/"
# time to wait before reconnecting after failure
RESPAWN=10

if [ ! -d "$BACKUP_DIR" ];then
	mkdir -p ${BACKUP_DIR}
fi

cd ${BACKUP_DIR}
echo "Backup dir: $BACKUP_DIR "

while :
do
	LAST_FILE=`ls -1 $BACKUP_DIR | grep -v orig | tail -n 1`
	if [ -z "$LAST_FILE" ];then
		LAST_FILE=`${MYSQL_BIN} -h${MASTER_HOST} -u${MYSQL_USER} -p${MYSQL_PASS} -e "SHOW BINARY LOGS;" 2>/dev/null|awk '/mysql-bin/ {print $1}'|head -n 1`
		${MYSQLLOG_BIN} --read-from-remote-server --host=${MASTER_HOST} --user=${MYSQL_USER} --password=${MYSQL_PASS} --raw --stop-never ${LAST_FILE}
	else
		TIMESTAMP=`date +%s`
		FILE_SIZE=$(stat -c%s "$LAST_FILE")

		if [ "$FILE_SIZE" -gt 0 ]; then
			echo "Backing up last binlog"
			mv $LAST_FILE ${LAST_FILE}_orig_${TIMESTAMP}
		fi

		touch $LAST_FILE
		echo "Starting live binlog backup"
		${MYSQLLOG_BIN} --read-from-remote-server --host=${MASTER_HOST} --user=${MYSQL_USER} --password=${MYSQL_PASS} --raw --stop-never ${LAST_FILE} 2>/dev/null
		echo "mysqlbinlog exited with $? trying to reconnect in $RESPAWN seconds."
		sleep $RESPAWN
	fi
done
