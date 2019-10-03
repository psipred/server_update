#!/bin/#!/usr/bin/env bash

err_report() {
  echo "errexit on line $(caller)" >&2
  echo `uname -n` | Mail -s "SEQUPDATE-FAILED $(caller)" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
}
trap err_report ERR


MAX_RETRIES=300
i=0

# Set the initial return value to failure

cd /data/pdb
false
while [ $? -ne 0 -a $i -lt $MAX_RETRIES ]
do
#echo "HEY"
i=$(($i+1))
rsync -rlpt -v -z --delete --copy-links --port=33444 rsync.rcsb.org::ftp_data/structures/all/pdb/ ./
done

if [ $i -eq $MAX_RETRIES ]
then
echo "Hit maximum number of retries, giving up."
fi

i=0
cd /data/pdb
false
while [ $? -ne 0 -a $i -lt $MAX_RETRIES ]
do
#echo "HEY"
i=$(($i+1))
ssh django_worker@bm3 rsync -rlpt -v -z --delete --copy-links --port=33444 rsync.rcsb.org::ftp_data/structures/all/pdb/ /data/pdb
done

if [ $i -eq $MAX_RETRIES ]
then
echo "Hit maximum number of retries, giving up."
fi

echo `uname -n` | Mail -s "PDBUPDATE-OK" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
