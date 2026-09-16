#!/bin/bash

find . -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) -print0 |
while IFS= read -r -d $'\0' f; do
    echo "--------------------------------------------------"
    echo "Processando: $f"
    echo "--------------------------------------------------"

    {
        case "${f,,}" in
            *.mkv)
                tmp="${f%.mkv}.tmp.mkv"

                first_audio_id=$(mkvmerge -J "$f" 2>/dev/null | jq -r '.tracks[] | select(.type=="audio") | .id' 2>/dev/null | head -n 1) || first_audio_id=""

                audio_args=()
                if [ -n "$first_audio_id" ] && [ "$first_audio_id" != "null" ]; then
                    audio_args=(--audio-tracks "$first_audio_id" --language "$first_audio_id:und")
                fi
                
                mkvmerge -o "$tmp" \
                    --title "" \
                    --no-chapters \
                    --no-track-tags \
                    --no-global-tags \
                    --no-attachments \
                    --no-subtitles \
                    --update-track-statistics-on-muxing yes \
                    "${audio_args[@]}" \
                    "$f" >/dev/null 2>&1

                status=$?
                if [ $status -eq 0 ] || [ $status -eq 1 ]; then
                    mkvpropedit "$tmp" --edit track:v1 --set name="" --edit track:a1 --set name="" >/dev/null 2>&1 || true
                    mv -f "$tmp" "$f"
                    echo "Sucesso (MKV): $f"
                else
                    echo "Aviso/Erro (MKV ignorado): $f (Código: $status)"
                    rm -f "$tmp"
                fi
                ;;

            *.mp4|*.avi)
                ext="${f##*.}"
                ext_lower="${ext,,}"
                tmp="${f%.*}.tmp.${ext_lower}"

                ffmpeg -nostdin -v error -y \
                    -i "$f" \
                    -map 0:v:0 \
                    -map 0:a:0? \
                    -sn \
                    -map -0:d \
                    -c copy \
                    -disposition:v:0 0 \
                    -map_metadata -1 \
                    -map_metadata:s -1 \
                    -map_chapters -1 \
                    -metadata title= \
                    -metadata:s:a:0 language=und \
                    "$tmp" >/dev/null 2>&1

                if [ $? -eq 0 ] && [ -f "$tmp" ]; then
                    mv -f "$tmp" "$f"
                    echo "Sucesso (${ext^^}): $f"
                else
                    echo "Aviso/Erro (${ext^^} ignorado): $f"
                    rm -f "$tmp"
                fi
                ;;
        esac
    } || {
        echo "Erro inesperado ao processar: $f (continuando...)"
        rm -f "${f%.*}.tmp."* 2>/dev/null || true
    }
done
