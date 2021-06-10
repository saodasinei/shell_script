#!/bin/bash

#拷贝脚本文件到TencentCloud
#scp ./* root@119.29.67.161:/root/script

rsync -r /root/script root@119.29.67.161:/root
