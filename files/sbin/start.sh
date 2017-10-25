#!/usr/bin/env bash

JOB_MANAGER_RPC_ADDRESS=${JOB_MANAGER_RPC_ADDRESS:-$(hostname -f)}

if [ "$1" == "--help" -o "$1" == "-h" ]; then
  echo "Usage: $(basename $0) (jobmanager|taskmanager)"
  exit 0

elif [ "$1" == "jobmanager" ]; then
  echo "Starting Job Manager"
  sed -i -e "s/jobmanager.rpc.address: localhost/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" $FLINK_HOME/conf/flink-conf.yaml
  echo "blob.server.port: 6124" >> "$FLINK_HOME/conf/flink-conf.yaml"

  echo "config file: " && grep '^[^\n#]' $FLINK_HOME/conf/flink-conf.yaml
  exec $FLINK_HOME/bin/jobmanager.sh start cluster

elif [ "$1" == "taskmanager" ]; then
  echo "Starting Task Manager"
  sed -i -e "s/jobmanager.rpc.address: localhost/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" $FLINK_HOME/conf/flink-conf.yaml
  sed -i -e "s/taskmanager.numberOfTaskSlots: 1/taskmanager.numberOfTaskSlots: $(grep -c ^processor /proc/cpuinfo)/g" $FLINK_HOME/conf/flink-conf.yaml
  echo "blob.server.port: 6124" >> "$FLINK_HOME/conf/flink-conf.yaml"

  echo "config file: " && grep '^[^\n#]' $FLINK_HOME/conf/flink-conf.yaml
  exec $FLINK_HOME/bin/taskmanager.sh start
fi

exec "$@"
