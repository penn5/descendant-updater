#!/bin/bash

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

mkdir ota
diff="$(python target_files_diff.py $1 $2)"
echo "$diff"

while read -r file; do
  echo $file
  if [ -e "$0/$file" ]; then
    if [ -e "$1/$file" ]; then
      if [ -d "$0/$file" ]; then
        if [ -f "$1/$file" ]; then
          echo "Please generate the OTA manually; you may need a customized update script"
          exit 3
        fi
      fi
      if [ -d "$1/$file" ]; then
        if [ -f "$0/$file" ]; then
          echo "Please generate the OTA manually; you may need a customized update script"
          exit 3
        fi
        find "$1/$file" -depth -print | cpio -pvmud ota/
        find "$1/$file" -depth -exec mv '{}' '{}.new' \;
        echo "$file" >> ota/update.files
      fi
      echo "$1/$file" | cpio -pvmud ota/
      mv "ota/system/$file" "ota/system/$file.new"
      echo "$file" >> ota/update.files
    else
      find "$1/$file" -depth -print | cpio -pvmud ota/
      echo "$file" >> ota/add.files
    fi
  else
    echo "$file" >> ota/rm.files
  fi
done <<< "$diff"
cd ota
echo -n incr > type
tar -cjpf update.tar.bz2 --strip-components=1 --transform 's/.\///' .
echo OTA Generated at ota/update.tar.bz2
