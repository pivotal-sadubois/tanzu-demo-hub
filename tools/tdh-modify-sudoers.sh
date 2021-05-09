#!/bin/bash

USER=$1

echo "$USER    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$USER && chmod 440 /etc/sudoers.d/$USER
