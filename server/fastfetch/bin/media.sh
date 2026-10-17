#!/bin/sh
# Free space on the network media share (first CIFS/NFS mount, found at runtime so no
# path lives in git). A network mount can hang if its host is down, so give df one
# second and print "?" instead of stalling the login.
MOUNT=$(findmnt -rn -t cifs,smb3,nfs,nfs4 -o TARGET 2>/dev/null | head -1)
[ -n "$MOUNT" ] || { echo "not mounted"; exit 0; }
timeout 1 df -h --output=avail,size,pcent "$MOUNT" 2>/dev/null \
  | awk 'NR==2 { printf "%s free of %s (%s used)\n", $1, $2, $3; ok=1 } END { if (!ok) print "?" }'
