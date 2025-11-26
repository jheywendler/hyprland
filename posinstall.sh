#!/bin/bash
set -euo pipefail

# Timestamp e arquivo de log (declarar e readonly separadamente para evitar avisos do shellcheck)
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
readonly TIMESTAMP
LOG_FILE="/tmp/posinstall_${TIMESTAMP}.log"
readonly LOG_FILE

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() {
    echo -e "${GREEN}>>> $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ ERRO: $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠ ATENÇÃO: $1${NC}" | tee -a "$LOG_FILE"
}

# Verificações prévias
check_prerequisites() {
    log "Verificando pré-requisitos..."
    
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        error "Esse script precisa de acesso sudo. Configure passwordless sudo ou execute como root."
        exit 1
    fi
    
    if ! command -v dnf &>/dev/null; then
        error "dnf não encontrado. Esse script é para Fedora/RHEL."
        exit 1
    fi
    
    log "Pré-requisitos OK"
}

check_prerequisites

# Atualizar sistema
log "Atualizando sistema Fedora..."
sudo dnf update -y

# Repositório com arquivos adicionais para o Hyprland e RPM Fusion
log "Addictional repo, i don't use Arch btw!"
sudo dnf copr enable solopasha/hyprland -y
# Captura a versão do fedora para uso nas URLs (evita word-splitting warnings)
FEDORA_VER="$(rpm -E %fedora)"
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

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

# Instalar fontes e Nerd Fonts
log "Fonts"
sudo dnf install -y \
    dejavu-fonts-all \
    google-noto-sans-fonts \
    google-noto-serif-fonts \
    google-noto-mono-fonts \
    google-noto-sans-cjk-fonts \
    google-noto-serif-cjk-fonts \
    fira-code-fonts \
    jetbrains-mono-fonts \
    google-noto-emoji-fonts \
    cabextract \
    xorg-x11-font-utils \
    fontconfig

# Instalar Microsoft Core Fonts (opcional)
if ! fc-list | grep -q "MS Shell Dlg"; then
    log "Instalando Microsoft Core Fonts..."
    sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcorefonts-2.6-1.noarch.rpm 2>/dev/null || warning "Falha ao instalar MS Core Fonts (pode ser ignorado)"
fi

# Instalar Nerd Fonts (baixar e descompactar para ~/.local/share/fonts)
log "Instalando Nerd Fonts (JetBrainsMono, FiraCode)..."
mkdir -p ~/.local/share/fonts
# Usar um subshell para não alterar o diretório do usuário
(
    cd ~/.local/share/fonts || exit 1
    if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
        wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip -O /tmp/JetBrainsMono.zip || true
        if [[ -f /tmp/JetBrainsMono.zip ]]; then
            unzip -q /tmp/JetBrainsMono.zip && rm -f /tmp/JetBrainsMono.zip
            log "JetBrainsMono Nerd instalada"
        else
            warning "Não foi possível baixar JetBrainsMono Nerd (verifique rede)"
        fi
    fi

    if ! fc-list | grep -qi "FiraCode Nerd"; then
        wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip -O /tmp/FiraCode.zip || true
        if [[ -f /tmp/FiraCode.zip ]]; then
            unzip -q /tmp/FiraCode.zip && rm -f /tmp/FiraCode.zip
            log "FiraCode Nerd instalada"
        else
            warning "Não foi possível baixar FiraCode Nerd (verifique rede)"
        fi
    fi
)

# Atualizar cache de fontes
sudo fc-cache -fv

# Agora, finalmente os apps junto com o Hyprland.
log "Instalar Hyprland e aplicações essenciais"
sudo dnf install -y \
    hyprland \
    hyprcursor \
    xdg-desktop-portal-hyprland \
    wl-clipboard \
    wofi \
    hyprshot \
    mako \
    waybar \
    hyprpolkitagent \
    steam \
    vlc \
    pavucontrol \
    ddcutil \
    wget \
    unzip \
    curl \
    git \
    neovim \
    kitty \
    tmux \
    fzf \
    ripgrep \
    fd-find \
    bat \
    lsd \
    starship \
    neofetch \
    dconf \
    gnome-keyring \
    glibc-langpack-pt

log "Configurações pós-instalação"
# Habilitar flathub remoto
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Criar diretórios padrão se não existirem
mkdir -p ~/.config/hypr
mkdir -p ~/.local/share/applications

log "✓ Sistema pronto para receber dotsfiles!"
log "Log salvo em: $LOG_FILE"
