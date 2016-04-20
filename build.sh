#!/bin/bash
pasmo --name paddle --tapbas -1 Paddle.asm Paddle.tap > debug.txt
retval=$?
if [ $retval -eq 0 ]; then
    /Applications/Spectrum\ Emulators/Fuse.app/Contents/MacOS/Fuse Paddle.tap
fi
