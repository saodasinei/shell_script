#!/bin/bash


#删除node
RST=`node -v`
if [[ $RST ]]
then
	npm uninstall pm2 -g
	npm uninstall npm -g
	yum remove nodejs npm -y
	#删除剩余文件
	rm -rf /opt/software/node
	rm -rf /usr/local/lib/node*
	rm -rf /usr/local/include/node*
	rm -rf /usr/local/bin/node
	rm -rf /usr/local/bin/np*
	rm -rf /usr/local/bin/pm*
	rm -r /root/.pm2
	echo 'node/npm has been removed'
else
	echo ‘node env not exists’
fi

#安装node
function installNode(){
wget https://nodejs.org/dist/$1/$2.tar.xz

xz -d $2.tar.xz
tar -xvf $2.tar -C /opt/software
mv /opt/software/$2 /opt/software/node
rm -f ./*.tar

#创建软连接
ln -s /opt/software/node/bin/node /usr/local/bin/node
ln -s /opt/software/node/bin/npm /usr/local/bin/npm

}


installNode v14.16.1 node-v14.16.1-linux-x64




#检查安装并设定淘宝源
RST=`node -v`
if [[ $RST ]]
then
	echo 'node installed'
	npm config set registry https://registry.npm.taobao.org
	echo 'table repository seted'
	npm install pm2 -g
	echo 'pm2 installed'
else
	echo 'failed to install node'
fi





