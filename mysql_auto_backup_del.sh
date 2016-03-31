#!/bin/bash

TIME=$(date +%Y%m%d_%H%M%S)
USER='root'
PASS='123456'
DBS=(9k9kcom kaifudata kaifumttt leshucomcn ls ls_mixedservice ls_union)
BACKUP_DIR=/data/backup/mysql
TTL=10

BACKUP(){
	mkdir -p $BACKUP_DIR/127.0.0.1_$TIME

	/data/lnmp/mysql/bin/mysql -u$USER -p$PASS -e"set global read_only=on" 2>/dev/null
	if [ "$?" -eq 0 ];then
		echo "$(date +%Y-%m-%d' '%H:%M:%S) lock mysql success."
	else
		echo "$(date +%Y-%m-%d' '%H:%M:%S) lock mysql failed."
		exit 1
	fi

	for i in ${DBS[*]}
	do
        	/data/lnmp/mysql/bin/mysqldump -u$USER -p$PASS $i > $BACKUP_DIR/127.0.0.1_$TIME/$i.sql 2>/dev/null
        	if [ "$?" -eq 0 ];then
           		echo "$(date +%Y-%m-%d' '%H:%M:%S) $i dump success."
        	else
            		echo "$(date +%Y-%m-%d' '%H:%M:%S) $i dump failed."
            		exit 1
		fi
    	done
	
	/data/lnmp/mysql/bin/mysql -u$USER -p$PASS -e"set global read_only=off" 2>/dev/null
	if [ "$?" -eq 0 ];then
		echo "$(date +%Y-%m-%d' '%H:%M:%S) unlock mysql success."
	else
		echo "$(date +%Y-%m-%d' '%H:%M:%S) unlock mysql failed."
		exit 1
	fi

	cd $BACKUP_DIR
	tar zcf 127.0.0.1_$TIME.tar.gz 127.0.0.1_$TIME
	if [ "$?" -eq 0 ];then
		echo "$(date +%Y-%m-%d' '%H:%M:%S) compress success."
		rm -rf $BACKUP_DIR/127.0.0.1_$TIME
	fi

        /usr/bin/scp 127.0.0.1_$TIME.tar.gz root@10.16.1.72:/data/backup/mysql/LESHU_MDB_NO_12_75/
	if [ $? -eq 0 ];then
		echo "$(date +%Y-%m-%d' '%H:%M:%S) copy to remote server success."
		#rm -rf 127.0.0.1_$TIME.tar.gz
	else
		echo "$(date +%Y-%m-%d' '%H:%M:%S) copy to remote server failed."
		exit 1
	fi
}

DELETE(){
	find $BACKUP_DIR -type f -name "*.tar.gz" -ctime +$TTL -exec rm -rf {} \;
	if [ "$?" -eq 0 ];then
		echo "$(date +%Y-%m-%d' '%H:%M:%S) clear ten days ago backup success."
	else
		echo "$(date +%Y-%m-%d' '%H:%M:%S) clear backup failed."
		exit 1
	fi
}


if [ ! -d $BACKUP_DIR ]; then
    mkdir -p $BACKUP_DIR
fi

BACKUP
DELETE
