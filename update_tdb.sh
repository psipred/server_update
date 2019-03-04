#!/bin/tcsh

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
chmod uog+rw /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/psichain.lst
/bin/cp -f /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/psichain.lst /scratch1/NOT_BACKED_UP/dbuchan/foldlib/

if ($status != 0) then
    tail -50 auto.log | Mail -s AUTO_PSISUM-FAILED psipred@cs.ucl.ac.uk
    exit
endif

set new_nl = `wc -l < psichain.lst`
set old_nl = `wc -l < psichain.old`

#check that the new list is not > 2% smaller than the old list
if ($new_nl - $old_nl < -500) then
    echo "AUTO_PSISUM-FAILED new_nl < old_nl-500" | Mail -s AUTO_PSISUM-FAILED psipred@cs.ucl.ac.uk
    exit
endif

cd /scratch1/NOT_BACKED_UP/dbuchan/foldlib/
chmod uog+rw /scratch1/NOT_BACKED_UP/dbuchan/foldlib/*
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
    /scratch0/NOT_BACKED_UP/dbuchan/Code/Update_scripts/src/tdb2fasta < $tdb.tdb >> psichain.fasta
end
#exit 0
chmod uog+rw psichain.fasta
tar zcf foldlib.tar.gz --files-from tar.lst

#move the list of tdb to the old list for next week's update
/bin/cp -f ./psichain.lst ./psichain.old
/bin/cp -f ./psichain.lst /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/psichain.old
chmod uog+rw /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/psichain.old

#move a copy of the seq file to an old list
/scratch0/NOT_BACKED_UP/dbuchan/Code/Update_scripts/src/remove_blanks.pl psichain.fasta > out.fasta
/bin/mv out.fasta psichain.fasta
chmod uog+rw psichain.fasta

/bin/cp -f ./psichain.fasta ./psichain.fasta.old
/bin/cp -f ./psichain.fasta /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/psichain.fasta.old

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
rsync /scratch1/NOT_BACKED_UP/dbuchan/foldlib tdb_sync@bioinfadmin:/var/www/html/downloads/pGenTHREADER/foldlibs/
#/bin/cp -f psichain.lst /var/www/html/foldlib/

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
rsync /webdata/data/tdb/psichain.fasta tdb_sync@bioinfadmin:/var/www/html/downloads/pGenTHREADER/foldlibs/
#/bin/cp -f psichain.fasta /var/www/html/foldlib/

#move the fold lib to the public data dir
rsync /webdata/data/tdb/foldlib.tar.gz tdb_sync@bioinfadmin:/var/www/html/downloads/pGenTHREADER/foldlibs/
#/bin/mv -f foldlib.tar.gz /var/www/html/foldlib

#create all the new images from the fold lib
#No longer needed due to CATH image referencing.
#csh /var/www/cgi-bin/psipred/bin/make_images

# Clean the temp directory
rm -f /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/*.fsa
rm -f /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/*.chk
rm -f /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/*.slx
rm -f /scratch0/NOT_BACKED_UP/dbuchan/tdb_update/*.bls
# /usr/bin/find /webdata/tmp/autoupdate/ -mindepth 1 -mtime +60 -exec rm -rf {} \;

# Inform psipred email address
cd /webdata/data/autoupdate/
wc -l ./psichain.lst | Mail -s AUTOUPDATE-OK psipred@cs.ucl.ac.uk

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
