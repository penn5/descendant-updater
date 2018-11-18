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
		[[ $(cat $2 | grep "$i") ]] && common $i || echo $i >> $tmp/del
	done
	cat $2 | while read -r i; do
		[[ $(cat $1 | grep "$i") ]] && common $i || echo $i >> $tmp/add
	done
}

md5(){
	local ret=$(md5sum $1 | cut -d ' ' -f 1)
	echo $ret
}

list(){
	> $tmp/common	
	(cd $old; find . -type d > $tmp/old)
	(cd $new; find . -type d > $tmp/new)
	dif $tmp/old $tmp/new
	cp $tmp/common $tmp/common_fld
	> $tmp/common
	for f in $(cat $tmp/common_fld); do
		(cd $old; find "$f" -maxdepth 1 -type f > $tmp/old)
		(cd $new; find "$f" -maxdepth 1 -type f > $tmp/new)
		dif $tmp/old $tmp/new
	done
	for m in $(cat $tmp/common); do
		[[ "$(md5 $old/$m)" = "$(md5 $new/$m)" ]] || echo $n >> $tmp/upd
	done

}
mkdir tmp
tmp="$PWD/tmp"
old=$(realpath "$1")
new=$(realpath "$2")
list