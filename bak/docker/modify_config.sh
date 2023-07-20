#!/bin/bash

SERVER_PATH=servers.xml
CONFIG_PATH=config.properties
AIM_SERVER_CONFIG_PATH=

if [ $SERVER_ID -ne "9000" ] ; then
  dbConfig=$(cat $SERVER_PATH | egrep -o "<ItemSpec id=\"$SERVER_ID.+" \
      | sed -e 's/ ip="[0-9.]\+"/ ip="127.0.0.1"/' \
      | sed -e 's/ pub_ip="[0-9.]\+"/ pub_ip="127.0.0.1"/' \
      | sed -e 's/ inner_ip="[0-9.]\+"/ inner_ip="127.0.0.1"/' \
      | sed -e 's/ db_ip="[0-9.]\+"/ db_ip="127.0.0.1"/' \
      | sed -e 's/db_name="[a-z0-9_-]\+"/db_name="hgdb"/');


  sed -i "s?<ItemSpec id=\"$SERVER_ID.\+?$dbConfig?" $SERVER_PATH


  sed -i  -e 's|realtime_local.jdbc.url=.\+|realtime_local.jdbc.url=jdbc:mysql://127.0.0.1:3306/hgdb?characterEncoding=utf-8|' \
       -e   's|global_db_url=.\+|global_db_url=jdbc:mysql://127.0.0.1:3306/td_global?characterEncoding=utf-8\&autoReconnect=true|' \
       -e  's|redis.cluster.ip.\+|redis.cluster.ip=127.0.0.1|g' \
       -e  's|redis.cluster.port1=.\+|redis.cluster.port1=6385|' \
        $CONFIG_PATH

    sed -i  -e 's|realtime_local.jdbc.url=.\+|realtime_local.jdbc.url=jdbc:mysql://127.0.0.1:3306/hgdb?characterEncoding=utf-8|' \
         -e   's|global_db_url=.\+|global_db_url=jdbc:mysql://127.0.0.1:3306/td_global?characterEncoding=utf-8\&autoReconnect=true|' \
         -e  's|redis.cluster.ip.\+|redis.cluster.ip=127.0.0.1|g' \
         -e  's|redis.cluster.port1=.\+|redis.cluster.port1=6385|' \
          $CONFIG_PATH

fi



#!/bin/sh
#数据库信息
HOSTNAME="127.0.0.1"
PORT="3306"
USERNAME="root"
PASSWORD="123456"


sed -i "s/innodb_buffer_pool_size.*/innodb_buffer_pool_size= ${INNODB_BUFFER_POOL_SIZE}G /g" /home/elex/mysql/conf/my.cnf
sed -i "s?innodb_write_io_threads = 8?innodb_write_io_threads = 8 \nskip-log-bin?g" /home/elex/mysql/conf/my.cnf

sed -i "s/bind-address.*//g" /home/elex/mysql/conf/my.cnf

echo "mysql starting...."
cd /home/elex/mysql && /home/elex/mysql/mysql_control start
if [ ! -d "/home/hgdb2002.sql" ]; then
  #授权
        /home/elex/mysql/bin/mysql  -e "grant all privileges on *.* to 'root'@'%' identified by '123456';grant all privileges on *.* to 'root'@'localhost' identified by '123456';grant all privileges on *.* to 'root'@'127.0.0.1' identified by '123456';flush privileges"
        #建库建表
        /home/elex/mysql/bin/mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "create database hgdb;set sql_log_bin=off;set autocommit=0;start transaction;use hgdb;source /home/hgdb2002.sql;commit;set autocommit=1;"
        /home/elex/mysql/bin/mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "create database td_global;use td_global;source /home/td_global.sql;"
else
  echo '$var1 not eq $var2'
fi


