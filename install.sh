#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

echo "==> Pakete installieren"
sudo apt update
sudo apt install -y sway swaylock swayidle swaybg waybar fuzzel kitty \
  mako-notifier libnotify-bin network-manager-gnome pipewire-audio \
  pipewire-pulse wireplumber pulseaudio-utils pavucontrol brightnessctl \
  grim slurp swappy wl-clipboard xdg-desktop-portal-wlr xwayland \
  lxappearance papirus-icon-theme fonts-jetbrains-mono fonts-font-awesome \
  fonts-noto-color-emoji thunar udiskie mate-polkit polkitd xdg-user-dirs \
  bluez gammastep firefox-esr flatpak unzip stow git \
  unattended-upgrades intel-microcode fwupd \
  bat btop htop fzf fd-find ripgrep jq tmux tree curl wget zip \
  build-essential thunar-archive-plugin tumbler xdg-desktop-portal-gtk gpg \
  libpam-gnome-keyring gnome-keyring \
  arc-theme breeze-icon-theme fonts-inter v4l-utils lsof memtester \
  libspa-0.2-bluetooth python3-venv chromium

echo "==> VS Code (Microsoft apt-Repo)"
if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
fi
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
fi
sudo apt update
sudo apt install -y code

echo "==> .NET SDK 10 (Microsoft-Feed)"
if ! dpkg -l dotnet-sdk-10.0 >/dev/null 2>&1; then
  wget -qO /tmp/ms-prod.deb https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb
  sudo dpkg -i /tmp/ms-prod.deb
  rm /tmp/ms-prod.deb
  sudo apt update
  sudo apt install -y dotnet-sdk-10.0
fi

echo "==> Docker (Debian-Repo)"
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
# Nutzer in docker-Gruppe -> docker ohne sudo (erst nach Neu-Login wirksam)
sudo usermod -aG docker "$USER"

echo "==> Tailscale (offizielles apt-Repo, Debian 13 = trixie)"
if [ ! -f /usr/share/keyrings/tailscale-archive-keyring.gpg ]; then
  sudo mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
fi
if [ ! -f /etc/apt/sources.list.d/tailscale.list ]; then
  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
fi
sudo apt update
sudo apt install -y tailscale
# Anmeldung erst danach manuell (interaktiv): sudo tailscale up  (siehe README)

echo "==> Google Chrome"
if ! dpkg -l google-chrome-stable >/dev/null 2>&1; then
  wget -qO /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y /tmp/chrome.deb
  rm /tmp/chrome.deb
fi

echo "==> GitKraken (offizielles .deb)"
if ! dpkg -l gitkraken >/dev/null 2>&1; then
  wget -qO /tmp/gitkraken.deb https://release.gitkraken.com/linux/gitkraken-amd64.deb
  sudo apt install -y /tmp/gitkraken.deb
  rm /tmp/gitkraken.deb
fi

echo "==> Nerd Font"
if [ ! -d "$HOME/.local/share/fonts/JetBrainsMonoNerd" ]; then
  mkdir -p "$HOME/.local/share/fonts"
  wget -qO /tmp/JBM.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -oq /tmp/JBM.zip -d "$HOME/.local/share/fonts/JetBrainsMonoNerd"
  rm /tmp/JBM.zip
  fc-cache -f
fi

echo "==> Flathub"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "==> Anwendungen (apt)"
sudo apt install -y thunderbird keepassxc

echo "==> Anwendungen (Flatpak)"
flatpak install -y flathub md.obsidian.Obsidian com.nextcloud.desktopclient.nextcloud net.ankiweb.Anki com.slack.Slack com.usebruno.Bruno

echo "==> GTK-Theme"
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface font-name "Inter 10"

echo "==> Unattended Upgrades aktivieren"
printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";\n' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null

echo "==> Vorhandene Dateien sichern, Symlinks setzen"
for f in "$HOME/.bashrc" "$HOME/.profile"; do
  [ -f "$f" ] && [ ! -L "$f" ] && mv "$f" "$f.bak"
done
stow sway waybar kitty fuzzel mako scripts bash wallpapers gtk
xdg-user-dirs-update

echo "==> Fertig. Abmelden und neu einloggen."
