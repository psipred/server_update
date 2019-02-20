#!/bin/#!/usr/bin/env bash
trap "echo Exited!; exit;" SIGINT SIGTERM

MAX_RETRIES=300
i=0

# Set the initial return value to failure

cd /webdata/data/pdb/ftp.wwpdb.org/pub/pdb/data/structures/all/pdb
false
while [ $? -ne 0 -a $i -lt $MAX_RETRIES ]
do
#echo "HEY"
i=$(($i+1))
rsync -rLpt -v -z --delete rsync.ebi.ac.uk::pub/databases/msd/pdb_uncompressed/ /webdata/data/pdb/ftp.wwpdb.org/pub/pdb/data/structures/all/pdb
done

if [ $i -eq $MAX_RETRIES ]
then
echo "Hit maximum number of retries, giving up."
fi

while [ $? -ne 0 -a $i -lt $MAX_RETRIES ]
do
#echo "HEY"
i=$(($i+1))
ssh django_worker@bioinfstage4 rsync -rLpt -v -z --delete rsync.ebi.ac.uk::pub/databases/msd/pdb_uncompressed/ /webdata/data/pdb/ftp.wwpdb.org/pub/pdb/data/structures/all/pdb
done

if [ $i -eq $MAX_RETRIES ]
then
echo "Hit maximum number of retries, giving up."
fi
