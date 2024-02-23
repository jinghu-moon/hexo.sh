#!/bin/bash
FOLDER_PATH=/test/1/
if [ -d "$FOLDER_PATH" ]; then
  exit
else
  mkdir $FOLDER_PATH
fi
