#!/bin/zsh

for i in $(find -name '*.dwo' -a ! -name '*built-in*' -a ! -wholename '*/drivers/*' -a ! -wholename '*/lib/*' ) ; do
	if [[ ! -e ${i/%.dwo/.mod.c} ]]; then
		for symbol in $(nm ${i/%.dwo/.o} | awk '$2 == "T" { print $3; }') ; do
			echo "$symbol $i" >> symbols.list
		done
	fi
done
