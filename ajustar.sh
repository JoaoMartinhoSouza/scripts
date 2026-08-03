#!/bin/bash

if [ $# -ne 1 ]; then
	echo "Uso: $0 deslocamento_em_segundos"
	exit 1
fi

OFFSET="$1"

for ARQ in *.srt; do
	[ -e "$ARQ" ] || continue
	TMP=$(mktemp)

	awk -v off="$OFFSET" '
	function to_seconds(h,m,s,ms) {
		return h*3600 + m*60 + s + ms/1000
	}
	function from_seconds(t) {
		if (t < 0) t=0
		h=int(t/3600); t%=3600
		m=int(t/60); t%=60
		s=int(t); ms=int((t-s)*1000)
		return sprintf("%02d:%02d:%02d,%03d",h,m,s,ms)
	}
	{
		if ($0 ~ /-->/) {
			split($1,a,":")
			split(a[3],b,",")
			t1=to_seconds(a[1],a[2],b[1],b[2])

			split($3,c,":")
			split(c[3],d,",")
			t2=to_seconds(c[1],c[2],d[1],d[2])

			t1+=off
			t2+=off

			print from_seconds(t1) " --> " from_seconds(t2)
		} else {
			print $0
		}
	}
	' "$ARQ" > "$TMP"

	mv "$TMP" "$ARQ"
	echo "Ajustado: $ARQ"
done
