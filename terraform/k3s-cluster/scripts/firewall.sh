#!/bin/bash
set -e
set -o pipefail

# Disable netfilter-persistent firewall
/usr/sbin/netfilter-persistent flush
systemctl stop netfilter-persistent.service
systemctl disable netfilter-persistent.service

# Use ufw for firewall
# https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/#networking
ufw limit ssh
ufw allow 6443/tcp                                            comment "Kubernetes API Server"
ufw allow from 10.0.0.0/24 to any port 10250 proto tcp        comment "Kubelet metrics"
ufw allow from 10.0.0.0/24 to any port 2379:2380 proto tcp    comment "etcd"
ufw enable
