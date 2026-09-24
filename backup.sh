#!/bin/bash

set -uo pipefail

DESTINO="/media/jms/Backup"

ORIGENS=(
    "/home/jms/.bash_aliases"
    "/home/jms/.git-credentials"
    "/home/jms/.gitconfig"
    "/home/jms/Área de trabalho/Concurso"
    "/home/jms/Área de trabalho/Scripts/setup.sh"
    "/home/jms/Área de trabalho/Temporário"
    "/home/jms/Documentos"
    "/home/jms/Imagens"
    "/home/jms/Modelos"
)

for ORIGEM in "${ORIGENS[@]}"; do
    if [ -d "$ORIGEM" ]; then
        NOME="$(basename "$ORIGEM")"

        rsync -a --update --delete \
              --human-readable --progress \
              "$ORIGEM/" "$DESTINO/$NOME/" || echo "Aviso: rsync reportou erros em $ORIGEM, mas continuando..."

    elif [ -f "$ORIGEM" ]; then
        rsync -a --update \
              --human-readable --progress \
              "$ORIGEM" "$DESTINO/" || echo "Aviso: rsync reportou erros no arquivo $ORIGEM, mas continuando..."

    else
        echo "Aviso: origem não encontrada, ignorando: $ORIGEM" >&2
    fi
done
