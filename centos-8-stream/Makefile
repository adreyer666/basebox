#!/usr/bin/env make

BUILD = default
IMAGE = basebox
 DESC = Basebox for vagrant builds

  DIR := $(shell pwd)
 NAME := $(shell basename $(DIR))
 DATE := $(shell date -uI)
   YQ := $(shell which yq)
   XQ := $(shell which xq)
   VM = $(NAME)_$(IMAGE)

build: .build.$(IMAGE)

.build.$(IMAGE): id_rsa.pub
	vagrant up --provider=libvirt 2>&1 | tee make.log \
	  && touch .build.$(IMAGE)
	vagrant ssh-config > ~/.ssh/config.d/vagrant-$(IMAGE).conf

id_rsa.pub:
	ssh-keygen -q -t rsa -b 4096 -f $(DIR)/id_rsa -N ''

run: .build.$(IMAGE)
	ssh -X $(NAME)

.requirements:
	( test "$(YQ)" = '' || test "$(XQ)" = '' ) && python3 -m pip install yq && touch .requirements || :
	test "$(YQ)" != '' && test "$(XQ)" != '' && test \! -f .requirements && touch .requirements

stopvm:
	-virsh destroy $(VM)

tmp/metadata.json: .build.$(IMAGE) .requirements metadata.json.template
	set -x; \
          IMG=`virsh dumpxml $(VM) | xq '.domain.devices.disk.source' | awk -NF\" '/@file/{print $$4}'`; \
          DISK=`virsh  vol-dumpxml --pool default $${IMG} | xq '.volume.capacity' | awk -NF\" '/#text/{print $$4}'`; \
          GB=`expr $${DISK} / 1024 / 1024 / 1024`; \
          mkdir -p $(DIR)/tmp; \
          sed -e "s/@IMAGE@/$(IMAGE)/g" -e "s/@NAME@/$(NAME)/g" \
	      -e "s/@VERSION@/$(DATE)/g" -e "s/@DESC@/$(DESC)/g" \
	      -e "s!@URL@!file://$(DIR)/tmp/$(NAME).box!g" \
	      -e "s/@DISK@/$${GB}/g" \
	    < $(DIR)/metadata.json.template > $(DIR)/tmp/metadata.json;

tmp/Vagrantfile: .build.$(IMAGE) .requirements Vagrantfile.template
	set -x; \
          MEM=`virsh dumpxml $(VM) | xq '.domain.memory' | awk -NF\" '/#text/{print $$4}'`; \
          MB=`expr $${MEM} / 1024`; \
          CPU=`virsh dumpxml $(VM) | xq '.domain.vcpu' | awk -NF\" '/#text/{print $$4}'`; \
          mkdir -p $(DIR)/tmp; \
          sed -e "s/@MEM@/$${MB}/g" -e "s/@VCPU@/$${CPU}/g" < $(DIR)/Vagrantfile.template > $(DIR)/tmp/Vagrantfile;

tmp/$(NAME).box: .build.$(IMAGE) .requirements stopvm tmp/Vagrantfile tmp/metadata.json
	set -x; \
	  IMG=`virsh dumpxml $(VM) | xq '.domain.devices.disk.source' | awk -NF\" '/@file/{print $$4}'`; \
          mkdir -p $(DIR)/tmp; \
	  sudo qemu-img convert -f raw -O qcow2 $${IMG}  $(DIR)/tmp/box.img
	sudo chown `id -u` $(DIR)/tmp/box.img
	(cd $(DIR)/tmp && tar -cvzf $(NAME).box  ./metadata.json ./Vagrantfile ./box.img)
	ls -la tmp/$(NAME).box

box: tmp/$(NAME).box

add: box
	-vagrant box remove $(IMAGE)/$(NAME)
	-#vagrant box add --name $(IMAGE)/$(NAME) --provider libvirt tmp/$(NAME).box
	vagrant box add --name $(IMAGE)/$(NAME) --provider libvirt tmp/metadata.json

stop:
	-vagrant destroy -f

clean: stop
	-rm -f .build.$(IMAGE) .requirements make.log
	-rm -f ~/.ssh/config.d/vagrant-$(IMAGE).conf
	-rm -rf $(DIR)/tmp/

