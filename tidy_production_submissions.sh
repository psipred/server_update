#!/bin/sh
find /webdata/production_submissions -type f -ctime +15 -exec rm {} \;
