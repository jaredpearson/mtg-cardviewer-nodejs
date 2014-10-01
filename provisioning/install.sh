#!/bin/bash

sudo apt-get update
sudo apt-get install -y wget

# install nvm and nodejs
sudo su vagrant -c "wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | sh"
echo "source ~/.nvm/nvm.sh" >> /home/vagrant/.bashrc
source /home/vagrant/.nvm/nvm.sh
nvm install v0.10.32
nvm alias default v0.10.32

chown vagrant:vagrant /home/vagrant/.nvm

# install coffee to global
npm install -g coffee-script@1.7.1

# install the app dependencies
cd /home/vagrant/app
npm install