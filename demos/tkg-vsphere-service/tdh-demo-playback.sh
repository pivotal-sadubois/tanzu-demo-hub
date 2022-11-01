#!/bin/bash
# ============================================================================================
# File: ........: tdh-demo-playback.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Play an asciinema recording
# ============================================================================================

if [ ! -f /usr/local/bin/asciinema -a ! -f /opt/homebrew/bin/asciinema -a ! -f /usr/bin/asciinema ]; then 
  echo "ERROR: asciinema is not installed, please install it first:"
  echo "       => brew update"
  echo "       => brew install asciinema"
  exit 1
fi

if [ "$1" == "" ]; then 
  echo "USAGE: $0 <asciinema.cast>"; exit 1
fi

DEMO_CAST=$1

echo ""
echo "tdh-demo-playback.sh - TDH Demo Playback"
echo ""
echo "INFO: The asciinema playback will start with an empty screen to give you time to prepare"
echo "      ie. on video conference to share the screen. Just hit 'enter' to start the playback"
echo "      You can press 'space' to pause/continue the playback at anytime."
echo ""
echo "      <press 'return' to start the playback>'"; read x

clear; read x; asciinema play $DEMO_CAST
