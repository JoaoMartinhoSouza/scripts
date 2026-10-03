#!/bin/bash

set -uo pipefail

DESTINO="/media/joao/Backup"

ORIGENS=(
    "/home/joao/.bash_aliases"
    "/home/joao/.git-credentials"
    "/home/joao/.gitconfig"
    "/home/joao/Área de trabalho/Concurso"
    "/home/joao/Área de trabalho/Scripts/setup.sh"
    "/home/joao/Área de trabalho/Temporário"
    "/home/joao/Documentos"
    "/home/joao/Imagens"
    "/home/joao/Modelos"
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
