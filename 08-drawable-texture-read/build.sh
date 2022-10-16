#!/usr/bin/env bash
clang main.m -o main -Wall -framework Cocoa -framework Metal -framework MetalKit -g 
xcrun -sdk macosx metal -c shaders.metal -o MyLibrary.air
xcrun -sdk macosx metallib MyLibrary.air -o MyLibrary.metallib
