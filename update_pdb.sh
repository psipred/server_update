#!/bin/sh

err_report() {
  echo "errexit on line $(caller)" # >&2
  echo `uname -n` | Mail -s "PDBUPDATE-FAILED $(caller)" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
  curl -X POST -H 'Content-type: application/json' --data '{"text":":rage:\n'`uname -n`' PDBUPDATE-FAILED"}' https://hooks.slack.com/services/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
  exit 0
}
trap err_report ERR


MAX_RETRIES=300
i=0

# Set the initial return value to failure

cd /data/pdb

while [ $i -lt $MAX_RETRIES ]
do
echo "HEY 1"
i=$(($i+1))
rsync -rlpt -v -z --delete --copy-links --port=33444 rsync.rcsb.org::ftp_data/structures/all/pdb/ ./
if [[ $? -eq 0 ]]; then
break
fi
done

if [ $i -eq $MAX_RETRIES ]
then
echo "Hit maximum number of retries, giving up."
fi

i=0
cd /data/pdb
while [ $i -lt $MAX_RETRIES ]
do
echo "HEY 2"
i=$(($i+1))
ssh django_worker@bm3 rsync -rlpt -v -z --delete --copy-links --port=33444 rsync.rcsb.org::ftp_data/structures/all/pdb/ /data/pdb
if [[ $? -eq 0 ]]; then
break
fi
done

if [ $i -eq $MAX_RETRIES ]
then
echo "Hit maximum number of retries, giving up."
fi

echo `uname -n` | Mail -s "PDBUPDATE-OK" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
curl -X POST -H 'Content-type: application/json' --data '{"text":":smile:\n'`uname -n`' PDBUPDATE-OK"}' https://hooks.slack.com/services/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
