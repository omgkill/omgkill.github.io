#!/bin/bash

rm -rf  /home/elex/mysql/data/sql/all_srv
expect <<'EOD'
spawn scp -r root@10.0.3.21:/home/ClashOfKingProject/sql/zone/all_srv/ /home/elex/mysql/data/sql
expect {
"yes/no" { send "yes\r";exp_continue;}
"root@10.0.3.21's password:" { send "1q2w3e4r5t\r" }
}
expect eof
EOD

if [ "$1" ] ;then
  ls /home/elex/mysql/data/sql/all_srv | egrep -v ^$1  | xargs -n1 -i rm /home/elex/mysql/data/sql/all_srv/{}
else
  cat /home/elex/mysql/data/version.txt | egrep  -o "^([0-9]+.[0-9]+.[0-9]).+sql" | xargs -n1 -i rm /home/elex/mysql/data/sql/all_srv/{}
fi



cd /home/elex/mysql/data/sql/all_srv &&  ls | xargs -n1 -i /home/elex/mysql/bin/mysql -uroot -h127.0.0.1  -p123456  -e "use hgdb9000;source {};"


ls | xargs -n1 -i {} >> /home/elex/mysql/data/version.txt