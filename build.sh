#!/bin/bash
cd ~/Documents/Code/Paddle
pasmo --name paddle --tapbas -1 Paddle.asm Paddle.tap > debug.txt
retval=$?
if [ $retval -eq 0 ]; then
    /Applications/Fuse\ for\ Mac\ OS\ X/Fuse.app/Contents/MacOS/Fuse Paddle.tap
fi
