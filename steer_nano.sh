#!/bin/bash

CHHH=$1
ROOT="HIG-RunIISummer20UL17NanoAODv9-00217.root"
OUTDIR="NanoAODs/$CHHH/"

## TODO: More generalized for not only dihiggs

if [ -z "$CHHH" ]; then
    echo "You probably did not give a coupling!"
    echo "Currently chhh0,chhh1,chhh2p45 or chhh5"
    return 1
fi

mkdir -p $OUTDIR

## TODO: More generalized
## Idea: Create a list of list and everytime 500 files
##       are appended, go to next list. Then call func
##       by looping through comprising list.

directories_1=()
directories_2=()
missing=()
switch=500

for ((i=0; i<1000; i++)); do
    if [ -f dihiggs/$CHHH/files/run_$i/$ROOT ]; then
        if [ "$i" -lt "$switch" ]; then
            directories_1+=("dihiggs/$CHHH/files/run_$i/$ROOT")
        else
            directories_2+=("dihiggs/$CHHH/files/run_$i/$ROOT")
        fi
    else
        echo "dihiggs/$CHHH/files/run_$i/$ROOT CHECK <-------"
    	missing+=("dihiggs/$CHHH/files/run_$i/$ROOT")
    fi
done

output_file="${OUTDIR}/missing_files.txt"

# Check if output file exists and delete it if it does
if [ -f "$output_file" ]; then
  rm "$output_file"
fi

for element in "${missing[@]}"; do
  echo "$element" >> "$output_file"
done

echo "Do you want to continue with hadd? (y/n)"
echo "Only 'y' continues, all other options stop program!"
read opt

if [ "$opt" == "y" ]; then
	python haddnano.py $OUTDIR${CHHH}_1.root "${directories_1[@]}"
	python haddnano.py $OUTDIR${CHHH}_2.root "${directories_2[@]}"
else
	echo "Do not hadd NanoAODs"
	return 1
fi

