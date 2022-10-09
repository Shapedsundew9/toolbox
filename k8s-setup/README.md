### Backgroud
Experimental setup of a K8s cluster comprising of 2 servers running Ubuntu 22.04.
One server is bare metal the other is in a virtualbox VM hosted on an Ubuntu 20.04 system.
#### Installing Kubernetes
Using this guide: https://kubernetes.io/docs/setup/ which directed me through to installing `kubectl`.
#### kubeadm
**kubeadm** needs to be installed on both servers. I did everything in this section on both. The node (control & worker) specific stuff are in separate sections below. Following the guide https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
Open ports aplenty:
```bash
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 2379
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 2380
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 6443
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 10250
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 10259
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 10257
sudo ufw allow from 192.168.100.0/24 proto tcp to any port 30000:32767
```
Need a container runtime, docker needs an extra plugin so want to go with [containerd](https://github.com/containerd/containerd/blob/main/docs/getting-started.md). `sudo apt install containerd runc` does work but the version is quite old. Went with the manual method:
```bash
wget https://github.com/containerd/containerd/releases/download/v1.6.8/containerd-1.6.8-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.6.8-linux-amd64.tar.gz
rm containerd-1.6.8-linux-amd64.tar.gz 
```
Setting up the systemd service
```bash
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /etc/systemd/system/
sudo systemctl enable containerd
sudo systemctl daemon-reload 
sudo systemctl start containerd
sudo journalctl -u containerd
```
OK, we are running. Now for `runc`.
```bash
wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
rm runc.amd64
```
Alright...don't really know what that does but hey-ho.
Finally CNI plugins
```bash
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
rm cni-plugins-linux-amd64-v1.1.1.tgz
```
Now we can do kubeadm which comes with **apt** installation instructions that include kubectl which we installed above!?
```bash
sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
Kublets do not like swap so we need to turn that off
```bash
sudo swapoff -a
```
Also need to set up some forwarding and bridging: See instructions at https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic
```bash
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
```
#### Creating a Cluster
Following these instructions https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
##### The Control Node
I have put the control node on the bare metal Ubuntu 22.04 system. I would recommend appending a `--dry-run` to the command below before doing it for real.
```bash
 sudo kubeadm init
 ```
 That seemed to work - it is moaning about 
 ```
preflight] Running pre-flight checks
	[WARNING SystemVerification]: missing optional cgroups: blkio
```
but searching the documentation for `blkio` comes up with nothing. Googling the pre-flight check warning just finds it in the output of people posting about other issues. Not going to worry for now...:shrug:
##### The Worker Node
Creating the control node gave me a command line to run on my worker to join the cluster. I would recommend appending a `--dry-run` to the command below before doing it for real. With a few deets removed:
```bash
su -
kubeadm join <control_node_ip>:6443 --token <token>  --discovery-token-ca-cert-hash sha256:<sha256>
```
That **did not** work! It just hung there moaning about bklio (see The Control Node section). I suspect network connectivity stuff. This worker is on a VM with a bridged network interface...investigating.