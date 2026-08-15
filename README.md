# Dotfiles — Debian 13 + Sway (Ozean-Theme)

Komplettes Desktop-Setup: Sway, Waybar, kitty, fuzzel, mako, gammastep,
GTK-Theming (Arc-Dark + Ozean-CSS), eigene Menü-Skripte (WLAN, Bluetooth,
Power, Nachtlicht) und Bash-Prompt.
Verwaltung per GNU stow (Symlinks), Wiederaufbau per install.sh.
Getestet auf zwei Maschinen: ThinkPad (Intel) und Desktop-PC (NVIDIA, Dual-Boot).

## Neuinstallation (frisches System -> fertiger Desktop)

### 1. Debian 13 installieren (netinst)
- Root-Passwort LEER lassen (Benutzer bekommt sudo)
- Partitionierung: "Gefuehrt - gesamte Platte mit verschluesseltem LVM"
- Software-Auswahl: alles abwaehlen, NUR "Standard-Systemwerkzeuge"

### 2. Paketquellen (einmalig, vor allem anderen)
Nach dem ersten Login im tty:

    sudo nano /etc/apt/sources.list

Alle drei deb-Zeilen muessen enden auf:
main contrib non-free non-free-firmware

Backports aktivieren:

    echo "deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/backports.list

Falls WLAN bei der Installation eingerichtet wurde: die wlp-Zeilen in
/etc/network/interfaces auskommentieren (sonst bleibt das Geraet fuer
NetworkManager "unmanaged"). Nur lo-Zeilen bleiben aktiv.

### 3. Repo holen und installieren

Das Repo ist privat. Auf einem frischen Debian gibt es aber noch keinen
Browser fuer die GitHub-Anmeldung (gh/Token) und auch noch keinen SSH-Key.
Einfachster Weg fuer den Erst-Klon: das Repo auf GitHub kurz auf **public**
stellen (Repo -> Settings -> Danger Zone -> Change visibility -> Make public),
dann klonen. Nach der Installation wieder auf **private** schalten.

    sudo apt update && sudo apt install -y git
    git clone https://github.com/janbah/dotfiles.git ~/dotfiles
    ~/dotfiles/install.sh

Achtung Reihenfolge: erst public schalten, DANN klonen — sonst laeuft der
Klon in eine Auth-Abfrage. Nach install.sh (Browser ist jetzt da) das Repo
wieder auf **private** setzen und die Git-Anmeldung einrichten (siehe
"Nacharbeiten"). Hinweis: Waehrend des public-Fensters sind Commit-Mail und
Gammastep-Koordinaten oeffentlich sichtbar.

### 4. Neu starten
Nach Reboot: LUKS-Passphrase -> tty-Login -> Sway startet automatisch
(via .profile). WLAN ueber das Icon in der Waybar verbinden.

### 5. Nacharbeiten (nicht im Repo, bewusst)

**SSH-Key + Git-Remote:**

Key aus dem Backup zurueckspielen (nicht neu erzeugen):

    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    cp /pfad/zum/backup/id_ed25519{,.pub} ~/.ssh/
    chmod 600 ~/.ssh/id_ed25519 && chmod 644 ~/.ssh/id_ed25519.pub

    git -C ~/dotfiles remote set-url origin git@github.com:janbah/dotfiles.git

Alternativ ohne SSH-Key, per Browser-Login (Passwort + OTP): `sudo apt install gh`
und `gh auth login` (GitHub.com -> HTTPS -> im Browser bestaetigen). Richtet die
HTTPS-Anmeldung fuers private Repo ein; die Remote kann dann auf https bleiben.

**Keyring automatisch entsperren (PAM):** In /etc/pam.d/login ergaenzen —
unter den auth-Zeilen:

    auth       optional     pam_gnome_keyring.so

ans Ende der session-Zeilen:

    session    optional     pam_gnome_keyring.so auto_start

(Voraussetzung: Keyring-Passwort = Login-Passwort.)

**Konten & Daten:**
- Nextcloud-Konto verbinden; Ordner-Sync `Obsidian` (Server) ->
  `~/Documents/Obsidian` (lokal) als eigene Sync-Verbindung anlegen
- Thunderbird-Konten einrichten
- KeePassXC-Datenbank aus Backup/Nextcloud zurueckspielen
- Firefox: Dark-Theme aktivieren; Erweiterung "Firefox Color" mit
  Ozean-Palette: Hintergruende #0b1d2e / #1b3a57, Text #e8f1f8,
  Akzent #7fb4d9

