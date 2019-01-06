#!/bin/bash
for n in {1..16}
do
	total=0
	for i in {1..100}
	do
		t=$(mpiexec -np $n --hostfile machines.txt --mca plm_rsh_no_tree_spawn 1 blurMPI)
		total=$(dc <<< "10k$total 10k$t + p")
	done
	mean=$(dc <<< "10k$total 100 / p")
	echo "$n: $mean"
done