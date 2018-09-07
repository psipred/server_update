cd /webdata/data/pdb;
rsync -rlpt -v -z --delete rsync.ebi.ac.uk::pub/databases/pdb/data/structures/divided/pdb/ /webdata/data/pdb/
mv */* ./
