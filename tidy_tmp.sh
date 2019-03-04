#!/bin/sh
find /tmp -maxdepth 1 -type d -ctime +10 -regextype posix-extended -regex ".*.{8}-.{4}-.{4}-.{4}-.{12}" -exec rm -rf "{}" \;
