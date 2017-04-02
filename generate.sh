#!/bin/bash

# Default Name for ISO_FILE

if [ -z "${1}" ]; then
   echo "Usage: ${0} dir name_of_iso"
   echo "dir is a directory that contains config-drive dir"
   echo "name_of_iso is optional"
   exit 1
fi

if [ -z "${2}" ]; then
  ISO_NAME=${1}
else
  ISO_NAME=${2}
fi

ISO_FILE=${ISO_NAME}-configdrive.iso

if [ -e $ISO_FILE ]
then
  rm $ISO_FILE
fi

mkisofs -R -V config-2 -o $ISO_FILE $1/config-drive