#!/bin/sh
err_report() {
  echo "errexit on line $(caller)" >&2
  Mail -s "BLASTUPDATE-FAILED $(caller)" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
}
trap err_report ERR

cd /data/update_tmp

wget --timeout 120 http://dunbrack.fccc.edu/Guoli/culledpdb_hh/pdbaa.gz
gunzip pdbaa.gz
/opt/blast-2.2.26/bin/formatdb -i pdbaa -p T

wget --timeout 120 ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
gunzip uniref90.fasta.gz
/opt/blast-2.2.26/bin/formatdb -i uniref90.fasta -p T

#
# wget http://wwwuser.gwdg.de/~compbiol/uniclust/current_release/uniclust30_2018_08_hhsuite.tar.gz
# tar -zxvf

source /home/blast_worker/aa_env/bin/activate
cd /home/blast_worker/analytics_automated/
celery multi stop_verify worker --pidfile=celery.pid
cp /data/update_tmp/pdbaa* /data/pdbaa/
cp /data/update_tmp/uniref* /data/uniref/
celery --app=analytics_automated_project.celery:app worker --loglevel=INFO -Q sequpdate,blast,low_blast,high_blast --concurrency=24 --detach --pidfile=celery.pid

ssh blast_worker@bm1 "source /home/blast_worker/aa_env/bin/activate; celery multi stop_verify worker --pidfile=/home/blast_worker/analytics_automated/celery.pid"
scp /data/update_tmp/pdbaa* blast_worker@bm1:/data/pdbaa/
scp /data/update_tmp/uniref* blast_worker@bm1:/data/uniref/
ssh blast_worker@bm1 "source /home/blast_worker/aa_env/bin/activate; cd /home/blast_worker/analytics_automated/; celery --app=analytics_automated_project.celery:app worker --loglevel=INFO -Q blast,low_blast,high_blast --concurrency=24 --detach --pidfile=celery.pid"

echo `uname -n` | Mail -s "BLASTUPDATE-OK" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
