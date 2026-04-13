#!/bin/sh

# read -r -n 1 key

if [[ $key == $'\e' ]];
then
echo aborted
else
echo OK
fi

