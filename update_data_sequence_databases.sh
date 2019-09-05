#!/bin/sh
set -e
cd /data/update_tmp

wget --timeout 120 http://dunbrack.fccc.edu/Guoli/culledpdb_hh/pdbaa.gz
gunzip pdbaa.gz
/data/ncbi-blast-2.7.1+/bin/makeblastdb -dbtype prot -in pdbaa

wget --timeout 120 ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
gunzip uniref90.fasta.gz
mv uniref90.fasta unirefmain.fasta
/data/ncbi-blast-2.7.1+/bin/makeblastdb -dbtype prot -in unirefmain.fasta
/data/hmmer-3.1b2-linux-intel-x86_64/binaries/esl-sfetch --index unirefmain.fasta

wget http://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/pdb70_from_mmcif_latest.tar.gz
tar -zxvf pdb70_from_mmcif_latest.tar.gz
#
# wget http://wwwuser.gwdg.de/~compbiol/uniclust/current_release/uniclust30_2018_08_hhsuite.tar.gz
# tar -zxvf

source /home/django_worker/aa_env/bin/activate
cd /home/django_worker/analytics_automated/
celery multi stop_verify worker --pidfile=celery.pid
cp /data/update_tmp/pdbaa* /data/pdbaa/
cp /data/update_tmp/uniref* /data/uniref/
cp -r /data/update_tmp/pdb70* /data/hhdb/pdb/
cp /data/update_tmp/pdb_filter.dat /data/hhdb/pdb/
celery --app=analytics_automated_project.celery:app worker --loglevel=INFO -Q pdbtdbupdate,low_localhost,localhost,high_localhost,celery,low_R,R,high_R,low_Python,Python,high_Python --detach --pidfile=celery.pid

ssh django_worker@bm3 "source /home/django_worker/aa_env/bin/activate; celery multi stop_verify worker --pidfile=/home/django_worker/analytics_automated/celery.pid"
scp /data/update_tmp/pdbaa* django_worker@bm3:/data/pdbaa/
scp /data/update_tmp/uniref* django_worker@bm3:/data/uniref/
scp -r /data/update_tmp/pdb70* django_worker@bm3:/data/hhdb/pdb/
scp /data/update_tmp/pdb_filter.dat django_worker@bm3:/data/hhdb/pdb/
ssh django_worker@bm3 "source /home/django_worker/aa_env/bin/activate; cd /home/django_worker/analytics_automated/; celery --app=analytics_automated_project.celery:app worker --loglevel=INFO -Q low_localhost,localhost,high_localhost,celery,low_R,R,high_R,low_Python,Python,high_Python --detach --pidfile=celery.pid"

echo `uname -n` | Mail -s "SEQUPDATE-OK" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