**Weitere Software (Fremdquellen mit beweglichen URLs):**
- Proton VPN: Repo-Paket von https://protonvpn.com/support/linux
  herunterladen, dann `sudo apt install proton-vpn-gnome-desktop`
- Claude Code: Installation laut https://docs.claude.com
- Claude Desktop: QUELLE HIER EINTRAGEN (TODO)

**Firmware pruefen:**

    sudo fwupdmgr refresh && sudo fwupdmgr get-updates

## NVIDIA-Rechner (z. B. Desktop-PC mit RTX 4060)

Ohne diese Schritte laeuft Sway auf nouveau -> zufaellige Session-Abstuerze.

1. Treiber + Header (Header sind Pflicht, sonst baut DKMS kein Modul):

       sudo apt install nvidia-driver firmware-misc-nonfree linux-headers-amd64

2. Kernel-Modesetting (ohne das startet kein Wayland-Compositor auf NVIDIA):

       echo 'options nvidia-drm modeset=1' | sudo tee /etc/modprobe.d/nvidia-kms.conf
       sudo update-initramfs -u

3. Secure Boot: muss AUS sein (BIOS), sonst laedt das unsignierte Modul nicht.
   Pruefen: `mokutil --sb-state`

4. Sway-Flag: in ~/.profile heisst die Zeile `exec sway --unsupported-gpu`
   (im Repo bereits enthalten; schadet Intel/AMD-Rechnern nicht).

5. Nach Reboot pruefen:

       lsmod | grep nvidia                                  # Module geladen
       cat /sys/module/nvidia_drm/parameters/modeset        # muss Y zeigen

Bei zwei GPUs (iGPU + dedizierte): Monitor an die dedizierte Karte;
falls Sway auf der falschen Karte startet, iGPU im BIOS deaktivieren.

## Dual-Boot mit Windows

- Windows-Updates setzen die UEFI-Bootreihenfolge gern zurueck (PC bootet
  ploetzlich nur noch Windows). Fix: Boot-Menue der Firmware (F12/F11/Esc)
  -> debian booten, dann:

      sudo efibootmgr                    # Reihenfolge ansehen
      sudo efibootmgr -o XXXX,YYYY       # debian-Eintrag nach vorn

- Windows im GRUB-Menue anzeigen: in /etc/default/grub die Zeile
  `GRUB_DISABLE_OS_PROBER=false` setzen, dann `sudo update-grub`.

## Zwei-Konten-Setup (admin + janbah)

1. Installer legt "admin" an (bekommt sudo durch leeres Root-Passwort)
2. Als admin: Paketquellen-Vorarbeit, dann `sudo adduser janbah` und
   voruebergehend `sudo usermod -aG sudo janbah`
3. Als janbah (neu einloggen!): Repo klonen, install.sh ausfuehren
4. Als admin: `sudo deluser janbah sudo` — ab dann Systempflege via `su - admin`

## Pflege

- Config aendern = Datei in ~/dotfiles aendern (Symlinks zeigen dorthin)
- Danach: `git add -u && git commit -m "..." && git push`
- Auf der anderen Maschine: `git pull` (und bei neuen Paketen `stow <paket>`)
- Neue Software IMMER in install.sh eintragen (apt-Block bzw. Flatpak-Zeile)
- Audit alle paar Monate: `apt-mark showmanual` und `flatpak list --app`
  gegen install.sh abgleichen
- Neues Config-Paket: Ordnerstruktur wie bestehende (paket/.config/...),
  Datei per mv hinein, dann `cd ~/dotfiles && stow paket`

## Struktur

    bash/       .bashrc (Ozean-Prompt), .profile (Sway-Autostart, NVIDIA-Flag)
    fuzzel/     Launcher
    gtk/        GTK3/GTK4-CSS (Ozean-Override fuer Arc-Dark)
    kitty/      Terminal
    mako/       Notifications
    scripts/    wifimenu, btmenu, powermenu, gammastep-toggle (~/.local/bin)
    sway/       Window Manager (Keybindings, Autostart, Optik)
    wallpapers/ ocean_with_cloud.png
    waybar/     Statusleiste (config.jsonc + style.css)
    install.sh  Komplett-Installation auf frischem Debian 13

## Ozean-Palette (Referenz)

    Tiefsee   #0b1d2e     Meerblau  #1b3a57     Hellblau  #7fb4d9
    Schaum    #e8f1f8     Warngelb  #f5c97b     Koralle   #e06c75
    Gruen     #98c379     Cyan      #56b6c2
