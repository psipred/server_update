#!/bin/sh
find /tmp -maxdepth 1 -type d -ctime +3 -regextype posix-extended -regex ".*.{8}-.{4}-.{4}-.{4}-.{12}" -exec rm -rf "{}" \;
find /tmp/django_worker/ -maxdepth 1 -type d -ctime +2 -exec rm -rf "{}" \;
find /webdata/production_submissons -type f -ctime +15 -exec rm {} \;
