#!/bin/zsh

cat <<EOF
CREATE TABLE global_symbols   (	symbol TEXT PRIMARY KEY,
dir TEXT,
file TEXT);
EOF

for i in $(find -name '*.dwo' -a ! -name '*built-in*' -a ! -wholename '*/drivers/*' -a ! -wholename '*/lib/*' ) ; do
	if [[ ! -e ${i/%.dwo/.mod.c} ]]; then
		for symbol in $(nm ${i/%.dwo/.o} | awk '$2 == "T" { print $3; }') ; do
		echo "INSERT INTO global_symbols (symbol,dir,file) VALUES ('${symbol}', '${$(dirname $i)#\.\/}', '$(basename $i .dwo).c');"
		done
	fi
done
