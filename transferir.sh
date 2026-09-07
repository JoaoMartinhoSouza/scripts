#!/bin/bash

LOCAL_DIR="/home/jms/Vídeos"
BASE_USB_DIR="/media/jms/Videoteca"

if [ "$1" != "series" ] && [ "$1" != "filmes" ] && [ "$1" != "animacoes" ]; then
    echo "Uso: $0 [series|filmes|animacoes]"
    exit 1
fi

if [ "$1" = "series" ]; then
    USB_DIR="$BASE_USB_DIR/_Séries"
elif [ "$1" = "filmes" ]; then
    USB_DIR="$BASE_USB_DIR/_Filmes"
else
    USB_DIR="$BASE_USB_DIR/_Animações"
fi

if [ ! -d "$LOCAL_DIR" ]; then
    echo "Erro: Diretório local não existe."
    exit 1
fi

if [ ! -d "$USB_DIR" ]; then
    echo "Erro: Diretório do HD externo não existe."
    exit 1
fi

echo "----------------------------------------"
echo "Enviando e removendo arquivos do LOCAL para o HD EXTERNO..."
echo "Origem: $LOCAL_DIR"
echo "Destino: $USB_DIR"
echo "----------------------------------------"

ERRO_GERAL=0

if [ "$1" = "series" ]; then

    rsync -av --no-progress --remove-source-files \
        "$LOCAL_DIR"/ "$USB_DIR"/

    ERRO_GERAL=$?

else

    for item in "$LOCAL_DIR"/*; do
        [ -e "$item" ] || continue

        nome_item=$(basename "$item")

        if [ -f "$item" ]; then

            rsync -av --no-progress --remove-source-files \
                "$item" "$USB_DIR"/

            if [ $? -ne 0 ]; then
                ERRO_GERAL=1
            fi

        elif [ -d "$item" ]; then

            primeiro_char="${nome_item:0:1}"
            primeiro_char_upper="${primeiro_char^^}"

            if [[ "$primeiro_char_upper" =~ ^[A-Z]$ ]]; then
                LETRA_DIR="$USB_DIR/$primeiro_char_upper"
            else
                LETRA_DIR="$USB_DIR/#"
            fi

            mkdir -p "$LETRA_DIR"

            if [ $? -ne 0 ]; then
                echo "Erro: não foi possível criar: $LETRA_DIR"
                ERRO_GERAL=1
                continue
            fi

            rsync -av --no-progress --remove-source-files \
                "$item/" "$LETRA_DIR/$nome_item/"

            if [ $? -ne 0 ]; then
                ERRO_GERAL=1
            else
                find "$item" -depth -empty -delete
            fi
        fi
    done
fi

echo "----------------------------------------"

if [ $ERRO_GERAL -eq 0 ]; then
    echo "Transferência concluída com sucesso."

    echo "Limpando pastas vazias no diretório de origem..."
    find "$LOCAL_DIR" -mindepth 1 -type d -empty -delete

    echo "Limpeza concluída."
else
    echo "Ocorreu um erro durante a transferência. Alguns arquivos originais podem ter sido mantidos."
fi

echo "----------------------------------------"
