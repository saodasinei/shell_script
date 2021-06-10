#!/bin/bash

############################################## 【绿色安装】 #####################################################

#环境变量文件的地址
ENV_DIR='/etc/profile.d/myenv.sh'
#绿色安装的根目录
SOFTWARE_DIR='/opt/software/'
#安装源文件目录
DOWNLOAD_DIR='/opt/download/'



#根据据参数1提供的识别符和参数2提供的行数[删除相关的配置信息]
function removeEnvVarIfExists(){
	if [ $# -lt 2 ]
	then
		echo 'no sign when remove env variables'
		exit -1
	fi
	sed -rin "/^#.*?$1/,+$2d" $ENV_DIR
	echo "env variables [ $1 ] removed"
}


#根据参数1提供的目录前缀[删除历史已解压目录]
function removeSrcIfExists(){
	if [ $# -lt 1 ]
    then
        echo 'no sign when remove env src'
        exit -1
    fi

	RST=`ls $SOFTWARE_DIR|grep $1`
	if [[ $RST ]]
	then
    		rm -rf $SOFTWARE_DIR$RST
    		echo $SOFTWARE_DIR$1' removed'
	else
    		echo "no [ $1 ] dir"
	fi
}


#根据参数1提供的原文件的前缀名将相关资源[解压缩]文件到目标路径
function tarxTo(){
	if [ $# -lt 1 ]
    then
        echo "no sign when tar -zxf $1"
        exit -1
    fi

	RST=(`ls $DOWNLOAD_DIR|grep $1`)
	if [ ${#RST[@]} -gt 0 ]
	then
    		RST=${RST[0]}
    		tar -zxf $DOWNLOAD_DIR$RST -C $SOFTWARE_DIR
    		eval mv $SOFTWARE_DIR$1'*' $SOFTWARE_DIR$1
    		echo "$1 decompressed"
	else
    		echo "no $1 source in "$DOWNLOAD_DIR
	fi
}


#将参数1环境变量列表加入myenv.sh
function addEnvVar(){
	echo '========== add env variables ========='
	DIR="$1"
	DIR=${DIR//;/ }
	for item in $DIR
	do
		sed -in '$i'$item $ENV_DIR
		echo $item' appended'
	done
	sed -in '${x;p;x}' $ENV_DIR
	echo '======================================='
	sed -in 's/-/ /g' $ENV_DIR
	#每次添加完新环境变量后再次激活
	source /etc/profile
}

############################################ 检查 myenv.sh 文件 ############################################
#检查myenv.sh是否存在，不存在则创建
ENV_DIR="/etc/profile.d/"
RST=`ls $ENV_DIR|grep myenv.sh`
if [[ -z $RST ]]
then
    ENV_DIR=$ENV_DIR'myenv.sh'
    eval touch $ENV_DIR
    #新建的空文件无法通过sed修改内容,因此创建文件后使用流的重定向先行添加一行
    echo '#[end]'>$ENV_DIR
    echo $ENV_DIR' created'
else
    ENV_DIR=$ENV_DIR'myenv.sh'
    echo $ENV_DIR' existed'
fi

############################################### JDK 安装 #####################################################
JAVA_ENV="#jdk;export-JAVA_HOME=$SOFTWARE_DIR"'jdk;export-PATH=$JAVA_HOME/bin:$PATH;export-CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar'

removeEnvVarIfExists jdk 4
removeSrcIfExists jdk
tarxTo jdk
addEnvVar $JAVA_ENV

############################################# hadoop 安装 ####################################################
HADOOP_ENV='#hadoop;export-HADOOP_HOME=/opt/software/hadoop;export-PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH;export-HDFS_NAMENODE_USER=root;export-HDFS_DATANODE_USER=root;export-HDFS_SECONDARYNAMENODE_USER=root;export-YARN_RESOURCEMANAGER_USER=root;export-YARN_NODEMANAGER_USER=root'

removeEnvVarIfExists hadoop 8
removeSrcIfExists hadoop
tarxTo hadoop
addEnvVar $HADOOP_ENV




############################################## 【rpm 安装】 ###################################################

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
			echo $i"...removed"
		done	
		rm -f $2'.*'
		echo "$1 left resource $2 has been removed"
		echo "======================================================================================="
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
		echo "there may be chinese random code for lack of $DIR"
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

#截取url中资源文件名称,功能等同于basename
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






