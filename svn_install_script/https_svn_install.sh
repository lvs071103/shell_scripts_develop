#!/bin/bash

#dep
yum install autoconf libtool gcc gcc-c++ lrzsz zlib zlib-devel libxml2 libxml2-devel expat expat-devel openssl openssl-devel pcre pcre-devel -y
if [ $? -eq 0 ];then
	echo "DEP install success."
else
	echo "DEP install failed."
	exit 1
fi

sleep 2

#apr
if [ ! -e ./apr-1.5.2.tar.gz ];then
	wget http://mirror.bit.edu.cn/apache//apr/apr-1.5.2.tar.gz
fi
if [ -d /data/lnmp/apr ];then
	echo "APR directory already exists."
	:
else
	tar zxvf apr-1.5.2.tar.gz
	cd apr-1.5.2
	sed -i 's/$RM "$cfgfile"/# $RM "$cfgfile"/' configure
	sed -i '/# $RM "$cfgfile"/ a\    $RM -f "$cfgfile"' configure
	./configure --prefix=/data/lnmp/apr
	if [ $? -eq 0 ];then
		make && make install
		echo "/data/lnmp/apr/lib/" > /etc/ld.so.conf.d/apr.conf
		ldconfig
		cd ..
	else
		exit 1
	fi
fi

#apr-util
if [ ! -e ./apr-util-1.5.4.tar.gz ];then
	wget http://apache.fayea.com//apr/apr-util-1.5.4.tar.gz
fi
if [ -d /data/lnmp/apr-util ];then
	echo "APR-UTIL directory already exists."
	:
else
	tar zxvf apr-util-1.5.4.tar.gz
	cd apr-util-1.5.4
	./configure --prefix=/data/lnmp/apr-util --with-apr=/data/lnmp/apr/
	if [ $? -eq 0 ];then
		make && make install
		echo "/data/lnmp/apr-util/lib" > /etc/ld.so.conf.d/apr-util.conf
		ldconfig
		cd ..
	else
		exit 1
	fi
fi

#httpd
if [ ! -e ./httpd-2.4.18.tar.gz ];then
	wget http://mirrors.hust.edu.cn/apache//httpd/httpd-2.4.18.tar.gz
fi
if [ -d /data/lnmp/apache24 ];then
	echo "Apache directory already exists."
	:
else
	tar zxvf httpd-2.4.18.tar.gz
	cd httpd-2.4.18
	./configure --prefix=/data/lnmp/apache24 --with-apr=/data/lnmp/apr/bin/apr-1-config \
		--with-apr-util=/data/lnmp/apr-util/bin/apu-1-config --enable-so --enable-dav \
		--enable-maintainer-mode --enable-rewrite --with-ssl=/usr
	if [ $? -eq 0 ];then
		make && make install
		cp -f ../httpd /etc/init.d/httpd
		chkconfig httpd on
		sed -i '$a\127.0.0.1 leshu-svn-backup' /etc/hosts
		sed -i '/#ServerName www.example.com:80/a\ServerName localhost:80' /data/lnmp/apache24/conf/httpd.conf
		/etc/init.d/httpd start
		cd ..
	else
		exit 1
	fi
fi

#scons
if [ ! -e ./scons-2.4.1.tar.gz ];then
	wget http://netix.dl.sourceforge.net/project/scons/scons/2.4.1/scons-2.4.1.tar.gz
fi
if [ ! -e /usr/bin/scons ];then
	tar zxvf scons-2.4.1.tar.gz
	cd scons-2.4.1
	python setup.py build
	python setup.py install
	cd ..
fi


#serf
if [ ! -e ./serf-1.3.8.tar.bz2 ];then
	wget https://archive.apache.org/dist/serf/serf-1.3.8.tar.bz2
fi
if [ -d /data/lnmp/serf ];then
	echo "Serf directory already exists."
	:
else
	tar xjf serf-1.3.8.tar.bz2
	cd serf-1.3.8
	scons PREFIX=/data/lnmp/serf APR=/data/lnmp/apr/bin/apr-1-config APU=/data/lnmp/apr-util/bin/apu-1-config
	scons install
	if [ $? -eq 0 ];then
		echo "/data/lnmp/serf/lib" > /etc/ld.so.conf.d/serf.conf
		echo "serf install success."
		cd ..
	else
		exit 1
	fi
fi

#sqlite
if [ ! -e ./sqlite-autoconf-3100000.tar.gz ];then
	wget http://www.sqlite.org/2016/sqlite-autoconf-3100000.tar.gz
fi
if [ ! -d /data/lnmp/sqlite ];then
	tar zxvf sqlite-autoconf-3100000.tar.gz
	cd sqlite-autoconf-3100000
	./configure --prefix=/data/lnmp/sqlite
	if [ $? -eq 0 ];then
		make && make install
		echo "/data/lnmp/sqlite/lib" > /etc/ld.so.conf.d/sqlite.conf
		ldconfig
		cd ..
	else
		exit 1
	fi
else
	echo "Sqlite directory already exsits."
fi

#svn
if [ ! -e ./subversion-1.9.3.tar.gz ];then
	wget http://mirror.bit.edu.cn/apache/subversion/subversion-1.9.3.tar.gz
fi
if [ ! -d /data/lnmp/subversion ];then
	tar zxvf subversion-1.9.3.tar.gz
	cd subversion-1.9.3
	mkdir sqlite-amalgamation
	cp ../sqlite-autoconf-3100000/sqlite3.c sqlite-amalgamation
	./configure --prefix=/data/lnmp/subversion --with-apxs=/data/lnmp/apache24/bin/apxs \
		--with-apr=/data/lnmp/apr/bin/apr-1-config --with-apr-util=/data/lnmp/apr-util/bin/apu-1-config \
		--with-zlib --enable-maintainer-mode --with-serf=/data/lnmp/serf --enable-mod-activation \
		--with-sqlite=/data/lnmp/sqlite
	if [ $? -eq 0 ];then
		make && make install
		echo 'export SVN_HOME=/data/lnmp/subversion' > /etc/profile.d/svn.sh
		echo 'export PATH=$SVN_HOME/bin:$PATH' >> /etc/profile.d/svn.sh
		source /etc/profile
		cd ..
	else
		exit 1
	fi
else
	echo "Subversion directory already exists."
fi

#configure httpd
echo "now start configure httpd conf"
cp /data/lnmp/apache24/conf/httpd.conf /data/lnmp/apache24/conf/httpd.conf.bak
sed -i '$ a\<Location /leshu-svn>\n\tDAV svn\n\tSSLRequireSSL\n\tSVNParentPath /data/svn.d/repos\n\tSVNListParentPath On\n\tAuthType Basic\n\tAuthName "svn repos"\n\tAuthUserFile /data/svn.d/passwd\n\tAuthzSVNAccessFile /data/svn.d/authz\n\tRequire valid-user\n</Location>' /data/lnmp/apache24/conf/httpd.conf
sed -i '/#Include conf\/extra\/httpd-ssl.conf/ a\Include conf\/extra\/httpd-ssl.conf' /data/lnmp/apache24/conf/httpd.conf
sed -i 's:SSLCertificateFile "/data/lnmp/apache24/conf/server.crt":SSLCertificateFile "/data/svn.d/server.crt":' /data/lnmp/apache24/conf/extra/httpd-ssl.conf
sed -i 's:SSLCertificateKeyFile "/data/lnmp/apache24/conf/server.key":SSLCertificateKeyFile "/data/svn.d/server.key":' /data/lnmp/apache24/conf/extra/httpd-ssl.conf
/etc/init.d/httpd restart
