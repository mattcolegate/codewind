#!/usr/bin/env sh
#*******************************************************************************
# Copyright (c) 2020 IBM Corporation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v2.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v20.html
#
# Contributors:
#     IBM Corporation - initial API and implementation
#*******************************************************************************
# Envars
#
# CODEWIND_HOME - set to the .codewind directory in your home directory
# CODEWIND_ECLIPSE_WORSPACE - set to your Eclipse Workspace directory.

if [ -z "$CODEWIND_HOME" ]; then
  CODEWIND_HOME=$HOMEPATH/.codewind
fi

mkdir -p ./mustgather
cd ./mustgather

# Collect Codewind container inspection & logs

for containerID in $(docker ps -a -q  --filter name=codewind)
do
  containerName=$(docker inspect --format='{{.Name}}' $containerID | sed 's/^.\{1\}//')
  echo "Collecting information from container $containerName"
  echo $(docker inspect $containerID) > ${containerName}.inspect
  echo $(docker logs --details $containerID) > ${containerName}.log
done

# Collect Codewind apps container inspection & logs

for containerID in $(docker ps -a -q  --filter name=cw-)
do
  containerName=$(docker inspect --format='{{.Name}}' $containerID | sed 's/^.\{1\}//')
  echo "Collecting information from container $containerName"
  echo $(docker inspect $containerID) > ${containerName}.inspect
  echo $(docker logs --details $containerID) > ${containerName}.log
done

# Collect Codewind PFE workspace

pfeContainerID=$(docker ps -a -q  --filter name=codewind-pfe)
# set CODEWIND_VERSION for later
eval `docker inspect --format='{{range $_, $value := .Config.Env}}{{println $value}}{{end}}' $pfeContainerID | grep CODEWIND_VERSION`
echo "Collecting PFE workspace"
docker cp $pfeContainerID:/codewind-workspace .

# Collect docker-compose file
echo "Collecting docker-compose"
cp $CODEWIND_HOME/docker-compose.yaml .

# Collect CWCTL version number
echo "Collecting CWCTL version"
$CODEWIND_HOME/$CODEWIND_VERSION/cwctl --version > cwctl.version

# Attempt to gather VSCode logs
echo "Collecting VSCode logs"
case $OSTYPE in
  "darwin")
    vsCodeLogsDir=$HOME/Library/Application Support/Code/logs
    ;;
  "linux-gnu")
    vsCodeLogsDir=$HOME/.config/Code/logs
    ;;
  "msys"|"cygwin"|"win32")
    vsCodeLogsDir=$HOME/AppData/Roaming/Code/logs
    ;;
  *)
esac
if [ -d $vsCodeLogsDir ]; then
  mkdir -p vsCodeLogs
  cp -R $vsCodeLogsDir/*  vsCodeLogs
else
  echo "Unable to collect VSCode logs"
fi

# Attempt to gather Eclipse Logs
echo "Collecting Eclipse logs"
if [ -z "$CODEWIND_ECLIPSE_WORSPACE" ]; then
  echo "Unable to collect Eclipse logs - check CODEWIND_ECLIPSE_WORSPACE is set to your Codewind Eclipse Workspace directory"
else
  mkdir -p eclipseLogs
  cp -t eclipseLogs $CODEWIND_ECLIPSE_WORSPACE/.metadata/*.log $CODEWIND_ECLIPSE_WORSPACE/.metadata/.*.log $CODEWIND_ECLIPSE_WORSPACE/.metadata/.log
fi

echo "Finished!"
