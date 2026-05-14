#!/bin/bash
set -xeuo pipefail

# Install necessary packages, run scripts, etc.
dnf update -y --setopt=install_weak_deps=False --nodocs && \
dnf -y install --setopt=install_weak_deps=False --nodocs \
    openssh-clients \
    bluez \
    vim vim-enhanced \
    zram-generator \
    zram-generator-defaults \
    xorg-x11-server-Xorg \
    gnome-desktop3 gnome-session-wayland-session adwaita-fonts-all gnome-themes-extra \
    gdm \
    NetworkManager \
    git \
    firefox \
    nautilus \
    gnome-shell-extension-appindicator gnome-shell-extension-dash-to-panel \
    zsh zsh-syntax-highlighting zsh-autosuggestions powerline-fonts \
    loupe \
    htop \
    fastfetch \
    flatpak \
    mesa-va-drivers mesa-vulkan-drivers \
    fedora-release-ostree-desktop \
    terminator


# add gnome system monitor extension
(cd /tmp && git clone https://github.com/michaelknap/gnome-system-monitor-indicator.git && cd gnome-system-monitor-indicator && EXTENSION_PATH="/usr/share/gnome-shell/extensions/system-monitor-indicator@mknap.com" && mkdir -p "$EXTENSION_PATH" && cp -r ./src/* "$EXTENSION_PATH" && glib-compile-schemas "$EXTENSION_PATH/schemas")

# Remove unnecessary packages to reduce image size and attack surface.
dnf remove ntfsprogs ntfs-3g plymouth flashrom at avahi ModemManager
systemctl enable gdm NetworkManager
systemctl disable accounts-daemon mdmonitor
systemctl set-default graphical.target

# install ohmyzsh
(export ZDOTDIR=/etc/skel ZSH=/usr/share/oh-my-zsh && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) "" --unattended")

chsh admin -s /usr/bin/zsh
cat >> /etc/skel/.zshrc <<'EOF'
# Path to your oh-my-zsh installation.
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/oh-my-zsh/oh-my-zsh.sh
fastfetch -c neofetch
EOF

# install icons and themes
(git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon-theme && cd /tmp/WhiteSur-icon-theme && bash install.sh --dest /usr/share/icons)

# set gnome desktop background, theme, extensions and favorites
cat > /etc/dconf/db/local.d/00_background <<'EOF'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/wallpaper.jpg'
picture-uri-dark='file:///usr/share/backgrounds/wallpaper.jpg'
picture-options='zoom'
primary-color='#FFFFFF'
secondary-color='#000000'
EOF

cat > /etc/dconf/db/local.d/00-theme <<'EOF'
[org/gnome/desktop/interface]
gtk-theme='Adwaita-dark'
icon-theme='WhiteSur-dark'
color-scheme='prefer-dark'
document-font-name='Adwaita Sans 11'
font-name='Adwaita Sans 11'
monospace-font-name='Adwaita Mono 11'
show-battery-percentage=true
EOF

cat > /etc/dconf/db/local.d/00-extensions <<'EOF'
[org/gnome/shell]
enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com', 'dash-to-panel@jderose9.github.com', 'system-monitor-indicator@mknap.com']
disable-user-extensions=false

[org/gnome/shell/extensions/system-monitor-indicator]
decimal-places=0

[org/gnome/shell/extensions/dash-to-panel]
panel-position='TOP'
show-apps-icon-file='/usr/share/icons/fedora.png'
preview-use-custom-opactity=true
trans-use-custom-opacity=true
EOF


cat > /etc/dconf/db/local.d/00-favorites <<'EOF'
[org/gnome/shell]
favorite-apps=['org.gnome.Nautilus.desktop', 'org.mozilla.firefox.desktop', 'terminator.desktop']
EOF

dconf update

mkdir -p /var/home
cp -rv /etc/skel /var/home/admin
chown admin:admin /var/home/admin
chown -Rv admin:admin /var/home/admin/

# add zed editor
# dnf install -y --setopt=install_weak_deps=False --nodocs --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
# dnf -y --setopt=install_weak_deps=False --nodocs install zed
# Remove leftover build artifacts from installing packages in the final built image.
dnf clean all
rm /var/{log,cache,lib}/* -rf
rm -rf /run/* /tmp/* /var/tmp/* || true
