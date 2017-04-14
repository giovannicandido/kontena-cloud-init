#!/bin/bash

platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   platform='linux'
elif [[ "$unamestr" == 'FreeBSD' ]]; then
   platform='freebsd'
elif [[ "$unamestr" == 'Darwin' ]]; then
   platform='macosx'
fi

echo "Generates nodes changing only the hostname"

if [ -z "${1}" ]; then
  echo "Usage: ${0} how_many"
  exit 1
fi

USER_DATA_LOCATION=nodes/config-drive/openstack/latest/user_data

if [[ $platform == 'unknown' ]]; then
  echo "Platform `uname` is unknown "
  exit 1
fi

for node in `seq 1 ${1}`; do
  echo "Creating iso for node $i"
  ISO_FILE=node$node-configdrive.iso
  echo ${ISO_FILE}
  cp $USER_DATA_LOCATION user_data.bak
  if [[ $platform == 'macosx' ]]; then
    gsed -ri 's/^(\s*)(hostname\s*:\s*node\s*$)/\1hostname: '"node$node"'/' $USER_DATA_LOCATION
  elif [[ "$platform" == 'linux' ]]; then
    sed -ri 's/^(\s*)(hostname\s*:\s*node\s*$)/\1hostname: '"node$node"'/' $USER_DATA_LOCATION
  fi
  if [ -e $ISO_FILE ]; then
    rm $ISO_FILE
  fi
  if [[ $platform == 'macosx' ]]; then
    hdiutil makehybrid -iso -joliet -default-volume-name config-2 -o $ISO_FILE nodes/config-drive
  elif [[ "$platform" == 'linux' ]]; then
    mkisofs -R -V config-2 -o $ISO_FILE nodes/config-drive
  fi
  
  cp user_data.bak $USER_DATA_LOCATION
done
