#!/system/bin/sh

#
#  Copyright (C) 2018 Penn Mackintosh
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#       https://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

cd /data/update
echo starting
# First we determine what type of update package is being installed...
#tar -xf update.tar.bz2 type
echo xtracted
#TYPE=$(cat type)
TYPE=incr
echo cated
rm type

echo stage 1.5

AB=$(getprop ro.build.ab_update)

echo stage 2

if [ -z $AB ]; then
  PREFIX="/system/"
  mount -wo remount "/system"
else
  PREFIX="/"
  mount -wo remount "/"
fi

tot="0"

mkdir /mnt/extracttmp
mkdir /mnt/system

while read -r file; do
  mount -wo remount "$file"
done <<< "$(mount | grep -o '/dev/block/[a-zA-Z0-9]* on /system.* type .*' | tr -s ' ' | cut -d ' ' -f 3)"

if [ "$TYPE" = "incr" ]; then
  export LD_LIBRARY_PATH="$PATH:/mnt/system/lib:/mnt/system/lib64"
  export PATH="$PATH:/mnt/system/bin"
#  tar -xf update.tar.bz2 update.files
  FILES=$(cat update.files)
  rm update.files
  while read -r file; do
    if [[ -z $file ]]; then
      continue
    fi
    echo "now doing: $file"
    #echo "now extracting..."
    cd /mnt/extracttmp
#    tar -xf /data/update/update.tar.bz2 "system/$file" #Put the new file in place
    mkdir -p "$(echo system/$file | sed 's;/[^/]*$;;')"
    cp -a /data/update/system/$file system/$file
    mv "system/$file" "$PREFIX$file.new"
    #echo "going in for the kill"
    mkdir -p "$(echo /mnt/system/$file | sed 's;/[^/]*$;;')"
    cp -a "$PREFIX$file" "/mnt/system/$file" || (echo "bakup fail!!";continue)
    umount -l "$PREFIX$file" 2>/dev/null
    umount -l "$PREFIX$file" 2>/dev/null
    (ln -f "$PREFIX$file" "$PREFIX$file.old" && ln -f "$PREFIX$file.new" "$PREFIX$file" && mount -o bind "$PREFIX$file.old" "$PREFIX$file") || (echo fail;setprop sys.update -1) #Why can linux not do this atomically???
#    echo "headshot!"
    rm "$PREFIX$file.new"
    rm "$PREFIX$file.old"
    tot=$(($tot + 1))
    setprop sys.update $tot
  done <<< "$FILES"
  cd /data/update
#  tar -xf update.tar.bz2 rm.files
  FILES=$(cat rm.files)
  rm rm.files
  while read -r file; do
    echo "now doing rm: $file"
    umount -l "$PREFIX$file" 2>/dev/null
    umount -l "$PREFIX$file" 2>/dev/null
    mount -wo remount "$(echo $PREFIX$file | sed 's;/[^/]*$;;')" #For magisk
    rm -rf "$PREFIX$file" #Theres no good way to do this... but it doesn't matter bcos it will be unlinked not deleted
    tot=$(($tot + 1))
    setprop sys.update $tot
  done <<< "$FILES"
  #tar -xf update.tar.bz2 add.files
  FILES=$(cat add.files)
  rm add.files
  cd /mnt/extracttmp
  while read -r file; do
    echo "now doing add: $file"
    mkdir -p "$(echo /mnt/system/$file | sed 's;/[^/]*$;;')"
#    tar -xf /data/update/update.tar.bz2 "system/$file" #Theres no good way to do this...
    cp -R /data/update/system/$file system/$file
    umount -l "$PREFIX$file" 2>/dev/null
    umount -l "$PREFIX$file" 2>/dev/null
    mv system/$file $PREFIX$file
    tot=$(($tot + 1))
    setprop sys.update $tot
  done <<< "$FILES"
fi
setprop sys.update false
