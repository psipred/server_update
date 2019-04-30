#!/bin/sh
find /tmp -maxdepth 1 -type d -ctime +3 -regextype posix-extended -regex ".*.{8}-.{4}-.{4}-.{4}-.{12}" -exec rm -rf "{}" \;
find /tmp/django_worker/ -maxdepth 1 -type d -ctime +2 -exec rm -rf "{}" \;

echo "finished" | Mail -s "TMP CLEANED" -r psipred@cs.ucl.ac.uk -S smtp="smtp.cs.ucl.ac.uk:25" psipred@cs.ucl.ac.uk
