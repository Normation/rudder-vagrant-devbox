#!/bin/bash
#####################################################################################
# Copyright 2012 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

# set -ex

## Config stage

# Fetch parameters
KEYSERVER=keyserver.ubuntu.com
KEY=474A19E8
RUDDER_REPO_URL="http://www.rudder-project.org/apt-2.4-nightly/"

# Rudder related parameters
# use the same IP than in Vagrantfile
SERVER_INSTANCE_HOST="192.168.42.80"
DEMOSAMPLE="no"
LDAPRESET="yes"
INITPRORESET="yes"
ALLOWEDNETWORK[0]='192.168.42.0/24'

NODE1_IP="192.168.42.81"
NODE1_HOSTNAME="node1"
NODE1_IP="192.168.42.82"
NODE1_HOSTNAME="node2"
NODE1_IP="192.168.42.83"
NODE1_HOSTNAME="node3"
NODE1_IP="192.168.42.84"
NODE1_HOSTNAME="node4"
NODE1_IP="192.168.42.85"
NODE1_HOSTNAME="node5"
NODE1_IP="192.168.42.86"
NODE1_HOSTNAME="node6"
NODE1_IP="192.168.42.87"
NODE1_HOSTNAME="node7"
NODE1_IP="192.168.42.88"
NODE1_HOSTNAME="node8"
NODE1_IP="192.168.42.89"
NODE1_HOSTNAME="node9"
NODE1_IP="192.168.42.90"
NODE1_HOSTNAME="node10"
# Misc
APTITUDE_ARGS="--assume-yes --allow-untrusted"

# Showtime
# Editing anything below might create a time paradox which would
# destroy the very fabric of our reality and maybe hurt kittens.
# Be responsible, please think of the kittens.

aptitude update && aptitude ${APTITUDE_ARGS} install lsb-release

##Accept Java Licence
echo sun-java6-jre shared/accepted-sun-dlj-v1-1 select true | /usr/bin/debconf-set-selections

apt-key adv --recv-keys --keyserver ${KEYSERVER} ${KEY}

#APT configuration
echo "deb http://ftp.fr.debian.org/debian/ $(lsb_release -cs) main non-free" > /etc/apt/sources.list
echo "deb-src http://ftp.fr.debian.org/debian/ $(lsb_release -cs) main non-free" >> /etc/apt/sources.list
echo "deb http://security.debian.org/ $(lsb_release -cs)/updates main" >> /etc/apt/sources.list
echo "deb-src http://security.debian.org/ $(lsb_release -cs)/updates main" >> /etc/apt/sources.list
echo "deb http://ftp.fr.debian.org/debian/ $(lsb_release -cs)-updates main" >> /etc/apt/sources.list
echo "deb-src http://ftp.fr.debian.org/debian/ $(lsb_release -cs)-updates main" >> /etc/apt/sources.list

echo "deb ${RUDDER_REPO_URL} $(lsb_release -cs) main contrib non-free" > /etc/apt/sources.list.d/rudder.list

aptitude update

#Packages minimum
aptitude ${APTITUDE_ARGS} install debian-archive-keyring vim zsh nfs-common
aptitude ${APTITUDE_ARGS} install rudder-server-root

# Allow all connections to LDAP and PostgreSQL
sed -i "s/^IP=.*$/IP=*/" /etc/default/slapd
echo "listen_addresses = '*'" >> /etc/postgresql/8.4/main/postgresql.conf
echo "host    all         all         192.168.42.0/24       trust" >> /etc/postgresql/8.4/main/pg_hba.conf
echo "host    all         all         10.0.0.0/16       trust" >> /etc/postgresql/8.4/main/pg_hba.conf
/etc/init.d/postgresql restart

# Initialize Rudder
/opt/rudder/bin/rudder-init.sh $SERVER_INSTANCE_HOST $DEMOSAMPLE $LDAPRESET $INITPRORESET ${ALLOWEDNETWORK[0]}

sed -i s%^base\.url\=.*%base\.url\=http\:\/\/localhost\:8080\/rudder% /opt/rudder/etc/rudder-web.properties

#we don't want to launch the Rudder Web app, only the endpoint
#so we replace the real Rudder with our fake one, available on share file
#we also have to adapt JVM memory to conform to what the VM has
/etc/init.d/jetty stop 
sed -i -e "s/-Xms1024m -Xmx1024m/-Xms350m -Xmx350m/" /etc/default/jetty
sed -i -e "s/-XX:PermSize=128m -XX:MaxPermSize=256m/-XX:PermSize=70m -XX:MaxPermSize=70m/" /etc/default/jetty
rm /opt/rudder/jetty7/webapps/rudder.war 
cp /vagrant/fakeRudder/fake-rudder-web-2.4.0-SNAPSHOT.war /opt/rudder/jetty7/webapps/rudder.war
/etc/init.d/jetty start

#we want to make sure that people don't look for the bad 
#configuration-repository - the one used is on the host
# -> to start server rudder needs to look for configuration-repository.
#mv /var/rudder/configuration-repository /var/rudder/configuration-repository-not-used-see-host-one

sed -i "s%^127\.0\.1\.1.*%127\.0\.1\.1\tserver\.rudder\.local\tserver%" /etc/hosts

echo "server" > /etc/hostname

hostname server

# node dns configuration
# to add node, add line here
echo -e "\n${NODE1_IP} ${NODE1_HOSTNAME}.rudder.local ${NODE1_HOSTNAME}" >> /etc/hosts

echo '0,5,10,15,20,25,30,35,40,45,50,55 * * * * root if [ `ps -efww | grep cf-execd | grep "/var/rudder/cfengine-community/bin/cf-execd" | grep -v grep | wc -l` -eq 0 ]; then /var/rudder/cfengine-community/bin/cf-execd; fi' >> /etc/crontab

# Set password to default passwords
sed -i "s/\(RUDDER_WEBDAV_PASSWORD:\).*/\1rudder/" /opt/rudder/etc/rudder-passwords.conf
sed -i "s/\(RUDDER_PSQL_PASSWORD:\).*/\1Normation/" /opt/rudder/etc/rudder-passwords.conf
sed -i "s/\(RUDDER_OPENLDAP_BIND_PASSWORD:\).*/\1secret/" /opt/rudder/etc/rudder-passwords.conf

# Run cf-agent to set passwords to default
/var/rudder/cfengine-community/bin/cf-agent

echo "Rudder server install: FINISHED" |tee /tmp/rudder.log

