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
  dnf remove -y firewalld-filesystem   ## removes all firewall..
  dnf -y reinstall kernel kernel-modules kernel-core
  latest=`rpm -q kernel | sed -e 's/^kernel-//g' | sort -t- -k2n | tail -1`
  /bin/kernel-install add ${latest} /boot/vmlinuz-${latest}.img
  sync
  # dnf remove -y  kernel-4.18.0-80.el8.x86_64 kernel-core-4.18.0-80.el8.x86_64 kernel-modules-4.18.0-80.el8.x86_64
  ls -al /boot/ /boot/loader/entries/
  dnf clean all
  rm -rf /var/log/anaconda/ /var/cache/man/ /var/cache/dnf/ /var/lib/sss/db/*
}

user_setup(){
  export PATH=$PATH:/usr/local/bin
  echo 'PATH=$PATH:/usr/local/bin; export PATH' > ${HOME}/.profile
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

reset_for_vagrant(){
  # dnf -y install gcc build-essential linux-headers-server
  chmod 0700 /home/vagrant/.ssh
  echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant
  curl -skL https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > /home/vagrant/.ssh/vagrant.pub
  cat /home/vagrant/.ssh/vagrant.pub > /home/vagrant/.ssh/authorized_keys
  chmod 0600 /home/vagrant/.ssh/authorized_keys
  cat /home/vagrant/.ssh/authorized_keys
  rm -f /etc/udev/rules.d/70-persistent.net
  sync; sync; sync;
}

boot_to_new_kernel(){
  running=`uname -r`
  latest=`rpm -q kernel | sed -e 's/^kernel-//g' | sort -t- -k2n | tail -1`
  test "${running}" = "${latest}" && return
  test -s "/boot/vmlinuz-${latest}" \
    && test -s "/boot/initramfs-${latest}.img" \
    && sync \
    && kexec --reuse-cmdline --initrd="/boot/initramfs-${latest}.img" "/boot/vmlinuz-${latest}"
}

#---------------------------------

prep_os
user_setup
reset_for_vagrant
boot_to_new_kernel
exit 0

