#!/bin/bash

if [ $(id -u) -ne 0 ]; then
  echo "Please run as root"
  exit 0
fi

#redhat / centos / fedora
if [ -x /usr/bin/lsb_release ]; then
  release="$(/usr/bin/lsb_release -sd)"
fi
if [ -z "$release" -a -e /etc/redhat-release ] ; then
  release=$(sed 's/ /_/g' </etc/redhat-release)
fi
if [ -z "$release" -a -e /etc/debian_version ] ; then
  release="Debian_$(cat /etc/debian_version)"
fi

case "$release" in
  CentOS_release_6*)
    mode=rpm
    key=linux.asc
    repo=http://stable.packages.cloudmonitoring.rackspace.com/centos-6-x86_64
    ;;
  CentOS_release_5*)
    mode=rpm
    key=centos-5.asc
    repo=http://stable.packages.cloudmonitoring.rackspace.com/centos-5-x86_64
    ;;
  Red_Hat_Enterprise_*_release_5*)
    mode=rpm
    key=redhat-5.asc
    repo=http://stable.packages.cloudmonitoring.rackspace.com/redhat-5-x86_64
    ;;
  Red_Hat_Enterprise_*_release_6*)
    mode=rpm
    key=linux.asc
    repo=http://stable.packages.cloudmonitoring.rackspace.com/redhat-6-x86_64
    ;;
  Fedora_release_19*)
    mode=rpm
    key=linux.asc
    repo=http://stable.packages.cloudmonitoring.rackspace.com/fedora-19-x86_64
    ;;
  Debian_7*)
    mode=apt
    key=linux.asc
    repo=http://stable.packages.cloudmonitoring.rackspace.com/debian-wheezy-x86_64
    ;;
  Ubuntu*)
    mode=apt
    key=linux.asc
    repo=http://stable.packages.cloudmonitoring.rackspace.com/ubuntu-$(lsb_release -rs)-$(uname -m)
    ;;
  *) echo "Unsupported OS $release"; exit 1;;
esac

if [ $mode = "rpm" ]; then
  curl https://monitoring.api.rackspacecloud.com/pki/agent/$key > /tmp/signing-key.asc
  rpm --import /tmp/signing-key.asc
  rm /tmp/signing-key.asc
  cat >/etc/yum.repos.d/rackspace-cloud-monitoring.repo <<_EOF
[rackspace]
name=Rackspace Monitoring
baseurl=$repo
enabled=1
_EOF
  yum install rackspace-monitoring-agent
fi

if [ $mode = "apt" ]; then
  echo "deb $repo cloudmonitoring main" >/etc/apt/sources.list.d/rackspace-monitoring-agent.list
  if [ -x /usr/bin/curl ]; then
    curl https://monitoring.api.rackspacecloud.com/pki/agent/$key | sudo apt-key add -
  fi
  if [ ! -x /usr/bin/curl -a -x /usr/bin/wget ]; then
    wget https://monitoring.api.rackspacecloud.com/pki/agent/$key -O - | sudo apt-key add -
  fi
  apt-get update
  apt-get install rackspace-monitoring-agent
fi

rackspace-monitoring-agent --setup
