#!/bin/bash

cd ~
ARSL=`pwd`
ARSL="$ARSL/.ALLOW_RM_SRC_LOG"
cd -
function checkAndRecord(){
	if [ ! -e $ARSL ]
	then
		eval touch $ARSL
	fi
	RST=`eval cat $ARSL|grep $1`
	if [[ -z  $RST ]]
	then
		echo $1>>$ARSL
	fi
}

function stopService(){
	RST=`systemctl status $1|grep ' active (.*)'`

	if [ -n "$RST" ]
	then
    	echo -n "service $1 is active running ... "
    	systemctl stop $1
    	RST=`systemctl status $1|grep ' active (.*)'`
    	if [[ $RST ]]
    	then
        	echo 'but fail to close'
        	exit -1
    	else
        	echo 'and succeed in closing'
    	fi
	else
    	echo "service $1 is inactive dead"
	fi
}

function removeRpm(){
	RST=`cat $ARSL|grep $1`
	if [[ $RST ]]
	then
		RST=`rpm -qa|grep $1`
		echo "====================================== yum remove $1 =================================="
		for i in $RST
		do
    		yum -y remove $i>/dev/null 2>&1
    		echo $i"... removed"
		done
		echo "======================================================================================="
		RST=`find / -name $1`	
		echo "================================== clear $1 left resource ============================="
		for i in $RST
		do
			rm -rf $i
		done	
		echo "======================================================================================="
		rm -f $2'.*'
		echo "$1 left resource $2 has been removed"
	else
		echo "WARN:you are trying to remove $1 which is not allowed"
	fi
}

#rpm安装：兼容远程安装和本地安装(提供rpm的完整路径)
function installRpm(){
	RST=$1
	ISERNAME=$2
	SSERNAME=$3
	if [[ $RST=~^http ]];then
		echo "rpm install $RST ..."
		wget $RST
		RST=`basename $RST`
	fi
	rpm -ivh $RST
	yum -y install $ISERNAME
	DIR="$4.cnf"
	if [ -e $DIR ]
	then
		cat $DIR>$5
		echo "$4 configuation has been overwritten"
	else
		echo "there may be chinese random code fro mlack of $DIR"
	fi	
	systemctl start $SSERNAME
	checkAndRecord $4
	deleteRpmSrc .rpm
	echo "$ISERNAME installed"
}

function deleteRpmSrc(){
	RST=`ls | grep $1`
	rm -f $RST
}

#截取url中资源文件名称,实现basename
function getFileName(){
	RST=$1
	if [[ $RST=~^http  ]];then
		echo "rpm install $RST ... "
		RST=${RST//\// }
		RST=($RST)
		i=${#RST[@]}
		rst=${RST[$i-1]}
		echo $rst
	fi
}


############################################### mysql 安装 ####################################################
stopService mysqld
removeRpm mysql /etc/my.cnf
SRC=https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm 
installRpm $SRC mysql-server mysqld mysql /etc/my.cnf


















