#!/bin/bash

#一键启动配置文件
CNF_FILE='start.cnf'

#验证配置文件(必须存在且为文件)
if [ ! -e $CNF_FILE -o -d $CNF_FILE ]
then
	echo $CNF_FILE" unavailable or is directiory, script will exit"
	exit 0
fi

#检查配置文件内容，并在命令行输出
CNF_LINES=(`cat start.cnf`)
count=0
for item in ${CNF_LINES[@]}
do
	((count++))
	arr=(${item/->/ })
	echo $count"、"${arr[0]}
done
#用户输入要启动的服务，启动编号之前所有服务
read -p 'please select the serveices to start: ' choice
#验证用户输入合法性
if [[ $choice =~ ^[0-9]+$ ]]
then
	if [ $choice -gt $count -o $choice -lt 1 ]
    then
		echo "choice must be between 1 and $count, script will exit"
		exit 0
	fi
else
	echo 'choice  must be a num, script will exit'
    exit 0
fi

#方法：检查要启动服务是否已完全启动，如果没有完全启动，结束残余的进程
function killOnLeft(){
	SIGN=$1
	SERS=$2
	SERS=(${SERS//_/ })
	PIDS=()
	count=0
	for item in ${SERS[@]}
	do
		RST=`jps -ml|grep -w $item`
		if [[ $RST ]]
		then
			RST=($RST)
			PIDS[$count]=${RST[0]}
			((count++))
		fi
	done
	if [ $count -lt ${#SERS[@]} ]
	then
		if [ $count -gt 0 ]
		then
			for pid in ${PIDS[@]}
			do
				RST=`kill -9 $pid`
			done
			echo "$SIGN has service left and killed"
		else
			echo "$SIGN has no service left"
		fi
		echo 'no'
	else
		echo "$SIGN is running"
		echo 'ok'
	fi
}

#自定义函数调用参数命令集启动相应服务
function startSers(){
	SIGN=$1
	SERS=$2
	SERS=${SERS//_/ }
	for cmd in $SERS
	do
		RST=`eval ${cmd//#/ }`
	done
	echo $SIGN' has been started'
}


#读取根据选择要启动的服务，读取配置文件中相应的服务信息和启动命令
count=0
while (( $count<$choice ))
do
	LINE=${CNF_LINES[$count]}
	LINE=(${LINE//->/ })
	SIGN=${LINE[0]}
	LINE=${LINE[1]}
	LINE=(${LINE//;/ })
	SERS=${LINE[0]}
	CMDS=${LINE[1]}
	RST=`killOnLeft $SIGN $SERS`
	echo $RST
	if [[ $RST =~ no$ ]]
	then
		RST=`startSers $SIGN $CMDS`
		echo $RST
	fi
	((count++))
done





