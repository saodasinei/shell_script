#!/bin/bash
source /etc/profile

#一键关闭服务
CNF_FILE='stop.cnf'

#验证配置文件是否存在
if [ ! -e $CNF_FILE -o -d $CNF_FILE  ]
then
	echo "$CNF_FILE not exits"
	exit 0
fi
		

#读取配置文件
CNF_LINES=(`cat $CNF_FILE`)
COUNT=0
for item in ${CNF_LINES[@]}
do
	((COUNT++))
	item=(${item//->/ })
	echo "$COUNT、${item[0]}"
done

read -p 'please select service to stop: ' choice

#验证用户输入合法性
if [[ $choice =~ ^[0-9]+$ ]]
then
    if [ $choice -gt $COUNT -o $choice -lt 1 ]
    then
        echo "choice must be between 1 and $COUNT, script will exit"
        exit 0
    fi
else
    echo 'choice  must be a num, script will exit'
    exit 0
fi

#自定义函数调用服务自带脚本关闭服务
function stopSers(){
	LINE=$1
	LINE=(${LINE//@/ })
	SERS=${LINE[0]}
	SERS=${SERS//,/ }
	COUNT=0
	for item in $SERS
	do
		RST=`jps -ml|grep -w $item`
		if [[ $RST ]]
		then
			COUNT=1
			break
		fi
	done
	if [ $COUNT -eq 1 ]
	then
		RST=`${LINE[1]}`
		echo "STOPPED"
	else
		echo 'NONE'
	fi
}

#自定义函数通过系统桶用函数Kill关闭服务
function killSers(){
	LINE=$1
	LINE=${LINE//,/ }
	COUNT=0
	for item in $LINE
	do
		PID=`jps -ml | grep -w $item | awk {'print $1'}`
		if [[ $PID ]]
		then
			((COUNT++))
			kill -9 $PID
		fi
	done
	if [ $COUNT -gt 0 ]
    then
        echo "STOPPED"
    else
        echo 'NONE'
    fi
}

#自定义函数根据参数类型和操作字符串关闭服务
function stopByLine(){
	SIGN=$1
	TYPE=$2
	LINE=$3
	case $TYPE in
	"STOP")
		LINE=${LINE//;/ }
		for item in $LINE
		do
			RST=`stopSers $item`
			item=(${item//@/ })
			item=${item[0]}		
			case $RST in
			"STOPPED")
				echo 'services [ '$item' ]' stopeed 
			;;
			"NONE")
				echo 'no services [ ' $item' ] exists'
			;;
			esac
		done
	;;
	"KILL")
		RST=`killSers $LINE`
		case $RST in
        "STOPPED")
            echo 'services [ '$LINE' ]' stopeed 
        ;;
        "NONE")
            echo 'no services [ ' $LINE' ] exists'
        ;;
        esac
	;;
	esac
		
}


#根据用户的选择向后关闭服务
COUNT=0
while (( $COUNT<$choice ))
do
	LINE=${CNF_LINES[$COUNT]}
	LINE=(${LINE//->/ })
	SIGN=${LINE[0]}
	TYPE=${LINE[1]}
	LINE=${LINE[2]}
	RST=`stopByLine $SIGN $TYPE $LINE`
	echo $RST
	((COUNT++))
done





