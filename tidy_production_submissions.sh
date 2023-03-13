#!/bin/sh
# find /webdata/production_submissions -type f -ctime +15 -exec rm {} \;
find /webdata/production_submissions -type f -ctime +7 -exec rm {} \;

# echo `uname -n` | Mail -s "PRODUCTION SUBMISSION CLEANED" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
curl -X POST -H 'Content-type: application/json' --data '{"text":":smile:\n'`uname -n`' PRODUCTION SUBMISSION CLEANED"}' https://hooks.slack.com/services/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
