#!/bin/bash

USER=$1

echo "$USER    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$USER && chmod ug=r /etc/sudoers.d/$USER
