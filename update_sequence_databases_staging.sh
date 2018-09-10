#!/bun/sh
# activate virtual env
source /home/blast_worker/aa_env/bin/activate
# stop workers and restart with one fewer worker
cd /home/blast_worker/analytics_automated
celery multi stop worker --pidfile=celery.pid
celery --app=analytics_automated_project.celery:app worker --loglevel=INFO -Q low_localhost,localhost,high_localhost,low_GridEngine,GridEngine,high_GridEngine,low_R,R,high_R,low_Python,Python,high_Python --pidfile=celery.pid --concurrency 47
# get the database
cd /data/uniref_tmp
wget --timeout 120 ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
get --timeout 120 http://dunbrack.fccc.edu/Guoli/culledpdb_hh/pdbaa.gz
gunzip uniref90.fasta.gz
gunzip pdbaa
# build blastdb
/usr/local/bin/makeblastdb -dbtype prot -in uniref90.fasta
/usr/local/bin/makeblastdb -dbtype prot -in pdbaa
# move db
cd /home/blast_worker/analytics_automated
celery multi stop worker --pidfile=celery.pid
mv /data/uniref_tmp/uniref90* /data/uniref
mv /data/uniref_tmp/pdbaa* /data/pdbaa
# restart workers
celery --app=analytics_automated_project.celery:app worker --loglevel=INFO -Q low_localhost,localhost,high_localhost,low_GridEngine,GridEngine,high_GridEngine,low_R,R,high_R,low_Python,Python,high_Python --pidfile=celery.pid
