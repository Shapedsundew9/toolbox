#!/bin/bash
# Install all the stuff
set -e

echo "Enter sudo password if prompted."
sudo echo "sudoing..."
pushd .
cd ~

echo "Getting everything up to date before we start..."
sudo apt -y update
sudo apt -y upgrade

echo "Installing useful tools..."
sudo apt -y install cpu-checker terminator pass uidmap dbus-user-session

echo "Install docker: https://docs.docker.com/engine/install/ubuntu/"
sudo apt -y install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt -y update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable containerd.service
cat << EOF | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5",
    "compress": "true"
  }
}
EOF
dockerd-rootless-setuptool.sh install
echo "export DOCKER_HOST=unix:///run/user/1000/docker.sock" >> ~/.bashrc
systemctl --user enable docker
sudo loginctl enable-linger $(whoami)
echo "Setting up docker credentials: https://www.techrepublic.com/article/how-to-setup-secure-credential-storage-for-docker/"
wget https://github.com/docker/docker-credential-helpers/releases/download/v0.7.0/docker-credential-pass-v0.7.0.linux-amd64
chmod a+x docker-credential-pass-v0.7.0.linux-amd64
sudo mv docker-credential-pass-v0.7.0.linux-amd64 /usr/bin/docker-credential-pass


echo "Cleaning up any apt cruft..."
sudo apt -y autoremove
sudo apt -y autoclean
