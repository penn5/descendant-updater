#!/bin/bash

#
#  Copyright (C) 2018 Mohamed Nahil Hamdhy
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

dif(){
	common(){
		[[ $(cat $tmp/common | grep "$1") ]] || echo $1 >> $tmp/common
	}
	cat $1 | while read -r i; do
		[[ $(cat $2 | grep "$i") ]] && common $i || (echo $i | sed "s;./;;" >> $ota/rm.files;echo "rm: $i")
	done
	cat $2 | while read -r i; do
		[[ $(cat $1 | grep "$i") ]] && common $i || (echo $i | sed "s;./;;" >> $ota/add.files;echo "add: $i")
	done
}

md5(){
	local ret=$(md5sum $1 | cut -d ' ' -f 1)
	echo $ret
}

list(){
	> $tmp/common
	> $ota/add.files
	> $ota/rm.files
	(cd $old; find . -type d > $tmp/old)
	(cd $new; find . -type d > $tmp/new)
	dif $tmp/old $tmp/new
	cp $tmp/common $tmp/common_fld
	> $tmp/common
	> $ota/update.files
	for f in $(cat $tmp/common_fld); do
		(cd $old; find "$f" -maxdepth 1 -type f > $tmp/old)
		(cd $new; find "$f" -maxdepth 1 -type f > $tmp/new)
		dif $tmp/old $tmp/new
	done
	for m in $(cat $tmp/common); do
		[[ "$(md5 $old/$m)" != "$(md5 $new/$m)" ]] && (echo "$m" | sed "s;./;;" >> $ota/update.files;echo "update: $m")
	done
	cd $new
        mkdir $ota/system
	find . -type d | tar --no-recursion -cpT - -f - | (cd $ota/system;tar -xpf -)
	for m in $(cat $ota/update.files); do
		cp -a $new/$m $ota/system/$m
	done
	for m in $(cat $ota/add.files); do
		cp -a $new/$m $ota/system/$m
	done

}

mkdir tmp
mkdir ota
tmp="$PWD/tmp"
ota="$PWD/ota"
old=$(realpath "$1")
new=$(realpath "$2")
list
cd $ota
