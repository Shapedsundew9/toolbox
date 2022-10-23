#!/bin/bash
# Install all the stuff

echo "Enter sudo password if prompted."
sudo echo "sudoing..."
pushd .
cd ~

echo "Getting everything up to date before we start..."
sudo apt -y update
sudo apt -y upgrade

echo "Cleaning up any apt cruft..."
sudo apt -y autoremove
sudo apt -y autoclean
