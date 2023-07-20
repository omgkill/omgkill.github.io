#!/bin/bash

#-s 11 -n game -p 10000 -b 6144

SERVER_ID=9000
INNODB_BUFFER_POOL_SIZE=512
PORT=0
CONTAINER_NAME=""
START_GAME=true
START_MYSQL=true
START_REDIS=true


while getopts ":s:b:p:n:g:m:r:" opt
do
    case $opt in
        p)
        PORT=$OPTARG
        ;;
        b)
        INNODB_BUFFER_POOL_SIZE=$OPTARG
        ;;
        s)
        SERVER_ID=$OPTARG
        ;;
        n)
        CONTAINER_NAME=$OPTARG
        ;;
#        g)
#        START_GAME=true
#        ;;
#        m)
#        START_MYSQL=true
#        ;;
#        r)
#        START_REDIS=true
#        ;;
        ?)
        echo "示例：./deploy_docker_game.sh -s 11 -p 10000 -n qiqi -b 512"
        echo "参数* p: 端口"
        echo "参数* n: 容器名，可以输入你的名字拼音"
        echo "参数 b: mysql 缓存大小,单位是m。默认 512M"
        echo "参数 s: 服id，如果不指定，默认9000服"
#        echo "参数 g: 开启game服务，默认不开启"
#        echo "参数 m: 开启mysql服务，默认不开启"
#        echo "参数 r: 开启cluster 服务，默认不开启"
        exit 1;;
    esac
done


if [ "${PORT}" -le 0 ];then
  echo "error, need port"
  exit 1
elif [ "${CONTAINER_NAME}" == '' ]; then
  echo "error, need container name;you can input your name"
  exit 1
elif [ "${SERVER_ID}" -le 0 ]; then
  echo "error, need server id"
  exit 1
fi



docker run -d --rm \
--name "$CONTAINER_NAME" \
--env SERVER_ID="$SERVER_ID" \
--env INNODB_BUFFER_POOL_SIZE="$INNODB_BUFFER_POOL_SIZE" \
--env DOCKER_NAME="$CONTAINER_NAME" \
--env START_GAME="$START_GAME" \
--env START_MYSQL="$START_MYSQL" \
--env START_REDIS="$START_REDIS" \
-p "$PORT":80 \
-v "$CONTAINER_NAME"_mysql:/home/elex/mysql/data \
-v "$CONTAINER_NAME"_redis:/home/elex/redis \
10.0.3.2:5001/ams2-ds


docker logs -f "$CONTAINER_NAME"