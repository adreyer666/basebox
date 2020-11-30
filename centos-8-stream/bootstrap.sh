#!/bin/bash

set -e -x

#---------------------------------

prep_os(){
  dnf -y install 'dnf-command(config-manager)'  centos-release-stream
  dnf clean all
  dnf config-manager --disable 'BaseOS'
  dnf config-manager --disable 'AppStream'
  dnf config-manager --disable 'extras'
  dnf -y upgrade
  dnf remove -y  \
    cronie-anacron cronie crontabs \
    man-pages man-db geolite2-city geolite2-country \
    cifs-utils samba-common samba-common-libs samba-client-libs cups-libs mozjs52 \
    python3-dnf-plugin-spacewalk python3-rhn-client-tools python3-rhnlib rhn-client-tools \
    elfutils-debuginfod-client parted hwdata iprutils pciutils sg3_utils sg3_utils-libs \
    xkeyboard-config hyperv-daemons
  dnf -y install \
    tar fuse procps iproute iptables nftables lsof psmisc curl ca-certificates sudo vim-minimal openssh-clients gnupg2
  # dnf remove -y  kernel-4.18.0-80.el8.x86_64 kernel-core-4.18.0-80.el8.x86_64 kernel-modules-4.18.0-80.el8.x86_64
  dnf remove -y firewalld-filesystem   ## removes all firewall..
  dnf clean all
  rm -rf /var/log/anaconda/ /var/cache/man/ /var/cache/dnf/ /var/lib/sss/db/*
}

user_setup(){
  export PATH=$PATH:/usr/local/bin
  echo 'PATH=$PATH:/usr/local/bin; export PATH' | sudo tee -a .profile
  if test -d /home/deploy;
    then groupmod -g 500 deploy
         usermod -u 500 -g 500 deploy
         chown -R deploy: /home/deploy /var/spool/mail/deploy
    else groupadd -g 500 deploy
         useradd -m -u 500 -g 500 -d /home/deploy deploy
  fi
  echo 'deploy ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/deploy
  mkdir -p /home/deploy/.ssh
  chmod 0700 /home/deploy/.ssh
  cat /vagrant/id_rsa.pub >> /home/deploy/.ssh/authorized_keys
  chmod 0600 /home/deploy/.ssh/authorized_keys
  chown -R deploy: /home/deploy/.ssh
}

add_builder(){
  dnf -y install gcc build-essential linux-headers-server
  rm -f /etc/udev/rules.d/70-persistent.net
}

#---------------------------------

prep_os
user_setup
#add_builder
exit 0

