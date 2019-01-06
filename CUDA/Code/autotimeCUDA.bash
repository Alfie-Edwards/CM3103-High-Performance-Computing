#!/bin/bash
for n in 10 20 40 80 160
do
	total1=0
	total2=0
	total3=0
	total4=0
	total5=0
	total6=0
	total7=0

	for i in {1..10}
	do
		output=$(blur $n)
		t=($output)
		t1=${t[0]}
		t2=${t[1]}
		t3=${t[2]}
		t4=${t[3]}
		t5=${t[4]}
		t6=${t[5]}
		t7=${t[6]}
		total1=$(dc <<< "10k$total1 10k$t1 + p")
		total2=$(dc <<< "10k$total2 10k$t2 + p")
		total3=$(dc <<< "10k$total3 10k$t3 + p")
		total4=$(dc <<< "10k$total4 10k$t4 + p")
		total5=$(dc <<< "10k$total5 10k$t5 + p")
		total6=$(dc <<< "10k$total6 10k$t6 + p")
		total7=$(dc <<< "10k$total7 10k$t7 + p")
	done
	mean1=$(dc <<< "10k$total1 10 / p")
	mean2=$(dc <<< "10k$total2 10 / p")
	mean3=$(dc <<< "10k$total3 10 / p")
	mean4=$(dc <<< "10k$total4 10 / p")
	mean5=$(dc <<< "10k$total5 10 / p")
	mean6=$(dc <<< "10k$total6 10 / p")
	mean7=$(dc <<< "10k$total7 10 / p")
	echo "$n: $mean1 $mean2 $mean3 $mean4 $mean5 $mean6 $mean7"
done