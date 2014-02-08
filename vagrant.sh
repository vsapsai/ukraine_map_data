#!/bin/bash --login
# --login argument is required by rvm use

# Install necessary tools.
sudo apt-get update

# GDAL
sudo apt-get install -y gdal-bin

# node.js
# vsapsai: Cannot install with 'sudo apt-get install -y nodejs' because
# standard repository has old Node version (at the time of writing v0.6.12
# while the released version is v0.10.25).
#
# TODO(vsapsai): review it after Ubuntu 14.04 release.
sudo apt-get install -y python-software-properties python g++ make
sudo add-apt-repository ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install -y nodejs

# topojson
sudo npm install -g topojson

# curl
sudo apt-get install -y curl

# rvm
RVM_DIR="/usr/local/rvm"
if [ ! -e "$RVM_DIR" ] ; then
  curl -L https://get.rvm.io | bash -s stable --ruby --autolibs=packages
  source "$RVM_DIR/scripts/rvm"
fi

# ruby
rvm install 2.1.0 --autolibs=packages
rvm use 2.1.0

# rake
gem install rake
