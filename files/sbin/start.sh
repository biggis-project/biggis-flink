#!/usr/bin/env bash

JOB_MANAGER_RPC_ADDRESS=${JOB_MANAGER_RPC_ADDRESS:-$(hostname -f)}
REMAINING_SYS_MEM_IN_PERCENT=${REMAINING_SYS_MEM_IN_PERCENT:-20}

# Render a file as template, performing variable substetutions but leaving quotes unchanged
# Credit: http://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
function render_template() {
eval "cat <<EOF
$(<$1)
EOF
"
}

function template() {
  local FILE=$1
  local TEMPLATE=${2:-$FILE.template}
  echo "[ $(date) ] Template config: $FILE from $TEMPLATE"
  render_template $TEMPLATE > $FILE
}

template /opt/flink/hadoop-conf/core-site.xml
template /opt/flink/hadoop-conf/hdfs-site.xml
template /opt/flink/conf/flink-conf.yaml

if [ "$1" == "--help" -o "$1" == "-h" ]; then
  echo "Usage: $(basename $0) (jobmanager|taskmanager)"
  exit 0

elif [ "$1" == "jobmanager" ]; then
  echo "Starting Job Manager"

  TM_MEMORY_PERCENT_FLOAT=$(echo $(( 100 - $REMAINING_SYS_MEM_IN_PERCENT )) / 100 | bc -l)
  TOTAL_MEMORY_AVAILABLE=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  TM_MEMORY_PORTION_MEGABYTE=$(echo $TOTAL_MEMORY_AVAILABLE*$TM_MEMORY_PERCENT_FLOAT/1024 | bc | awk '{print int($1)}')

  sed -i -e "s/jobmanager.rpc.address: localhost/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" $FLINK_HOME/conf/flink-conf.yaml
  sed -i -e "s/taskmanager.heap.mb: 1024/taskmanager.heap.mb: $TM_MEMORY_PORTION_MEGABYTE/g" $FLINK_HOME/conf/flink-conf.yaml
  echo "blob.server.port: 6124" >> "$FLINK_HOME/conf/flink-conf.yaml"

  echo "config file: " && grep '^[^\n#]' $FLINK_HOME/conf/flink-conf.yaml
  exec $FLINK_HOME/bin/jobmanager.sh start-foreground cluster

elif [ "$1" == "taskmanager" ]; then
  echo "Starting Task Manager"

  TM_MEMORY_PERCENT_FLOAT=$(echo $(( 100 - $REMAINING_SYS_MEM_IN_PERCENT )) / 100 | bc -l)
  TOTAL_MEMORY_AVAILABLE=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  TM_MEMORY_PORTION_MEGABYTE=$(echo $TOTAL_MEMORY_AVAILABLE*$TM_MEMORY_PERCENT_FLOAT/1024 | bc | awk '{print int($1)}')


  sed -i -e "s/jobmanager.rpc.address: localhost/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" $FLINK_HOME/conf/flink-conf.yaml
  sed -i -e "s/taskmanager.numberOfTaskSlots: 1/taskmanager.numberOfTaskSlots: $(grep -c ^processor /proc/cpuinfo)/g" $FLINK_HOME/conf/flink-conf.yaml
  sed -i -e "s/taskmanager.heap.mb: 1024/taskmanager.heap.mb: $TM_MEMORY_PORTION_MEGABYTE/g" $FLINK_HOME/conf/flink-conf.yaml
  echo "blob.server.port: 6124" >> "$FLINK_HOME/conf/flink-conf.yaml"

  echo "config file: " && grep '^[^\n#]' $FLINK_HOME/conf/flink-conf.yaml
  exec $FLINK_HOME/bin/taskmanager.sh start-foreground
fi

exec "$@"
