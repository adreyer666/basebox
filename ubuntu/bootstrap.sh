#!/bin/bash

set -e -x

#---------------------------------

prep_os(){
  apt-get clean
  apt-get remove -y \
    cifs-utils parted hwdata pciutils nfs-common \
    ruby vim-nox hdparm tcpdump \
    ufw firewalld haveged thermald \
    language-selector-common ntfs-3g accountsservice command-not-found friendly-recovery sg3-utils sg3-utils-udev sosreport \
    sound-theme-freedesktop unattended-upgrades usbutils
    # linux-firmware intel-microcode amd64-microcode
  apt-get reinstall -y linux-generic linux-image-generic 
  apt-get autoremove -y --purge
  dpkg --purge `dpkg -l | awk '/^rc/{print $2}'`
  apt-get update
  apt-get upgrade -y
  apt-get install -y \
    tar fuse procps iproute2 iptables nftables lsof psmisc curl ca-certificates sudo vim-tiny openssh-client gnupg2 \
    grub-pc zip zerofree
  # latest=`rpm -q kernel | sed -e 's/^kernel-//g' | sort -t- -k2n | tail -1`
  # /bin/kernel-install add ${latest} /boot/vmlinuz-${latest}.img
  # sync
  # # dnf remove -y  kernel-4.18.0-80.el8.x86_64 kernel-core-4.18.0-80.el8.x86_64 kernel-modules-4.18.0-80.el8.x86_64
  # ls -al /boot/ /boot/loader/entries/
  apt-get clean
  rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/apt/archives/partial
  snap remove lxd
  snap remove core18
  snap remove snapd
  swapoff -av
  rm -f /swap.img
  rootfs=`df --output=source,target / | tail -1|cut -d\  -f1`
  # mount -o remount,ro /
  # zerofree -nv ${rootfs}
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
#boot_to_new_kernel
exit 0

