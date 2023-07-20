#!/bin/bash

#/home/elex/mybat/conf/my.cnf

STR=$(cat dd.txt | grep skip-log-bin);


if [ ! "$STR" ];then
  echo "test success"
fi