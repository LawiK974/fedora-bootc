# fedora-bootc/server

A Fedora bootc server node with k3s.

## Configuration

1. Put your api server vip or first node ip in `/etc/systemd/system/k3s.service.env` for every node.

```sh
K3S_MODE="server" # change to "agent" on agent nodes
K3S_SERVER_IP="192.168.122.100"  # this is an example : change IP to your api server vip or first node ip
# K3S_ADDITIONAL_OPTS="--cluster-init" # only on the first node
K3S_TOKEN="changeme" # change to a secure token shared by all nodes
```

2. Adapt IP in `/var/lib/k3s/server/manifests/kube-vip-ds.yaml`

```sh
sed -i 's/192.168.122.100/<MY_IP>/g' /var/lib/k3s/server/manifests/kube-vip-ds.yaml
```

3. start k3s on every node:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now k3s
```
