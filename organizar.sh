#!/bin/bash

ajuda() {
    echo "Uso: $0 [-c | -d]"
    echo "  -c    Coletar: Encontra todos os arquivos .srt nos subdiretórios e os traz para o diretório atual."
    echo "  -d    Distribuir: Move os arquivos .srt do diretório atual para as pastas correspondentes."
    exit 1
}

if [ $# -eq 0 ]; then
    ajuda
fi

coletar_srt() {
    echo "Buscando arquivos .srt nos subdiretórios..."
    local encontrou=0

    while IFS= read -r -d '' arquivo; do
        if [ "$(dirname "$arquivo")" != "." ]; then
            echo "Movendo: $arquivo -> ./"
            mv "$arquivo" ./
            encontrou=1
        fi
    done < <(find . -mindepth 2 -type f -name "*.srt" -print0)

    if [ $encontrou -eq 0 ]; then
        echo "Nenhum arquivo .srt encontrado nos subdiretórios."
    else
        echo "Coleta concluída!"
    fi
}

formatar_nome_diretorio() {
    local nome_base="$1"
    if [[ "$nome_base" =~ ^([Tt][Hh][Ee]|[Aa][Nn]?)\ (.*)$ ]]; then
        echo "${BASH_REMATCH[2]}, ${BASH_REMATCH[1]}"
    else
        echo "$nome_base"
    fi
}

distribuir_srt() {
    echo "Distribuindo arquivos .srt para seus respectivos diretórios..."
    local encontrou=0

    for arquivo in *.srt; do
        [ -e "$arquivo" ] || continue
        encontrou=1

        local nome_sem_ext="${arquivo%.srt}"

        local nome_filme="$nome_sem_ext"
        if [[ "$nome_sem_ext" =~ \.[a-zA-Z]{2}(-[a-zA-Z]{2})?$ ]]; then
            nome_filme="${nome_sem_ext%.*}"
        fi

        local busca_diretorio
        busca_diretorio=$(formatar_nome_diretorio "$nome_filme")

        local diretorio_destino=""
        for d in */; do
            [ -e "$d" ] || continue
            local d_limpo="${d%/}"
            if [[ "${d_limpo,,}" =~ ^${busca_diretorio,,} ]]; then
                diretorio_destino="$d_limpo"
                break
            fi
        done

        if [ -n "$diretorio_destino" ]; then
            echo "Movendo '$arquivo' para '$diretorio_destino/'"
            mv "$arquivo" "$diretorio_destino/"
        else
            echo "Aviso: Nenhum diretório correspondente encontrado para '$arquivo' (Esperado algo como: '$busca_diretorio ...')"
        fi
    done

    if [ $encontrou -eq 0 ]; then
        echo "Nenhum arquivo .srt encontrado no diretório raiz para distribuir."
    fi
}

while getopts "cd" opcao; do
    case "${opcao}" in
        c)
            coletar_srt
            ;;
        d)
            distribuir_srt
            ;;
        *)
            ajuda
            ;;
    esac
done
