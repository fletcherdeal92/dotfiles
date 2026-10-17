#!/bin/sh
# Running / total Docker containers
running=$(docker ps -q 2>/dev/null | wc -l) || { echo "?"; exit 0; }
total=$(docker ps -aq 2>/dev/null | wc -l)
echo "$running running of $total"
