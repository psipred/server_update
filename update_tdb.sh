#!/bin/tcsh
err_report() {
  echo "errexit on line $(caller)" >&2
  # echo `uname -n` | Mail -s "TDBUPDATE-FAILED $(caller)" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
  curl -X POST -H 'Content-type: application/json' --data '{"text":":rage:\n'`uname -n`' TDBUPDATE-OK"}' https://hooks.slack.com/services/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
  exit 0
}
trap err_report ERR

# stop workers
# start workers with 1 less thread

#make sure we are in the pdb
#is this right or should we be in autoupdate?
cd /data/update_tdb

#set the t_coffee env variables
setenv TMP_4_TCOFFEE .t_coffee
setenv CACHE_4_TCOFFEE .t_coffee/cache

# Remove old cullpdb list
/bin/rm -f cullpdb*
# /bin/rm -f /webdata/data/autoupdate/cullpdb*

#chmod uog+rw /webdata/data/pdb/*
#pdb is now so large we need to pipe the chmod from a find listing
find /data/pdb/ -type f -exec chmod uog+rw {} \;
find /data/pdb/ -iname "*.gz" -type f -exec gunzip {} \;

echo "building pdb list"
# Build cullpdb list

#make a list of the pdb's we've grabbed
/bin/ls -1 /data/pdb/ > pdb.lst

# Extract protein sequences from PDB ATOM records (ignore CA-only entries)
echo "extracting aa sequences"
/data/server_update/src/makepdbaa /data/pdb pdb.lst pdb_aa.fasta >& /data/update_tdb/makepdb.log
chmod uog+rw /data/update_tdb/makepdb.log
chmod uog+rw /data/update_tdb/pdb_aa.fasta

# Cluster sequences at 90% redundancy
echo "clustering pdb"
/data/server_update/src/pdbclust pdb_aa.fasta > cullpdb.lst
chmod uog+rw /data/update_tdb/cullpdb.lst
#exit 0

#run auto_psisum to make new tdb files
#add new auto_psisum command here.
#/webdata/data/autoupdate/make_tdb.pl
/data/maketdb/bin/make_tdb.pl -i /data/update_tdb/cullpdb.lst -o /data/update_tdb/psichain.lst -d /data/update_tdb/dssp/ -s /data/server_update/src/dsspcmbi -t /data/pgenthreader/tdb/ -u /data/uniref/unirefmain.fasta -b /data/ncbi-blast-2.7.1+/bin/psiblast -v 0.001 -h 2 -m /data/maketdb/src/chkparse -c /data/T-COFFEE_distribution_Version_11.00.8cbe486/bin/binaries/linux/t_coffee -p /data/pdb/ -q /data/cath_data/cath-domain-list-v4_2_0_annotated.txt -r /data/update_tdb/ -f /data/update_tdb/ -a /data/pgenthreader/cath_domain_tdb -y C -e /data/maketdb/bin/parse_source -l /data/cath_data/cath-domain-seqs-S100-v4_1_0.fa
#./auto_psisum >& auto.log
#### HERE ####
chmod uog+rw /data/update_tdb/psichain.lst
/bin/cp -f /data/update_tdb/psichain.lst /data/pgenthreader/tdb/
/bin/cp -f /data/update_tdb/psichain.lst /data/pgenthreader/data/

if ($status != 0) then
    tail -50 auto.log | Mail -s AUTO_PSISUM-FAILED psipred@cs.ucl.ac.uk
    exit
endif

set new_nl = `wc -l < psichain.lst`
set old_nl = `wc -l < psichain.old`

#check that the new list is not > 2% smaller than the old list
if ($new_nl - $old_nl < -500) then
    echo "AUTO_PSISUM-FAILED new_nl < old_nl-500" | Mail -s AUTO_PSISUM-FAILED psipred@cs.ucl.ac.uk
    curl -X POST -H 'Content-type: application/json' --data '{"text":":rage:\n'`uname -n`' AUTOPSISUM-FAILED"}' https://hooks.slack.com/services/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
    exit
endif

cd /data/pgenthreader/tdb/
find  /data/pgenthreader/tdb/ -type f -exec chmod uog+rw {} \;
#remove the old fasta file of all the chains
/bin/rm -f psichain.fasta

#build a new fold library tar file.
echo "psichain.lst" > tar.lst

#for each tdb file that was made move it to the data dir
foreach tdb (`cat psichain.lst`)
	#copy the tdb file to the data dir
    #is this redundant if the make_tdb.pl command sends the tdbs to /webdata/data/tdb/ already?
	#/bin/cp -f $tdb.tdb ../data

	#add the tdb file to the archive
    echo $tdb.tdb >> tar.lst

	#then add the tdb file's sequence to the new fastafile
    /data/server_update/src/tdb2fasta < $tdb.tdb >> psichain.fasta
