#!/bin/sh
find /webdata/production_submissions -type f -ctime +15 -exec rm {} \;

echo `uname -n` | Mail -s "PRODUCTION SUBMISSION CLEANED" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
curl -X POST -H 'Content-type: application/json' --data '{"text":":smile:\nPRODUCTION SUBMISSION CLEANED"}' https://hooks.slack.com/services/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
