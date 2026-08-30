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
SRC="$LOCAL_DIR"
DEST="$USB_DIR"

echo "Origem: $SRC"
echo "Destino: $DEST"
echo "----------------------------------------"

rsync -av --no-progress --remove-source-files "$SRC"/ "$DEST"/

STATUS=$?

echo "----------------------------------------"

if [ $STATUS -eq 0 ]; then
    echo "Transferência concluída com sucesso."
    
    echo "Limpando pastas vazias no diretório de origem..."
    find "$SRC" -mindepth 1 -type d -empty -delete
    
    echo "Limpeza concluída."
else
    echo "Ocorreu um erro durante a transferência. Os arquivos originais foram mantidos por segurança."
fi

echo "----------------------------------------"
