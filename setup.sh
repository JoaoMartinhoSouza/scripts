#!/usr/bin/env bash

set -euo pipefail

pacotes=(
    cowsay
    curl
    deluge
    exiftool
    ffmpeg
    foliate
    fortune
    gcolor3
    git
    imagemagick
    libreoffice-l10n-pt-br
    lolcat
    mkvtoolnix
    rsync
    wget
    xmlstarlet
)

pacotes_remover=(
    evolution
    gnome-clocks
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-snapshot
    gnome-sound-recorder
    gnome-tour
    gnome-tweaks
    gnome-weather
    shotwell
)

repositorios=(
    "https://github.com/JoaoMartinhoSouza/epub-cleaner.git|/home/jms/Área de trabalho/Epub Cleaner"
    "https://github.com/JoaoMartinhoSouza/joaomartinhosouza.github.io.git|/home/jms/Área de trabalho/Página pessoal"
    "https://github.com/JoaoMartinhoSouza/scripts.git|/home/jms/Área de trabalho/Scripts"
)

backup_itens=(
    "/media/jms/Backup/.bash_aliases|/home/jms/.bash_aliases|arquivo"
    "/media/jms/Backup/.git-credentials|/home/jms/.git-credentials|arquivo"
    "/media/jms/Backup/.gitconfig|/home/jms/.gitconfig|arquivo"
    "/media/jms/Backup/Documentos|/home/jms/Documentos|conteudo"
    "/media/jms/Backup/Imagens|/home/jms/Imagens|conteudo"
    "/media/jms/Backup/Modelos|/home/jms/Modelos|conteudo"
    "/media/jms/Backup/Temporário|/home/jms/Área de trabalho|pasta"
)

gsettings=(
    "gsettings set org.gnome.desktop.interface clock-show-weekday true"
    "gsettings set org.gnome.mutter center-new-windows true"
    "gsettings set org.gnome.desktop.wm.preferences action-right-click-titlebar 'toggle-maximize'"
)

comandos_avulsos=(
    "rm /home/jms/.face"
    "rm /home/jms/.face.icon"
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

customizar_grub() {
    local arquivo="/etc/default/grub"

    sed -i '/^#\?\s*GRUB_BACKGROUND=/d' "$arquivo"
    echo "GRUB_BACKGROUND=''" >> "$arquivo"

    sudo update-grub
}

configurar_sudo() {
    local user_file="/etc/sudoers.d/jms"
    local defaults_file="/etc/sudoers.d/00-custom"

    echo "jms ALL=(ALL:ALL) ALL" > "$user_file"
    chmod 440 "$user_file"

    touch "$defaults_file"

    grep -qE '^\s*Defaults\s+pwfeedback\b' "$defaults_file" || \
        echo "Defaults pwfeedback" >> "$defaults_file"

    grep -qE '^\s*Defaults\s+insults\b' "$defaults_file" || \
        echo "Defaults insults" >> "$defaults_file"

    chmod 440 "$defaults_file"
}

aplicar_gsettings() {
    log "Aplicando configurações do GNOME..."

    for cmd in "${gsettings[@]}"; do
        log "→ $cmd"
        bash -c "$cmd"
    done
}

executar_comandos_avulsos() {
    log "Executando comandos avulsos..."

    for cmd in "${comandos_avulsos[@]}"; do
        log "→ $cmd"
        bash -c "$cmd"
    done
}

corrigir_permissoes_home() {
    log "Corrigindo permissões de /home/jms..."
    chown -R jms:jms /home/jms
}

main() {
    checar_root

    case "${1:-tudo}" in
        pacotes)
            instalar_pacotes
            remover_pacotes
            ;;
        repos)
            clonar_repositorios
            corrigir_permissoes_home
            ;;
        backup)
            restaurar_backup
            corrigir_permissoes_home
            ;;
        configs)
            customizar_grub
            configurar_sudo
            aplicar_gsettings
            ;;
        tudo)
            instalar_pacotes
            remover_pacotes
            clonar_repositorios
            restaurar_backup
            customizar_grub
            configurar_sudo
            executar_comandos_avulsos
            aplicar_gsettings
            corrigir_permissoes_home
            ;;
        *)
            echo "Uso: $0 [pacotes|repos|backup|configs|tudo]"
            exit 1
            ;;
    esac

    log "Processo concluído."
}

main "$@"
