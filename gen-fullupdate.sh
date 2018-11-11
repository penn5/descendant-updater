#!/bin/bash
mkdir ota
cp -R system ota/system
cd ota
echo -n incr > type
tar -cvjpf update.tar.bz2 --strip-components=1 --transform 's/.\///' --show-transformed-names .
echo OTA Generated at ota/update.tar.bz2
