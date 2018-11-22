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

AB=$(getprop ro.build.ab_update)

if [ -z $AB ]; then
  PREFIX="/system/"
  mount -wo remount "/system"
else
  PREFIX="/"
  mount -wo remount "/"
fi

tot="0"

TYPE=$(cat type)
echo $TYPE
mkdir /mnt/extracttmp
mkdir /mnt/system
mkdir /mnt/systembak

mount -o bind /system /mnt/system #Magisk workaround; submounts are not preserved (we get a real disk image mounted here, not a ton of tmpfs's)

if [ "$TYPE" = "incr" ]; then
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/mnt/systembak/lib64"
  export PATH="$PATH:/mnt/systembak/bin"
#  tar -xf update.tar.bz2 update.files
  TOTAL=$(wc -l perms.files | cut -d " " -f 1)
  FILES=$(cat update.files)
  rm update.files
  while read -r file; do
    if [[ -z $file ]]; then
      continue
    fi
    #echo "now extracting..."
    cd /mnt/extracttmp
#    tar -xpf /data/update/update.tar.bz2 "system/$file" #Put the new file in place
    mkdir -p "$(echo system/$file | sed 's;/[^/]*$;;')" #
    cp -a /data/update/system/$file system/$file #
    mod=$(grep "^[0-9]* [0-9]* [0-9]* $file$" /data/update/perms.files | cut -d " " -f 1)
    uid=$(grep "^[0-9]* [0-9]* [0-9]* $file$" /data/update/perms.files | cut -d " " -f 2)
    grp=$(grep "^[0-9]* [0-9]* [0-9]* $file$" /data/update/perms.files | cut -d " " -f 3)
    chmod $mod "system/$file"
    chown -hP $uid "system/$file"
    chgrp -hP $grp "system/$file"
    mv "system/$file" "/mnt/system/$file.new"
    #echo "going in for the kill"
    mkdir -p "$(echo /mnt/systembak/$file | sed 's;/[^/]*$;;')"
    cp -a "$PREFIX$file" "/mnt/systembak/$file" || (echo "bakup fail!!";continue)
    umount -l "/system/$file" 2>/dev/null
    (ln -f "/mnt/system/$file.new" "/mnt/system/$file" && (restorecon -FR "$PREFIX$file" 2> /dev/null; mount -o bind "/mnt/systembak/$file" "$PREFIX$file")) || (echo fail;setprop sys.update -1;echo $file)
    restorecon -FR "$PREFIX$file" 2> /dev/null
    rm "/mnt/system/$file.new"
#    echo "headshot!"
    tot=$(($tot + 1))
    setprop sys.update $tot/$TOTAL
    getprop sys.update
  done <<< "$FILES"
  cd /data/update
#  tar -xf update.tar.bz2 rm.files
  FILES=$(cat rm.files)
  rm rm.files
  while read -r file; do
    rm -rf "/mnt/system/$file" #Theres no good way to do this... but it doesn't matter bcos it will be unlinked not deleted
    tot=$(($tot + 1))
    setprop sys.update $tot/$TOTAL
    getprop sys.update
  done <<< "$FILES"
  #tar -xf update.tar.bz2 add.files
  FILES=$(cat add.files)
  rm add.files
  cd /mnt/extracttmp
  while read -r file; do
    mkdir -p "$(echo system/$file | sed 's;/[^/]*$;;')"
#    tar -xf /data/update/update.tar.bz2 "system/$file" #Theres no good way to do this...
    cp -R /data/update/system/$file system/$file
    mod=$(grep "^[0-9]* [0-9]* [0-9]* $file$" /data/update/perms.files | cut -d " " -f 1)
    uid=$(grep "^[0-9]* [0-9]* [0-9]* $file$" /data/update/perms.files | cut -d " " -f 2)
    grp=$(grep "^[0-9]* [0-9]* [0-9]* $file$" /data/update/perms.files | cut -d " " -f 3)
    chmod $mod "system/$file"
    chown -hP $uid "system/$file"
    chgrp -hP $grp "system/$file"
    mv "system/$file" "/mnt/system/$file"
    restorecon -FR "/mnt/system/$file"
    tot=$(($tot + 1))
    setprop sys.update $tot/$TOTAL
    getprop sys.update
  done <<< "$FILES"
fi
restorecon -R /mnt/system
setprop sys.update false
