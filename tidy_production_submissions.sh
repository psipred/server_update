#!/bin/sh
find /webdata/production_submissons -type f -ctime +15 -exec rm {} \;
