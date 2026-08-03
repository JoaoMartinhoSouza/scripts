#!/bin/bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

DIRETORIO_CHAMADA="$(pwd)"

for cmd in mkvmerge mkvextract ffmpeg jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Erro: o comando '$cmd' não está instalado. Instale com:"
        echo "  sudo apt install mkvtoolnix ffmpeg jq"
        exit 1
    fi
done

FIND_OPTS=(-type f -iname "*.mkv")

mapfile -d '' ARQUIVOS < <(find "$DIRETORIO_CHAMADA" "${FIND_OPTS[@]}" -print0)

if [ ${#ARQUIVOS[@]} -eq 0 ]; then
    echo "Nenhum arquivo MKV encontrado em '$DIRETORIO_CHAMADA'."
    exit 0
fi

for ARQ in "${ARQUIVOS[@]}"; do
    echo "Processando: $ARQ"

    BASE="${ARQ%.*}"

    JSON=$(mkvmerge -J "$ARQ" 2>/dev/null)
    if [ -z "$JSON" ]; then
        echo "Aviso: mkvmerge não conseguiu ler '$ARQ'. Pulando."
        continue
    fi

    echo "$JSON" | jq -r '
        .tracks[]? | select(.type=="subtitles") |
        "\(.id)|\(.properties.language // "und")|\(.properties.codec_id // "unknown")"
    ' | while IFS="|" read -r ID LANG CODEC; do

        if [ "$LANG" = "eng" ]; then
            LANG="en"
        elif [ "$LANG" = "por" ]; then
            LANG="pt"
        fi

        SAIDA="${BASE}.${LANG}"

        case "$CODEC" in
            S_TEXT/UTF8|S_TEXT/ASCII)
                EXT="srt"
                ;;
            S_TEXT/ASS|S_TEXT/SSA)
                EXT="ass"
                ;;
            *)
                EXT="sub"
                ;;
        esac

        SAIDA_FINAL="${SAIDA}.${EXT}"

        if ! mkvextract tracks "$ARQ" "$ID:$SAIDA_FINAL" >/dev/null 2>&1; then
            echo "Falha ao extrair trilha $ID."
            continue
        fi

        if [ "$EXT" = "ass" ]; then
            if ffmpeg -y -i "$SAIDA_FINAL" "${SAIDA}.srt" >/dev/null 2>&1; then
                rm "$SAIDA_FINAL"
                SAIDA_FINAL="${SAIDA}.srt"
            else
                echo "Falha ao converter '$SAIDA_FINAL' para SRT."
            fi
        fi

        echo "Legenda salva como: $SAIDA_FINAL"
    done

    echo "Concluído para: $ARQ"
    echo
done

echo "Extração concluída."
