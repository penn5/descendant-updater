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
		[[ $(cat $2 | grep "$i") ]] && common $i || echo $i >> $ota/rm.files
	done
	cat $2 | while read -r i; do
		[[ $(cat $1 | grep "$i") ]] && common $i || echo $i >> $ota/add.files
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
		[[ "$(md5 $old/$m)" != "$(md5 $new/$m)" ]] && echo "$m" >> $ota/update.files
	done
	for m in $(cat $ota/update.files); do
		cp -a 

}

prettify(){
> "$1".pretty
cat $1 | while read -r a; do
	match=0
	temp="$a"
	until [[ ! "$temp" =~ '/' ]] || [[ "$match" = "1" ]]; do
		[[ $(grep -Fx "$temp" "$1".pretty) ]] && match=1
		temp=${temp%/*}
	done
	[[ "$match" = "0" ]] && echo $a >> "$1".pretty
done
sed -i 's/\.\///' "$1".pretty
}

mkdir tmp
tmp="$PWD/tmp"
ota="$PWD/ota"
old=$(realpath "$1")
new=$(realpath "$2")
list
for c in {add,del,upd}; do
	prettify $tmp/$c
done
