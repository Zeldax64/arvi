#!/bin/bash

if [ "$#" -lt 1 ]
then
	echo "You must pass an elf file as argument."
	exit 1
else
	riscv64-unknown-elf-objcopy -O binary $1 temp.txt
	od -An -t x4 temp.txt -v |
	awk '{print $1; print $2; print $3; print $4}'
	rm temp.txt
fi