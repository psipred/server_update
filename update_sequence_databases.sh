#!/bun/sh
# activate virtual env
source /scratch0/NOT_BACKED_UP/dbuchan/virtualenvs/analytics_automated/bin/activate
# stop workers and restart with one fewer worker
cd /home/dbuchan/Code/analytics_automated
celery multi stop worker --pidfile=celery.pid
rm /home/dbuchan/Code/analytics_automated/celery.pid
celery --app=analytics_automated_project.celery:app worker --loglevel=INFO -Q low_localhost,localhost,high_localhost,low_GridEngine,GridEngine,high_GridEngine,low_R,R,high_R,low_Python,Python,high_Python --pidfile=celery.pid --concurrency 11 --detach
# get the database
cd /scratch0/NOT_BACKED_UP/dbuchan/unireftmp
wget --timeout 120 ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
wget --timeout 120 http://dunbrack.fccc.edu/Guoli/culledpdb_hh/pdbaa.gz
gunzip uniref90.fasta.gz
gunzip pdbaa
# build blastdb
/scratch0/NOT_BACKED_UP/dbuchan/Applications/ncbi-blast-2.2.31+/bin/makeblastdb -dbtype prot -in uniref90.fasta
/scratch0/NOT_BACKED_UP/dbuchan/Applications/ncbi-blast-2.2.31+/bin/makeblastdb -dbtype prot -in pdbaa
# move db
cd /home/dbuchan/Code/analytics_automated
celery multi stop worker --pidfile=celery.pid
rm /home/dbuchan/Code/analytics_automated/celery.pid
mv /scratch0/NOT_BACKED_UP/dbuchan/unireftmp/* /scratch1/NOT_BACKED_UP/dbuchan/uniref/
# restart workers
celery --app=analytics_automated_project.celery:app worker --loglevel=INFO -Q low_localhost,localhost,high_localhost,low_GridEngine,GridEngine,high_GridEngine,low_R,R,high_R,low_Python,Python,high_Python --pidfile=celery.pid --detach
