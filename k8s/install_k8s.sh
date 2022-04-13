#!/bin/bash
apt update -y
apt-get install apt-transport-https ca-certificates curl software-properties-common

# install docker
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
# add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
# apt update
# apt-cache policy docker-ce
# apt install -y docker-ce
# systemctl enable docker
apt install -y docker.io

# install k8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get install -y kubeadm kubelet kubectl
apt-mark hold kubeadm kubelet kubectl
kubeadm version
swapoff -a
echo '{"exec-opts": ["native.cgroupdriver=systemd"]}' >> /etc/docker/daemon.json
systemctl restart docker