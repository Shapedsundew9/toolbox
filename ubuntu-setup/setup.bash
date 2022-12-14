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
sudo apt -y install cpu-checker terminator dbus-user-session htop vim git python3.10-venv libgtk-3-dev libcairo2 libcairo2-dev imagemagick htop
sudo apt -y install libpq5=14.5-0ubuntu0.22.04.1 && sudo apt -y install libpq-dev # For psycopg2
sudo apt -y install net-tools pass
sudo apt -y install libgirepository1.0-dev # For python gi

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
  sudo apt -y install python3-graph-tool
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
  echo "See ubuntu_setup.txt in private_scripts repo for how to set up the secure crential store."
fi

echo "Cloning git repos..."
mkdir -p ~/Projects
cd ~/Projects

REPOS="egp-population egp-seed experiments pypgtable egp-physics egp-gp-monitor egp-types toolbox egp-execution private_scripts obscure-password utils egp-stores"
rm -f ~/.bash-ss
touch ~/.bash-ss
echo "export PYTHONPATH=." >> ~/.bashrc
for repo in ${REPOS}; do
  echo "export PYTHONPATH=\${PYTHONPATH}:~/Projects/${repo}" >> ~/.bash-ss
  if [ ! -d ${repo} ]
    then
      git clone git@github.com:Shapedsundew9/${repo}.git
      git checkout Latest
      git pull
    fi
done

# Environment updates
case `grep -Fx commitall ~/.bashrc >/dev/null; echo $?` in
  0)
    echo "~/.bashrc has already been updated...skipping"
    ;;
  1)
    echo "alias commit='find ~/Projects -type d -name \".git\" -execdir git add -u \; -execdir git commit -m \"Latest\" \; -execdir git push \;'" >> ~/.bashrc
    echo "alias commitall='find ~/Projects -type d -name \".git\" -execdir git add -A \; -execdir git commit -m \"Latest\" \; -execdir git push \;'" >> ~/.bashrc
    echo "alias status='find ~/Projects -type d -name \".git\" -execdir git status \;'" >> ~/.bashrc
    echo "source ~/.bash-ss" >> ~/.bashrc
    ;;
  *)
    echo "ERROR: An error occured checking ~/.bashrc. Changes have not been applied."
    ;;
esac

cd ~/Projects
[ ! -d ~/Projects/venv ] && python3 -m venv venv
source ~/Projects/venv/bin/activate

pip3 install pytest numpy tqdm cerberus psycopg2 matplotlib pycairo PyGObject bokeh networkx

# Graph tool is in the distribution site packages
cd ~/Projects/venv/lib/python3.10/site-packages/
echo "/usr/lib/python3/dist-packages" > dist-packages.pth

# Return whence we came
popd

echo "Cleaning up any apt cruft..."
sudo apt -y autoremove
sudo apt -y autoclean
