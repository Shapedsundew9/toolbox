### Backgroud
Experimental setup of a K8s cluster comprising of 2 servers running Ubuntu 22.04.
One server is bare metal the other is in a virtualbox VM hosted on an Ubuntu 20.04 system.
Servers have an OpenVPN mesh network (I know 2 is hardly a mesh but it is configured that way for expansion) IP range 10.179.38.0/8
#### Installing Kubernetes
Using this guide: https://kubernetes.io/docs/setup/ which directed me through to installing `kubectl`.
#### kubectl
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/ using the curl method.
```bash
sudo apt install curl
```
:neutral_face:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
```
`OK` - good so far. Continuing...
```bash
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```
Client Version: version.Info{Major:"1", Minor:"25", GitVersion:"v1.25.2", GitCommit:"5835544ca568b757a8ecae5c153f317e5736700e", GitTreeState:"clean", BuildDate:"2022-09-21T14:33:49Z", GoVersion:"go1.19.1", Compiler:"gc", Platform:"linux/amd64"}
Kustomize Version: v4.5.7
```
Peachy.
```bash
kubectl cluster-info
```
```
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```
Less peachy!. Turns out you need a running cluster first. I chose kubeadm.
#### kubeadm
Following the guide https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
First flag is the need for a MAC address (I assume link layer address) - my VPN does not have one of those...


