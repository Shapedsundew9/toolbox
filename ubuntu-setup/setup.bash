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
sudo apt -y install cpu-checker terminator dbus-user-session htop vim git python3.11-venv libgtk-3-dev libcairo2 libcairo2-dev imagemagick htop wget curl
sudo apt -y install libpq5 && sudo apt -y install libpq-dev # For psycopg2
sudo apt -y install net-tools pass
sudo apt -y install libgirepository1.0-dev # For python gi

echo "Configuring terminator..."
cat << EOF | tee /home/shapedsundew9/.config/terminator/config
[global_config]
[keybindings]
[profiles]
  [[default]]
    cursor_color = "#aaaaaa"
    scrollback_lines = 50000
[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = ""
    [[[child1]]]
      type = Terminal
      parent = window0
[plugins]
EOF

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

REPOS="egp-population egp-seed experiments pypgtable egp-physics egp-gp-monitor egp-types toolbox egp-execution private_scripts obscure-password egp-utils egp-stores egp-worker egp-containers egp-execution"
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

# Python 3.11
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y python3.11
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
sudo apt install -y python3.11-dev python3.11-venv python3.11-distutils python3.11-gdbm python3.11-tk python3.11-lib2to3

# Environment updates
case `grep -Fx commitall ~/.bashrc >/dev/null; echo $?` in
  0)
    echo "~/.bashrc has already been updated...skipping"
    ;;
  1)
    echo "alias commit='find ~/Projects -type d -name \".git\" -execdir git add -u \; -execdir git commit -m \"Latest\" \; -execdir git push \;'" >> ~/.bashrc
    echo "alias commitall='find ~/Projects -type d -name \".git\" -execdir git add -A \; -execdir git commit -m \"Latest\" \; -execdir git push \;'" >> ~/.bashrc
    echo "alias status='find ~/Projects -type d -name \".git\" -execdir git status \;'" >> ~/.bashrc
    echo "alias push='find ~/Projects -type d -name \".git\" -execdir git push \;'" >> ~/.bashrc
    echo "alias pull='find ~/Projects -type d -name \".git\" -execdir git pull \;'" >> ~/.bashrc
    echo "source ~/.bash-ss" >> ~/.bashrc
    ;;
  *)
    echo "ERROR: An error occured checking ~/.bashrc. Changes have not been applied."
    ;;
esac

cd ~/Projects
mkdir scratch
[ ! -d ~/Projects/.venv ] && python3 -m venv .venv
source ~/Projects/.venv/bin/activate

pip3 install pytest numpy tqdm cerberus psycopg2 matplotlib pycairo PyGObject bokeh networkx pympler scipy exrex

# Get latest boost
sudo apt install -y autotools-dev automake libcgal-dev libboost-all-dev libsparsehash-dev libgtk-3-dev libcairomm-1.0-dev libcairo2-dev pkg-config python3.11-dev python3-matplotlib
cd ~/downloads
wget https://boostorg.jfrog.io/artifactory/main/release/1.81.0/source/boost_1_81_0.tar.gz
tar -xvf boost_1_81_0.tar.gz
cd boost_1_81_0
./bootstrap.sh --prefix=/usr/ --with-python=python3.11
sudo CPLUS_INCLUDE_PATH=/usr/include/python3.11 ./b2 install

# Get the latest graph-tool (Need 13 GB RAM including swap minimum for -j 3)
mkdir -p ~/3rd-Party-Projects
cd ~/3rd-Party-Projects
export CXXFLAGS=-O3
git clone https://git.skewed.de/count0/graph-tool.git
cd graph-tool
./autogen.sh
./configure --with-python-module-path=$HOME/Projects/venv/lib/python3.11/site-packages --prefix=$HOME/.local
make install -j 3

# Not needed with local build of graph-tool.
# cd ~/Projects/.venv/lib/python3.11/site-packages/
# echo "/usr/lib/python3/dist-packages" > dist-packages.pth


# Return whence we came
popd

echo "Cleaning up any apt cruft..."
sudo apt -y autoremove
sudo apt -y autoclean

echo "MANUAL settings"
echo "==============="
echo ""
echo "1. VScode: Add pylance plugin."
echo "2. VScode enable pylint."
echo "3. VScode enable document formatting."
echo "4. Patch exrex.py as needed (see comments here)."
# Replace
#     from re import sre_parse
# with:
#   try:
#     import re._parser as sre_parse
#   except ImportError: # Python < 3.11
#     from re import sre_parse
