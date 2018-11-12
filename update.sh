#!/system/bin/sh

cd /data/update

# First we determine what type of update package is being installed...
tar -xjf update.tar.bz2 type
TYPE=$(cat type)
rm type

AB=$(getprop ro.build.ab_update)

mkdir -p /mnt/system

if [ -z $AB ]; then
  mount -t "$(mount | grep -o '/dev/block/[a-zA-Z0-9]* on /system type .*' | tr -s ' ' | cut -d ' ' -f 5)" -r "$(mount | grep -o '/dev/block/[a-zA-Z0-9]* on /system type .*' | tr -s ' ' | cut -d ' ' -f 1)" /mnt/system
  PREFIX="/system/"
else
  mount -t "$(mount | grep -o '/dev/block/[a-zA-Z0-9]* on / type .*' | tr -s ' ' | cut -d ' ' -f 5)" -r "$(mount | grep -o '/dev/block/[a-zA-Z0-9]* on / type .*' | tr -s ' ' | cut -d ' ' -f 1)" /mnt/system
  PREFIX="/"
fi
mount -wo remount /mnt/system

tot="0"

if [ "$TYPE" = "incr" ]; then
  tar -xjf update.tar.bz2 update.files
  FILES=$(cat update.files)
  rm update.files
  while read -r file; do
    echo "now doing: $file"
    echo "now extracting..."
    cd /mnt
    tar -xjf /data/update/update.tar.bz2 "system/$file.new" #Put the new file in place
    ln "system/$file" "system/$file.old"
    echo "going in for the kill"
    ln -f "system/$file.new" "system/$file" && mount -o bind "$PREFIX$file.old" "$PREFIX$file" || (setprop sys.update -1) #Why can linux not do this atomically???
    echo "headshot!"
    rm "system/$file.new"
    rm "system/$file.old"
    tot=$(($tot + 1))
    setprop sys.update $tot
  done <<< "$FILES"
  cd /data/update
  tar -xjf update.tar.bz2 rm.files
  FILES=$(cat rm.files)
  rm rm.files
  while read -r file; do
    echo "now doing: $file"
    rm -rf "/mnt/system/$file" #Theres no good way to do this... but it doesn't matter bcos it will be unlinked not deleted
    tot=$(($tot + 1))
    setprop sys.update $tot
  done <<< "$FILES"
  tar -xjf update.tar.bz2 add.files
  FILES=$(cat add.files)
  rm add.files
  cd /mnt
  while read -r file; do
    echo "now doing: $file"
    tar -xjf /data/update/update.tar.bz2 "system/$file" #Theres no good way to do this...
    tot=$(($tot + 1))
    setprop sys.update $tot
  done <<< "$FILES"
fi
umount /mnt/system
setprop sys.update false
