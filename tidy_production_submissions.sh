#!/bin/sh
find /webdata/production_submissions -type f -ctime +15 -exec rm {} \;

echo `uname -n` | Mail -s "PRODUCTION SUBMISSION CLEANED" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
