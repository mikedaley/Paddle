#!/bin/bash

echo -ne "Assembling file:" $1 "\n"
tapFile=$(basename $1 .asm).tap
echo -ne "Generating TAP file:" $tapFile "\n"
echo -ne "************************************************************************\n\n"
/usr/local/bin/pasmo --tapbas -1 "$1" "$tapFile" >> debug.txt
