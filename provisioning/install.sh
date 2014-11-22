#!/bin/bash

APTGET_UPDATED=0
aptGetUpdate() {
	if [ $APTGET_UPDATED -eq 0 ]; then
		sudo apt-get update	
		APTGET_UPDATED=1
	fi
}

# install wget
if ! command -v wget > /dev/null; then
	aptGetUpdate
	sudo apt-get install -y wget=1.13.4-2ubuntu1.1
fi

# install imagemagick
if ! command -v convert > /dev/null; then
	aptGetUpdate
	sudo apt-get install -y imagemagick=8:6.6.9.7-5ubuntu3.3
fi

# install nvm
if [ ! -d /home/vagrant/.nvm/nvm.sh ]; then 
	sudo su vagrant -c "wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.18.0/install.sh | sh"
	chown vagrant:vagrant /home/vagrant/.nvm
	echo "source ~/.nvm/nvm.sh" >> /home/vagrant/.bashrc
fi
source /home/vagrant/.nvm/nvm.sh

# install nodejs
if ! command -v node > /dev/null; then
	nvm install v0.10.32
	nvm alias default v0.10.32
fi

# install coffee to global
if ! command -v coffee > /dev/null; then
	npm install -g coffee-script@1.7.1
fi

# install the app dependencies
cd /home/vagrant/app
npm install
