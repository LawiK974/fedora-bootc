#!/bin/bash
set -xeuo pipefail

# reduce console log verbosity to avoid filling up the journal with non-critical messages.
cat > /etc/sysctl.d/99-sysctl.conf <<'EOF'
kernel.printk = 1 4 1 7
EOF

# Default system language and virtual console keymap to French.
cat >/etc/locale.conf <<'EOF'
LANG=fr_FR.UTF-8
LC_TIME=fr_FR.UTF-8
EOF

cat >/etc/vconsole.conf <<'EOF'
KEYMAP=fr
FONT=eurlatgr
XKBMODEL="pc105"
XKBLAYOUT="fr,us"
XKBVARIANT="latin9,intl"
XKBOPTIONS=""
BACKSPACE=guess
EOF

cp /etc/vconsole.conf /etc/default/keyboard

# Install necessary packages, run scripts, etc.
dnf -y --setopt=install_weak_deps=False --nodocs install \
    python3 \
    rpm-ostree \
    bootupd \
    irqbalance \
    fwupd \
    lvm2 \
    bash-completion \
    glibc-langpack-fr \
    shadow-utils \
    cracklib-dicts \
    logrotate \
    doas

dnf -y remove bluez avahi ntfsprogs ntfs-3g plymouth flashrom at
ln -sf /usr/libexec/bootupd /usr/bin/bootupd
systemctl enable systemd-resolved systemd-timesyncd bootc-fetch-apply-updates.timer
systemctl disable systemd-homed systemd-homed-activate rpmdb-rebuild

cat >/etc/profile.d/99-bash-completion.sh <<'EOF'
# Load bash completion for interactive Bash shells.
if [ -n "$BASH_VERSION" ] && [ -n "$PS1" ] && [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
fi
EOF

cat >> /usr/lib/sysusers.d/admin-user.conf << 'EOF'
#Type Name  ID        GECOS                 Home directory Shell
g     admin 1000
u     admin 1000:1000 "Local Administrator" /home/admin    /bin/bash
#Type User  Group
m     admin wheel
EOF

cat >/usr/lib/tmpfiles.d/admin-home.conf <<'EOF'
#Type Path                  Mode User  Group Age Argument
d     /var/home/admin       0755 admin admin -   -
f     /var/spool/mail/admin 0755 admin admin -   -
EOF

# Create admin user/group now (build time)
systemd-sysusers /usr/lib/sysusers.d/admin-user.conf

# Set password now (build time)
echo 'admin:admin' | chpasswd

# Expire the password to force changing it on first login.
# passwd -e admin
cat >/etc/doas.conf <<'EOF'
permit nopass admin as root
EOF
chmod 0400 /etc/doas.conf

# SELinux mode permissive
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Remove leftover build artifacts from installing packages in the final built image.
dnf clean all
rm /var/{log,cache,lib}/* -rf
rm -rf /run/* /tmp/* /var/tmp/* || true
