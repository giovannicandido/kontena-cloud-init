#!/bin/bash

echo "Generates nodes changing only the hostname"

if [ -z "${1}" ]; then
  echo "Usage: ${0} how_many"
  exit 1
fi

USER_DATA_LOCATION=nodes/config-drive/openstack/latest/user_data

for node in `seq 1 ${1}`; do
  echo "Creating iso for node $i"
  ISO_FILE=node$node-configdrive.iso
  echo ${ISO_FILE}
  cp $USER_DATA_LOCATION user_data.bak
  sed -ri 's/^(\s*)(hostname\s*:\s*node\s*$)/\1hostname: '"node$node"'/' $USER_DATA_LOCATION
  if [ -e $ISO_FILE ]; then
    rm $ISO_FILE
  fi
  mkisofs -R -V config-2 -o $ISO_FILE nodes/config-drive
  cp user_data.bak $USER_DATA_LOCATION
done