end
#exit 0
chmod uog+rw psichain.fasta
tar zcf foldlib.tar.gz --files-from tar.lst

#move the list of tdb to the old list for next week's update
/bin/cp -f ./psichain.lst ./psichain.old
/bin/cp -f ./psichain.lst /data/update_tdb/psichain.old
chmod uog+rw /data/update_tdb/psichain.old

#move a copy of the seq file to an old list
/data/server_update/src/remove_blanks.pl psichain.fasta > out.fasta
/bin/mv out.fasta psichain.fasta
chmod uog+rw psichain.fasta

/bin/cp -f ./psichain.fasta ./psichain.fasta.old
/bin/cp -f ./psichain.fasta /data/update_tdb/psichain.fasta.old

#copy the list to the psipred dir and rsync to other worker hosts
#
# Stop remote workers.
# rsync/copy foldlib
# start remote workers
#
#/bin/cp -f psichain.lst /webdata/binaries/current/psipred/
#/bin/cp -f psichain.lst /webdata/data/current/psipred/data/
#chmod uog+rw /webdata/binaries/current/psipred/psichain.lst
#chmod uog+rw /webdata/data/current/psipred/data/psichain.lst

#move list to public web site
# /bin/cp -f psichain.lst /var/www/html/foldlib/

# #copy the fasta file to the data dir
# /bin/cp -f psichain.fasta /webdata/binaries/current/psipred/
# /bin/cp -f psichain.fasta /webdata/data/current/psipred/data/
# /bin/cp -f psichain.fasta /webdata/data/current/blast/db/
# chmod uog+rw /webdata/binaries/current/psipred/psichain.fasta
# chmod uog+rw /webdata/data/current/psipred/data/psichain.fasta
# chmod uog+rw /webdata/data/current/blast/db/psichain.fasta
# cd /webdata/data/current/blast/db/
# /webdata/binaries/current/BLAST/bin/formatdb -i psichain.fasta
#move fasta file to public website
rsync /data/pgenthreader/tdb/psichain.fasta django_worker@bioinfadmin:/var/www/html/downloads/pGenTHREADER/foldlibs/
scp /data/pgenthreader/tdb/psichain.fasta django_worker@bm3:/data/pgenthreader/tdb/
#/bin/cp -f psichain.fasta /var/www/html/foldlib/

#move the fold lib to the public data dir
rsync /data/pgenthreader/tdb/foldlib.tar.gz django_worker@bioinfadmin:/var/www/html/downloads/pGenTHREADER/foldlibs/
scp /data/pgenthreader/tdb/foldlib.tar.gz django_worker@bm3:/data/pgenthreader/tdb/
ssh django_worker@bm3 "cd /data/pgenthreader/tdb/; tar -zxvf foldlib.tar.gz"
#/bin/mv -f foldlib.tar.gz /var/www/html/foldlib
rsync /data/pgenthreader/tdb/psichain.lst django_worker@bioinfadmin:/var/www/html/downloads/pGenTHREADER/foldlibs/
scp /data/pgenthreader/tdb/psichain.lst django_worker@bm3:/data/pgenthreader/tdb/
scp /data/pgenthreader/tdb/psichain.lst django_worker@bm3:/data/pgenthreader/data/
#create all the new images from the fold lib
#No longer needed due to CATH image referencing.
#csh /var/www/cgi-bin/psipred/bin/make_images

# Clean the temp directory
cd /data/update_tdb/
rm -f /data/update_tdb/*.fsa
rm -f /data/update_tdb/*.chk
rm -f /data/update_tdb/*.slx
rm -f /data/update_tdb/*.bls
# /usr/bin/find /webdata/tmp/autoupdate/ -mindepth 1 -mtime +60 -exec rm -rf {} \;

# Inform psipred email address
# wc -l ./psichain.lst | Mail -s AUTOUPDATE-OK psipred@cs.ucl.ac.uk

# echo `uname -n; wc -l ./psichain.lst` | Mail -s "TDBUPDATE-OK" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
curl -X POST -H 'Content-type: application/json' --data '{"text":":smile:\n'`uname -n`' TDBUPDATE-OK"}' https://hooks.slack.com/services/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

# stop workers
# start workers again

#clean temporary files
#rm -f 1*.aux
#rm -f 1*.chk
#rm -f 1*.mn
#rm -f 1*.pn
#rm -f 1*.sn
#rm -f 1*.mtx
#rm -f 1*.fasta
#rm -f 1*.tdb
#rm -f 2*.aux
#rm -f 2*.chk
#rm -f 2*.mn
#rm -f 2*.pn
#rm -f 2*.sn
#rm -f 2*.mtx
#rm -f 2*.fasta
#rm -f 2*.tdb
#rm -f *.aux
#rm -f *.chk
#rm -f *.mn
#rm -f *.pn
#rm -f *.sn
#rm -f *.mtx
#rm -f *.fasta
#rm -f *.tdb
