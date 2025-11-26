#!/bin/bash
set -e
set -o pipefail

echo "Pls don't crash!!!"

log () {
    echo -e "\n>>> $1\n"
}

# Atualizar sistema
log "Updating Windows 11."
sudo dnf update -y

# Repositório com arquivos adicionais para o Hyprland e RPM Fusion
log "Addictional repo, i don't use Arch btw!"
sudo dnf copr enable solopasha/hyprland -y
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

# Ainda é RPM Fusion, agora os codecs
log "Midia and Codecs"
sudo dnf group install multimedia -y
sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf install ffmpeg-libs libva libva-utils -y
sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y

# Flathub não vem por padrão, então é necessário configurar
log "Flathub"
sudo dnf install flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Instalar fontes, ainda falta as Nerd, mas btw, depois procuro
log "Fonts"
sudo dnf install -y dejavu-fonts-all google-noto-sans* google-noto-serif* google-noto-mono* google-noto-sans-cjk* google-noto-serif-cjk* fira-code-fonts jetbrains-mono-fonts google-noto-emoji-color-fonts curl cabextract xorg-x11-font-utils fontconfig && sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcorefonts-2.6-1.noarch.rpm && sudo fc-cache -fv

# Agora, finalmente os apps junto com o Hyprland.
log "Instalar Hyprland bucha e uns apps."
sudo dnf install -y \
    hyprland \
    wofi \
    hyprshot \
    steam \
    vlc \
    pavucontrol \
    ddcutil \
    wget \
    unzip \
    mako \
    hyprpolkitagent \
    glibc-langpack-pt \
    

    

echo "Do the L"
