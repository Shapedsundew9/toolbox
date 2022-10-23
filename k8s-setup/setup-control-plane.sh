#!/bin/bash
# Takes 0 or >0 arguments
# If there is >0 arguments a control node will be created

ARCH=`dpkg --print-architecture`
CONTAINERD_VERSION="1.6.8"
RUNC_VERSION="1.1.4"
CALICO_VERSION="3.24.1"
CNI_VERSION="1.1.1"
HELM_VERSION="3.10.1"
K9S_VERSION="0.26.7"

# This is because k9s is not consistent with the use of architecture and platform in the package naming.
if [ "${ARCH}" == "amd64" ]; then
  PLATFORM="x86_64"
else
  PLATFORM="arm64"
fi

echo "Enter sudo password if prompted."
sudo echo "sudoing..."
pushd .
cd ~

echo "Getting everything up to date before we start..."
sudo apt -y update
sudo apt -y upgrade

echo "Platform architecture is ${ARCH}"
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 2379
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 2380
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 6443
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 10250
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 10259
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 10257
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 30000:32767
sudo ufw enable

echo "Install containerd..."
wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
sudo tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
rm containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir /etc/containerd
sudo containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
sudo mv containerd.service /etc/systemd/system/
sudo systemctl enable containerd
sudo systemctl daemon-reload 
sudo systemctl start containerd

echo "Install runc..."
wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.${ARCH}
sudo install -m 755 runc.${ARCH} /usr/local/sbin/runc
rm runc.${ARCH}

echo "Installing CNI..."
wget https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${ARCH}-v${CNI_VERSION}.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-arm64-v${CNI_VERSION}.tgz
rm cni-plugins-linux-${ARCH}-v${CNI_VERSION}.tgz

echo "Turning swap off..."
sudo swapoff -a

echo "Setting up forwarding IPv4 and letting iptables see bridged traffic..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

echo "Install Kubernetes..."
# kubeadm config print init-defaults --component-configs KubeletConfiguration
sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

if [ ${#} -gt 0 ]; then
  echo "Making this node the control node..."
  sudo kubeadm init --pod-network-cidr=10.157.0.0/16
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  echo "Install Helm..."
  wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz
  tar -zxvf helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz
  sudo mv linux-${ARCH}/helm /usr/local/bin/helm
  rm -rf linux-${ARCH}

  echo "Install Calico..."
  kubectl create namespace tigera-operator
  helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
  helm install calico projectcalico/tigera-operator --version v${CALICO_VERSION} --namespace tigera-operator

  echo "Install k9s..."
  wget https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${PLATFORM}.tar.gz
  tar -zxvf k9s_Linux_${PLATFORM}.tar.gz
  sudo mv k9s /usr/local/bin/
  rm -f LICENSE README.md k9s_Linux_${PLATFORM}.tar.gz
else
  echo "Worker node created."
  echo "Now run the join command."
fi

echo "Cleaning up any apt cruft..."
sudo apt -y autoremove
sudo apt -y autoclean

popd
echo "Done!"
