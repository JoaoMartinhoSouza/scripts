#!/bin/bash

find . -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) -print0 |
while IFS= read -r -d $'\0' f; do
    echo "--------------------------------------------------"
    echo "Processando: $f"
    echo "--------------------------------------------------"

    case "${f,,}" in
        *.mkv)
        tmp="${f%.mkv}.tmp.mkv"

        first_audio_id=$(mkvmerge -J "$f" | jq -r '.tracks[] | select(.type=="audio") | .id' | head -n 1)

        audio_args=()
        if [ -n "$first_audio_id" ]; then
            audio_args=(--audio-tracks "$first_audio_id" --language "$first_audio_id:und")
        fi

        mkvmerge -o "$tmp" \
            --title "" \
            --no-chapters \
            --no-track-tags \
            --no-global-tags \
            --no-attachments \
            --no-subtitles \
            "${audio_args[@]}" \
            "$f"

        status=$?
        if [ $status -eq 0 ] || [ $status -eq 1 ]; then
            mv -f "$tmp" "$f"
            echo "Sucesso (MKV): $f"
        else
            echo "Erro real (MKV): $f (Código de saída: $status)"
            rm -f "$tmp"
        fi
        ;;

        *.mp4|*.avi)
        ext="${f##*.}"
        tmp="${f%.*}.tmp.${ext}"

        ffmpeg -nostdin -v error -y \
            -i "$f" \
            -map 0:v:0 \
            -map 0:a:0? \
            -sn \
            -map -0:d \
            -c copy \
            -disposition:v:0 0 \
            -map_metadata -1 \
            -map_chapters -1 \
            -metadata title= \
            -metadata:s:a:0 language=und \
            "$tmp"

        if [ $? -eq 0 ]; then
            mv -f "$tmp" "$f"
            echo "Sucesso (${ext^^}): $f"
        else
            echo "Erro (${ext^^}): $f"
            rm -f "$tmp"
        fi
        ;;
    esac
done
