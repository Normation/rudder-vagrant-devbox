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

SERVER_IP="192.168.42.80"
NODE_HOSTNAME="node1"
NODE_IP="192.168.42.81"

# Misc
APTITUDE_ARGS="--assume-yes --allow-untrusted"


# Showtime
# Editing anything below might create a time paradox which would
# destroy the very fabric of our reality and maybe hurt kittens.
# Be responsible, please think of the kittens.

aptitude update && aptitude ${APTITUDE_ARGS} install lsb-release

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
aptitude ${APTITUDE_ARGS} install debian-archive-keyring

aptitude ${APTITUDE_ARGS} install rudder-agent

sed -i "s%^127\.0\.1\.1.*%127\.0\.1\.1\t${NODE_HOSTNAME}\.rudder\.local\t${NODE_HOSTNAME}%" /etc/hosts

echo "${NODE_HOSTNAME}" > /etc/hostname

hostname ${NODE_HOSTNAME}

echo -e "\n${SERVER_IP}	server.rudder.local" >> /etc/hosts

echo "${SERVER_IP}" > /var/rudder/cfengine-community/policy_server.dat

echo '0,5,10,15,20,25,30,35,40,45,50,55 * * * * root if [ `ps -efww | grep cf-execd | grep "/var/rudder/cfengine-community/bin/cf-execd" | grep -v grep | wc -l` -eq 0 ]; then /var/rudder/cfengine-community/bin/cf-execd; fi' >> /etc/crontab

# Fusion inventory, add it if Fusion inventory is not working in Rudder

# prepare cpan
#export PERL_MM_USE_DEFAULT=1 cpan
#cp /vagrant/FusionInventory/Config.pm /etc/perl/CPAN

#cpanm is faster than cpan
#cpan -f -i App::cpanminus
#install with cpanm, loooots of dependencies
#cpanm -n FUSINV/FusionInventory-Agent-2.2.2.tar.gz
# A dependency in fusion prevents its installation even if we don't need it, force installation
#cpan -f FUSINV/FusionInventory-Agent-2.2.2.tar.gz

#change run-inventory to run our specific version
#sed -i 's/.*fusioninventory.*/fusioninventory-agent "$@"/' /opt/rudder/bin/run-inventory

echo "Rudder node install: FINISHED" |tee /tmp/rudder.log
