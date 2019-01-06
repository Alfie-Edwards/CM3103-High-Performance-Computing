#!/bin/bash
for n in 10 20 40 80 160
do
	echo $n
	for i in {1..20}
	do
		blur $n
	done
done