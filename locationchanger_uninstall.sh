#!/bin/bash

INSTALL_DIR=/usr/local/bin
SCRIPT_NAME=$INSTALL_DIR/locationchanger

LAUNCH_AGENTS_DIR=$HOME/Library/LaunchAgents
PLIST_NAME=$LAUNCH_AGENTS_DIR/LocationChanger.plist

sudo rm -rf $SCRIPT_NAME
sudo rm -rf $PLIST_NAME
