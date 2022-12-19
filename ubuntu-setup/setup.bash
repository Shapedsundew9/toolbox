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
sudo apt -y install cpu-checker terminator dbus-user-session htop vim git

if [ ! -f /etc/apt/sources.list.d/vscode.list ]
then
  echo "Installing VS code..."
  curl -L https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-archive-keyring.gpg >/dev/null
  sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  sudo apt -y update
  sudo apt -y install code
fi

if [ ! -f /etc/apt/sources.list.d/skewed.list ]
then
  echo "Installing graph-tool..."
  curl "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x612defb798507f25" | sudo gpg --dearmor -o /usr/share/keyrings/skewed.gpg
  sudo sh -c 'echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/skewed.gpg] https://downloads.skewed.de/apt $(lsb_release -cs) main" > /etc/apt/sources.list.d/skewed.list'
  sudo apt -y update
  sudo apt -y python3-graph-tool
fi

if [ ! -f /etc/apt/sources.list.d/pgadmin4.list ]
then
  echo "Installing pgadmin..."
  curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
  sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
  sudo apt -y update
  sudo apt -y install pgadmin4
  sudo apt -y install pgadmin4-web 
fi

if [ ! -f /etc/apt/sources.list.d/docker.list ]
then
  echo "Install docker: https://docs.docker.com/engine/install/ubuntu/"
  sudo apt -y install ca-certificates curl gnupg lsb-release pass uidmap
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
fi

echo "Cloning git repos..."
mkdir -p ~/Projects
cd ~/Projects

REPOS="egp-population egp-seed experiments pypgtable egp-physics egp-gp-monitor egp-types toolbox egp-execution private_scripts obscure-password utils egp-stores"
for repo in ${REPOS}; do
  if [ ! -d ${repo} ]
    then
      git clone git@github.com:Shapedsundew9/${repo}.git
    fi
done

# Return whence we came
popd

echo "Cleaning up any apt cruft..."
sudo apt -y autoremove
sudo apt -y autoclean
