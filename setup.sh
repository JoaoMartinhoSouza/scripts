#!/usr/bin/env bash

set -euo pipefail

pacotes=(
    apostrophe
    curl
    exiftool
    deluge
    drawing
    ffmpeg
    foliate
    git
    gcolor3
    gnome-console
    gnome-video-trimmer
    imagemagick
    mkvtoolnix
    mpv
    papers
    rsync
    thunderbird
    wget
    xmlstarlet
)

pacotes_remover=(
    evince
    evolution
    gnome-clocks
    gnome-connections
    gnome-contacts
    gnome-logs
    gnome-maps
    gnome-music
    gnome-snapshot
    gnome-sound-recorder
    gnome-terminal
    gnome-tour
    gnome-tweaks
    gnome-weather
    libreoffice*
    malcontent
    seahorse
    simple-scan
    shotwell
    totem
)

repositorios=(
    "https://github.com/joao-martinho/epub-cleaner.git|/home/joao/Área de trabalho/Epub Cleaner"
    "https://github.com/joao-martinho/pagina-pessoal.git|/home/joao/Área de trabalho/Página pessoal"
    "https://github.com/joao-martinho/scripts.git|/home/joao/Área de trabalho/Scripts"
)

backup_itens=(
    # Arquivos
    "/media/joao/Backup/.bash_aliases|/home/joao/.bash_aliases|arquivo"
    "/media/joao/Backup/.git-credentials|/home/joao/.git-credentials|arquivo"
    "/media/joao/Backup/.gitconfig|/home/joao/.gitconfig|arquivo"
    
    # Pastas
    "/media/joao/Backup/Concurso|/home/joao/Área de trabalho|pasta"
    "/media/joao/Backup/Documentos|/home/joao/Documentos|conteudo"
    "/media/joao/Backup/Imagens|/home/joao/Imagens|conteudo"
    "/media/joao/Backup/Modelos|/home/joao/Modelos|conteudo"
    "/media/joao/Backup/Temporário|/home/joao/Área de trabalho|pasta"
)

comandos_avulsos=(
    # GSettings
    ## Comportamento e aparência
    "gsettings set org.gnome.desktop.background picture-uri file:///usr/share/backgrounds/gnome/pixels-l.svg"
    "gsettings set org.gnome.desktop.interface accent-color 'slate'"
    "gsettings set org.gnome.desktop.interface clock-show-weekday true"
    "gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
    "gsettings set org.gnome.desktop.wm.preferences action-right-click-titlebar 'toggle-maximize'"
    "gsettings set org.gnome.mutter center-new-windows true"
    
    ## Luz noturna
    "gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true"
    "gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false"
    "gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 20"
    "gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 20"
    "gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3700"
    
    ## Energia
    "gsettings set org.gnome.desktop.session idle-delay 0"
    "gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'"
    
    # Outros
    "gpg --import /home/joao/Documentos/PGP/*.asc"
    "rm /home/joao/.face"
    "rm /home/joao/.face.icon"
    "sudo apt install libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gnome libreoffice-l10n-pt-br"
)

log() {
    printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"
}

checar_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Este script precisa ser executado como root."
        echo "Use: sudo $0"
        exit 1
    fi
}

instalar_pacotes() {
    log "Atualizando lista de pacotes..."
    apt update

    log "Instalando pacotes..."
    apt install -y "${pacotes[@]}"
}

remover_pacotes() {
    log "Removendo pacotes desnecessários..."
    apt purge -y "${pacotes_remover[@]}"

    log "Limpando dependências não utilizadas..."
    apt autoremove -y
}

clonar_repositorios() {
    log "Clonando repositórios..."

    for repo in "${repositorios[@]}"; do
        IFS="|" read -r url destino <<< "$repo"

        log "→ $url → $destino"

        if [[ -d "$destino/.git" ]]; then
            log "Atualizando repositório existente..."
            git -C "$destino" pull
        else
            git clone "$url" "$destino"
        fi
    done
}

restaurar_backup() {
    log "Restaurando backup..."

    for item in "${backup_itens[@]}"; do
        IFS="|" read -r origem destino modo <<< "$item"

        log "→ $origem → $destino ($modo)"

        if [[ ! -e "$origem" ]]; then
            log "Aviso: $origem não existe, pulando..."
            continue
        fi

        case "$modo" in
            conteudo)
                mkdir -p "$destino"
                rsync -a "$origem"/ "$destino"/
                ;;
            pasta)
                rsync -a "$origem" "$destino"
                ;;
            arquivo)
                mkdir -p "$(dirname "$destino")"
                rsync -a "$origem" "$destino"
                ;;
            *)
                log "Modo desconhecido: $modo"
                ;;
        esac
    done
}

corrigir_permissoes_home() {
    log "Corrigindo permissões de /home/joao..."
    chown -R joao:joao /home/joao
}

configurar_sudo() {
    local user_file="/etc/sudoers.d/joao"
    local defaults_file="/etc/sudoers.d/00-custom"

    echo "joao ALL=(ALL:ALL) ALL" > "$user_file"
    chmod 440 "$user_file"

    touch "$defaults_file"

    grep -qE '^\s*Defaults\s+pwfeedback\b' "$defaults_file" || \
        echo "Defaults pwfeedback" >> "$defaults_file"

    grep -qE '^\s*Defaults\s+insults\b' "$defaults_file" || \
        echo "Defaults insults" >> "$defaults_file"

    chmod 440 "$defaults_file"
}

customizar_grub() {
    local arquivo="/etc/default/grub"

    sed -i '/^#\?\s*GRUB_BACKGROUND=/d' "$arquivo"
    echo "GRUB_BACKGROUND=''" >> "$arquivo"

    sudo update-grub
}

executar_comandos_avulsos() {
    log "Executando comandos avulsos..."

    for cmd in "${comandos_avulsos[@]}"; do
        log "→ $cmd"
        bash -c "$cmd"
    done
}

main() {
    checar_root
    
    instalar_pacotes
    remover_pacotes
    clonar_repositorios
    restaurar_backup
    corrigir_permissoes_home
    configurar_sudo
    customizar_grub
    executar_comandos_avulsos

    log "Processo concluído."
}

main "$@"
