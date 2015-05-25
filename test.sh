#!/bin/bash
iso=CentOS-7-x86_64-NetInstall-1503.iso
for mirror in $(curl -s http://isoredirect.centos.org/centos/7/isos/x86_64/ | sed  "s/[<>']/\ /g" | awk '$1 ~ /^http/')
do
	curl -Is $mirror$iso | grep OK > /dev/null
	[ $? -eq 0 ] && echo "$site is OK..Install can proceed"; break;
done
									
