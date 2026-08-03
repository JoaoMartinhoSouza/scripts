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

echo "Enviando arquivos do LOCAL para o HD EXTERNO..."
SRC="$LOCAL_DIR"
DEST="$USB_DIR"

echo "Origem: $SRC"
echo "Destino: $DEST"
echo "----------------------------------------"

rsync -av --no-progress "$SRC"/ "$DEST"/

STATUS=$?

echo "----------------------------------------"

if [ $STATUS -eq 0 ]; then
    echo "Transferência concluída com sucesso."
else
    echo "Ocorreu um erro durante a transferência."
fi

echo "----------------------------------------"
