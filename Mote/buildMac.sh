#!/bin/bash

g++ src/*.cpp -std=c++11 -lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf -llua -lBox2D -o mote_Run
