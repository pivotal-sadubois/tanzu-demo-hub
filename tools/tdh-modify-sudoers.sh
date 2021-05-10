#!/bin/bash

USER=$1

echo > /dev/null 2>&1
echo "$USER    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$USER && chmod 0440 /etc/sudoers.d/$USER
#sed -i 's/#includedir/includedir/' /etc/sudoers.d
