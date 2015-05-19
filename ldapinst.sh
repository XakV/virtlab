#!/bin/bash

###install and configure ldap for a test lab on CentOS7
##users are ldapuser1 through ldapuser10
##user passwords are all Z0mgbee!

yum -y install openldap openldap-clients openldap-servers migrationtools

#set slappasswd to "redhat"

slappasswd -s redhat -n > /etc/openldap/passwd

#generate ssl cert (requires user interaction)

openssl req -new -x509 -nodes -out /etc/openldap/certs/cert.pem -keyout /etc/openldap/certs/priv.pem -days 365 -subj "/C=./ST=./L=./O=./CN=instructor.example.com"

#secure /etc/ldap

chown -R ldap:ldap /etc/openldap/certs
chmod 600 /etc/openldap/certs/priv.pem

#copy sample config

cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG

#check to see if slaptest is ok then change ownership to ldap user - enable - start slapd

slaptest

if [ $? -eq 1 ] 
then
	chown -R ldap:ldap /var/lib/ldap
	systemctl enable slapd
	systemctl start slapd
	netstat -lt | grep ldap
else
	echo "slapd enable failed"
	systemctl status slapd
	exit 1
fi

#configure

cd /etc/openldap/schema
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f nis.ldif

#copy changes.ldif and base.ldif to correct directory if it is created or exit if not

[ -f /changes.ldif ] && cp /changes.ldif /etc/openldap/changes.ldif || { echo "Dude you need an ldif"; exit 1; }

[ -f /etc/openldap/changes.ldif ] && { ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/openldap/changes.ldif; } || { echo "failed to modify changes.ldif"; exit 1; }


[ -f /base.ldif ] && cp /base.ldif /etc/openldap/base.ldif || { echo "Dude you need an ldif"; exit 1; }


[ -f /etc/openldap/base.ldif ] && { ldapadd -x -w redhat -D cn=Manager,dc=example,dc=com -f /etc/openldap/base.ldif; } || { echo "failed to add base.ldif"; exit 1; }

#create users for testing

mkdir /home/guests

ldappwd='Z0mgbee!'

for u in {1..10}
do
	useradd -d /home/guests/ldapuser$u -p $ldappwd ldapuser$u
done

#migrate user accounts

cd /usr/share/migrationtools

[ -f /usr/share/migrationtools/migrate_common.ph ] && { sed -i 's/"padl.com"/"example.com"/' /usr/share/migrationtools/migrate_common.ph; } && { sed -i 's/"dc=padl,dc=com"/"dc=example,dc=com"/' /usr/share/migrationtools/migrate_common.ph; }

#create users in the directory service

grep ":10[0-9][0-9]" /etc/passwd > passwd
./migrate_passwd.pl passwd users.ldif
ldapadd -x -w redhat -D cn=Manager,dc=example,dc=com -f users.ldif
 
grep ":10[0-9][0-9]" /etc/group > group
./migrate_group.pl group groups.ldif
ldapadd -x -w redhat -D cn=Manager,dc=example,dc=com -f groups.ldif

#setup firewall

firewall-cmd --permanent --add-service=ldap
firewall-cmd --reload

#enable logging

echo "local4.* /var/log/ldap.log" >> /etc/rsyslog.conf
systemctl restart rsyslog


echo "COMPLETE"
		
