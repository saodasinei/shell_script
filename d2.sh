#!/bin/bash

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


################## hadoop 配置文件

cp /root/script/conf/* /opt/software/hadoop/etc/hadoop
cd /opt/software/hadoop
mkdir data
./bin/hdfs namenode -format




################################################ Hive 安装 ########################################
HIVE_ENV='#hive;export-HIVE_HOME=/opt/software/hive312;export-PATH=$HIVE_HOME/bin:$PATH'
removeSrcIfExists hive
tarxTo hive
addEnvVar $HIVE_ENV


################# hive 配置
cd /opt/software/hive/conf
mv hive-default.xml.template hive-default.xml
cp /root/script/conf/hive-site.xml ./

cd /opt/software/hive/lib
RST=ls|grep '^guava.*.jar'
rm -f $RST
cp /opt/software/hadoop/share/hadoop/common/lib/guava-27.0-jre.jar /opt/software/hive/lib








