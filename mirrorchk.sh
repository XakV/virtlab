#!/bin/bash

for site in $(curl http://mirror-status.centos.org/ | sed 's/[<>"]/\ /g' | awk 'BEGIN {RS="TR"; FS=" "} /http:\/\// {if ($44=="ok") print $6}')
do
	curl -Is $site | grep OK > /dev/null
	[ $? -eq 0 ] && echo "$site is OK"
done
