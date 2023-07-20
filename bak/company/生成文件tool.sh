#!/bin/bash -e

SCRIPT_ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG=en_US.UTF-8
DEBUG_ON=
REMOTE_SERVER_ROOT=

export PS4='+${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]}: '

shopt -s expand_aliases
alias LOGDEBUG="set +x && log DEBUG"
alias LOGINFO="set +x && log INFO"
alias LOGWARNING="set +x && log WARNING"
alias LOGERROR="set +x && log ERROR"

function log() {
  set +x
  if [ "$#" -lt 2 ]; then
    echo "$0 <level> <msg>"
    exit
  fi
  local level=$1
  shift 1
  local logfilename=LOGFILE_${level}
  if [[ ! "${!logfilename}" ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')][${level}] $@"
  else
    logfilename=${!logfilename}
    echo "[$(date +'%Y-%m-%d %H:%M:%S')][${level}] $@" | tee -a $logfilename
  fi
  ${DEBUG_ON}
}

function usage() {
  echo "Usage: sh $(basename $0) syncall sectionId | syncjar sectionId | syncmeta sectionId | genall | genmeta | genmodel | genproto | genjson | packcs"
  echo "        makejar                 打包game，并拷贝依赖"
  echo "        syncall sectionId       同步jar包和meta到指定的dev服务器，例如:sh tool.sh syncall 101"
  echo "        syncjar sectionId       同步jar包到指定的dev服务器，例如:sh tool.sh syncjar 101"
  echo "        syncmeta sectionId      同步meta到指定的dev服务器，例如:sh tool.sh syncmeta 101"
  echo "        genall                  生成全部的model、meta、proto文件，并自动将客户端需要的文件打包，例如:sh tool.sh genall"
  echo "        genmeta                 生成meta结构文件，例如:sh tool.sh genmeta"
  echo "        genmodel                生成model结构文件，例如:sh tool.sh genmodel"
  echo "        genproto                生成proto结构文件，例如:sh tool.sh genproto"
  echo "        genjson                 生成proto文件的json描述文档，例如:sh tool.sh genjson"
  echo "        packcs                  将客户端需要的文件打包，例如:sh tool.sh packcs"
}

function remote_server_root() {
  local section=$1
  host=172.16.153.92
  REMOTE_SERVER_ROOT=user00@$host:/data/home/user00/japari/s$section
  LOGINFO "remoteServerRoot: $REMOTE_SERVER_ROOT"
}

function makejar() {
  cd $SCRIPT_ROOT/game
  mvn clean package -U -Dmaven.test.skip.exec
  mvn dependency:copy-dependencies
}

function syncmeta() {
  remote_server_root $@
  cd $SCRIPT_ROOT
  rsync --delete -avz /Users/topjoy/workspace/japari/frontend/japaridemo/Assets/Res/Numeric/*.num $REMOTE_SERVER_ROOT/meta/
  LOGINFO "sync meta success to remote path: $REMOTE_SERVER_ROOT/meta"
}

function syncjar() {
  remote_server_root $@
  cd $SCRIPT_ROOT/game
  rsync --delete -avz target/game-1.0.1-SNAPSHOT.jar $REMOTE_SERVER_ROOT
  rsync --delete -avz target/dependency/ $REMOTE_SERVER_ROOT/dependency
  LOGINFO "sync jar success to remote path: $REMOTE_SERVER_ROOT/"
}

function syncall() {
  syncjar $@
  syncmeta $@
}

function compile_entity() {
  cd $SCRIPT_ROOT/entity-structs
  mvn clean compile -U -Dmaven.test.skip.exec
  mvn dependency:copy-dependencies
}

function gen_model() {
  cd $SCRIPT_ROOT/entity-structs
  java -cp target/classes/:target/dependency/* -Xmx512m -Xms512m com.topjoy.japari.model.GenModelsMain -p config/model/gen_models.json
  rm -rf $SCRIPT_ROOT/game/src/main/java/com/topjoy/japari/gs/gen/model/*
  cp -r output/model/java/* $SCRIPT_ROOT/game/src/main/java/
}

function gen_proto() {
  cd $SCRIPT_ROOT/entity-structs
  java -cp target/classes/:target/dependency/* com.topjoy.japari.protocol.ProtocolMain -p config/protocol/gen_protos.json -s -c
  rm -rf $SCRIPT_ROOT/game/src/main/java/com/topjoy/japari/gs/gen/protocol/*
  cp -r output/msg/java/* $SCRIPT_ROOT/game/src/main/java
  rm -rf $SCRIPT_ROOT/lego/src/main/java/com/topjoy/japari/gs/gen/protocol/*
  cp -r output/msg/java/* $SCRIPT_ROOT/lego/src/main/java
  rm -rf $SCRIPT_ROOT/client/src/main/java/com/topjoy/japari/gs/gen/protocol/*
  cp -r output/msg/java/* $SCRIPT_ROOT/client/src/main/java
  cp output/msg/message_config.json $SCRIPT_ROOT/game/src/main/resources/
  cp output/msg/message_config.json $SCRIPT_ROOT/client/src/main/resources/
}

function gen_meta() {
  cd $SCRIPT_ROOT/entity-structs
  java -cp target/classes/:target/dependency/* -Xmx512m -Xms512m com.topjoy.japari.meta.MetaMain -p config/meta/gen_metas.json -f json -e .schema -s -m
  rm -rf $SCRIPT_ROOT/game/src/main/java/com/topjoy/japari/gs/gen/meta/*
  cp -r output/meta/java/* $SCRIPT_ROOT/game/src/main/java/
}

function gen_json(){
  cd $SCRIPT_ROOT/entity-structs/protobuf3/bin
  ./protoc --doc_out=$SCRIPT_ROOT/web_client/json --plugin=protoc-gen-doc=protoc-gen-doc --doc_opt=json,proto.json $SCRIPT_ROOT/protocols/*.proto  --proto_path=$SCRIPT_ROOT/protocols/ --proto_path=$SCRIPT_ROOT/protocols/model
  cd $SCRIPT_ROOT/web_client/json
  sed "1s/{/var proto = {/" proto.json > proto.js
}

function packcs() {
  cd $SCRIPT_ROOT/entity-structs
  rm -f output/cs.tar.gz
  tar -zcvf output/cs.tar.gz output/msg/csharp
}

function genall() {
  compile_entity
  gen_model
  gen_proto
  gen_meta
  packcs
}

function genmodel() {
  compile_entity
  gen_model
}

function genproto() {
  compile_entity
  gen_proto
}

function genjson() {
  gen_json
}

function genmeta() {
  compile_entity
  gen_meta
}


function foo() {
  server_id=$(($1))
}

function drum() {
  rm -rf data_config.json
  rm -rf japari-config

  git clone --depth=1 -b beta_new --single-branch git@git.youle.game:japari/japari-config.git
  config_dir=$SCRIPT_ROOT/japari-config/Data
  echo "{\"dataConfigPath\":\"$config_dir\"}" > data_config.json

  cd game
  mvn clean compile dependency:copy-dependencies -Dmaven.test.skip=true
  nohup java -server -javaagent:$SCRIPT_ROOT/lego/jacocoagent.jar -Dproject-root=$SCRIPT_ROOT -Dspring.profiles.active=drum -cp target/classes/:target/dependency/* com.topjoy.japari.JapariMain --numeric-path=$SCRIPT_ROOT/japari-config/Data > /dev/null 2>&1 &
  sleep 60

  cd ../lego
  mvn clean compile test -DdataConfig.path=$SCRIPT_ROOT

  cd ..
  rm data_config.json
  rm -rf japari-config
}

function runaction() {
  set +x
  local declared_action_name
  local action
  action=$1
  declared_action_name=$(declare -F $action || true)
  if test ! -n "$declared_action_name"; then
    LOGINFO "$action() not found in $0"
    usage
    exit 1
  fi

  shift 1
  ${DEBUG_ON}
  $action $@
}

runaction $@
