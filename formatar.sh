#!/bin/bash

echo "Iniciando limpeza de legendas no diretório: $(pwd)"

find . -type f -iname "*.srt" -print0 | while IFS= read -r -d '' file; do
	echo "Verificando: $file"

	if grep -q '<[^>]\+>' "$file"; then
		echo "  HTML encontrado, limpando..."
		sed -E -i 's/<[^>]+>//g' "$file"
		echo "  Limpo"
	else
		echo "  Sem HTML, ignorado"
	fi
done

echo "Concluído"
