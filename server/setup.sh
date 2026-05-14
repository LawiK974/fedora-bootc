#!/bin/bash
set -xeuo pipefail

# Install necessary packages, run scripts, etc.
dnf update -y --setopt=install_weak_deps=False --nodocs && \
dnf -y install --setopt=install_weak_deps=False --nodocs \
    openssh-server \
    systemd-networkd \
    dhcp-client
dnf remove ntfsprogs ntfs-3g plymouth flashrom at avahi ModemManager
systemctl enable systemd-networkd
systemctl disable accounts-daemon mdmonitor


# Configure systemd-networkd to use DHCP on all wired interfaces.
cat > /etc/systemd/network/20-wired.network <<'EOF'
[Match]
Name=en*

[Link]
RequiredForOnline=routable

[Network]
DHCP=yes
EOF

cat > /etc/sysctl.d/99-k3s.conf <<'EOF'
vm.panic_on_oom=0
vm.overcommit_memory=1
kernel.panic=10
kernel.panic_on_oops=1
EOF

sysctl -p /etc/sysctl.d/99-k3s.conf

curl -Lo /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/v1.36.0+k3s1/k3s
chmod a+x /usr/local/bin/k3s

# Remove leftover build artifacts from installing packages in the final built image.
dnf clean all
rm /var/{log,cache,lib}/* -rf
rm -rf /run/* /tmp/* /var/tmp/* || true
