#!/bin/sh

LastID=`dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1`

NextID=$((LastID + 1))

. /etc/rc.common
dscl . create /Users/postgres
dscl . create /Users/postgres RealName "Postgres Account"
dscl . passwd /Users/postgres password
dscl . create /Users/postgres UniqueID $NextID
dscl . create /Users/postgres PrimaryGroupID 20
dscl . create /Users/postgres UserShell /bin/bash
dscl . create /Users/postgres NFSHomeDirectory /Users/postgres
cp -R /System/Library/User\ Template/English.lproj /Users/postgres
chown -R postgres:staff /Users/postgres

