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

## TODO: More generalized
## Idea: Create a list of list and everytime 500 files
##       are appended, go to next list. Then call func
##       by looping through comprising list.

directories_1=()
directories_2=()
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
    fi
done

python haddnano.py $OUTDIR${CHHH}_1.root "${directories_1[@]}"
python haddnano.py $OUTDIR${CHHH}_2.root "${directories_2[@]}"