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
# set CODEWIND_VERSION -- need a better way of finding correct line
eval `docker inspect --format='{{index .Config.Env 3}}' $pfeContainerID`
echo "Collecting PFE workspace"
docker cp $pfeContainerID:/codewind-workspace .

# Collect docker-compose file
echo "Collecting docker-compose"
cp $CODEWIND_HOME/docker-compose.yaml .

# Collect CWCTL version number
echo "Collecting CWCTL version"
$CODEWIND_HOME/$CODEWIND_VERSION/cwctl --version > cwctl.version

echo "Finished!"
