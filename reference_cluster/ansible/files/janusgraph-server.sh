#!/bin/bash
# Copyright 2018 JanusGraph Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[[ -n "$DEBUG" ]] && set -x

SOURCE="${BASH_SOURCE[0]}"
while [[ -h "$SOURCE" ]]; do
  BIN="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$BIN/$SOURCE"
done
BIN="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd -P "$( dirname "$SOURCE" )" || exit 1
# Set $CFG to $BIN/../conf/gremlin-server
cd -P $BIN/../conf/gremlin-server
CFG=$(pwd)
# Set $LIB to $BIN/../lib
cd -P $BIN/../lib
LIB=$(pwd)
# Set $LIB to $BIN/../ext
cd -P $BIN/../ext
EXT=$(pwd)
# Initialize classpath to $CFG
CP="$CFG"
# Add the slf4j-log4j12 binding
CP="$CP":$(find -L $LIB -name 'slf4j-log4j12*.jar' | sort | tr '\n' ':')
# Add the jars in $BIN/../lib that start with "janusgraph"
CP="$CP":$(find -L $LIB -name 'janusgraph*.jar' | sort | tr '\n' ':')
# Add the remaining jars in $BIN/../lib.
CP="$CP":$(find -L $LIB -name '*.jar' \
                \! -name 'janusgraph*' \
                \! -name 'slf4j-log4j12*.jar' | sort | tr '\n' ':')
# Add the jars in $BIN/../ext (at any subdirectory depth)
CP="$CP":$(find -L $EXT -name '*.jar' | sort | tr '\n' ':')

JANUSGRAPH_SERVER_CMD=org.apache.tinkerpop.gremlin.server.GremlinServer

# (Cygwin only) Use ; classpath separator and reformat paths for Windows ("C:\foo")
[[ $(uname) = CYGWIN* ]] && CP="$(cygpath -p -w "$CP")"

export CLASSPATH="${CLASSPATH:-}:$CP"

# Change to $BIN's parent
cd $BIN/..

[[ -n "$DEBUG" ]] && set -x

if [[ -z "$JANUSGRAPH_HOME" ]]; then
  JANUSGRAPH_HOME="$(pwd)"
fi

if [[ -z "$LOG4J_CONF" ]]; then
  LOG4J_CONF="file:$JANUSGRAPH_HOME/conf/gremlin-server/log4j-server.properties"
fi

if [[ -z "$JANUSGRAPH_LOGDIR" ]] ; then
  JANUSGRAPH_LOGDIR="$JANUSGRAPH_HOME/logs"
fi

export JANUSGRAPH_LOGDIR="$BIN/../log"

if [[ -z "$PID_DIR" ]] ; then
  PID_DIR="$JANUSGRAPH_HOME/run"
fi

if [[ -z "$PID_FILE" ]]; then
  PID_FILE=$PID_DIR/janusgraph.pid
fi

if [[ -z "$JANUSGRAPH_YAML" ]]; then
  JANUSGRAPH_YAML=$CFG/gremlin-server.yaml
fi
echo "JANUSGRAPH_YAML is $JANUSGRAPH_YAML"
if [[ ! -r "$JANUSGRAPH_YAML" ]]; then
  # fqdn failed, try relative to home
  if [[ -r "$JANUSGRAPH_HOME/$JANUSGRAPH_YAML" ]]; then
    JANUSGRAPH_YAML="$JANUSGRAPH_HOME/$JANUSGRAPH_YAML"
  else
    echo WARNING: Tried "$JANUSGRAPH_YAML" and "${JANUSGRAPH_HOME}/${JANUSGRAPH_YAML}". Neither were readable.
  fi
fi

# Find Java
if [ "$JAVA_HOME" = "" ] ; then
    JAVA="java -server"
else
    JAVA="$JAVA_HOME/bin/java -server"
fi

# Set Java options
if [ "$JAVA_OPTIONS" = "" ] ; then
    JAVA_OPTIONS="-Xms32m -Xmx512m -javaagent:$LIB/jamm-0.3.0.jar -Dgremlin.io.kryoShimService=org.janusgraph.hadoop.serialize.JanusGraphKryoShimService"
fi

isRunning() {
  if [[ -r "$PID_FILE" ]] ; then
    PID=$(cat "$PID_FILE")
    ps -p "$PID" &> /dev/null
    return $?
  else
    return 1
  fi
}

status() {
  isRunning
  RUNNING=$?
    if [[ $RUNNING -gt 0 ]]; then
      echo Server not running
    else
      echo Server running with PID $(cat "$PID_FILE")
    fi
}

stop() {
  isRunning
  RUNNING=$?
  if [[ $RUNNING -gt 0 ]]; then
    echo Server not running
    rm -f "$PID_FILE"
  else
    kill "$PID" &> /dev/null || { echo "Unable to kill server [$PID]"; exit 1; }
    for i in $(seq 1 60); do
      ps -p "$PID" &> /dev/null || { echo "Server stopped [$PID]"; rm -f "$PID_FILE"; return 0; }
      [[ $i -eq 30 ]] && kill "$PID" &> /dev/null
      sleep 1
    done
    echo "Unable to kill server [$PID]";
    exit 1;
  fi
}

start() {
  isRunning
  RUNNING=$?
  if [[ $RUNNING -eq 0 ]]; then
    echo Server already running with PID $(cat "$PID_FILE").
    exit 1
  fi

  mkdir -p "$JANUSGRAPH_LOGDIR" &>/dev/null
  if [[ ! -d "$JANUSGRAPH_LOGDIR" ]]; then
    echo ERROR: JANUSGRAPH_LOGDIR $JANUSGRAPH_LOGDIR does not exist and could not be created.
    exit 1
  fi

  mkdir -p "$PID_DIR" &>/dev/null
  if [[ ! -d "$PID_DIR" ]]; then
    echo ERROR: PID_DIR $PID_DIR does not exist and could not be created.
    exit 1
  fi

  $JAVA -Djanusgraph.logdir="$JANUSGRAPH_LOGDIR" -Dlog4j.configuration=$LOG4J_CONF $JAVA_OPTIONS -cp $CP:$CLASSPATH $JANUSGRAPH_SERVER_CMD $JANUSGRAPH_YAML
  PID=$!
  disown $PID
  echo $PID > "$PID_FILE"

  isRunning
  RUNNING=$?
  if [[ $RUNNING -eq 0 ]]; then
    echo Server started $(cat "$PID_FILE").
    exit 0
  else
    echo Server failed
    exit 1
  fi

}

startForeground() {
  isRunning
  RUNNING=$?
  if [[ $RUNNING -eq 0 ]]; then
    echo Server already running with PID $(cat "$PID_FILE").
    exit 1
  fi

  if [[ -z "$RUNAS" ]]; then
    $JAVA -Dlog4j.configuration=$LOG4J_CONF $JAVA_OPTIONS -cp $CP:$CLASSPATH $JANUSGRAPH_SERVER_CMD "$JANUSGRAPH_YAML"
    exit 0
  else
    echo Starting in foreground not supported with RUNAS
    exit 1
  fi

}

install() {

  isRunning
  RUNNING=$?
  if [[ $RUNNING -eq 0 ]]; then
    echo Server must be stopped before installing.
    exit 1
  fi

  echo Installing dependency $@
  $JAVA -Djanusgraph.logdir="$JANUSGRAPH_LOGDIR" -Dlog4j.configuration=$LOG4J_CONF $JAVA_OPTIONS -cp $CP:$CLASSPATH org.apache.tinkerpop.gremlin.server.util.GremlinServerInstall "$@"


}

case "$1" in
  status)
    status
    ;;
  restart)
    stop
    start
    ;;
  start)
    start
    ;;
  stop)
    stop
    ;;
  install)
    shift
    install "$@"
    ;;
  console)
    startForeground
    ;;
  *)
    if [[ -n "$1" ]] ; then
      if [[ -r "$1" ]]; then
        JANUSGRAPH_YAML="$1"
        startForeground
      elif [[ -r "$JANUSGRAPH_HOME/$1" ]] ; then
        JANUSGRAPH_YAML="$JANUSGRAPH_HOME/$1"
        startForeground
      fi
      echo Configuration file not found.
    fi
    echo "Usage: $0 {start|stop|restart|status|console|install <group> <artifact> <version>|<conf file>}"
    echo
    echo "    start        Start the server in the background using conf/gremlin-server/gremlin-server.yaml as the"
    echo "                 default configuration file"
    echo "    stop         Stop the server"
    echo "    restart      Stop and start the server"
    echo "    status       Check if the server is running"
    echo "    console      Start the server in the foreground using conf/gremlin-server/gremlin-server.yaml as the"
    echo "                 default configuration file"
    echo "    install      Install dependencies"
    echo
    echo "If using a custom YAML configuration file then specify it as the only argument for Gremlin"
    echo "Server to run in the foreground or specify it via the JANUSGRAPH_YAML environment variable."
    echo
    exit 1
    ;;
esac