#!/bin/sh

if [ -z "$1" ]; then
	echo "no arguments provided"
	return
fi

mkdir -p ~/.icons
if cp -r "linux/$1" ~/.icons/; then
	echo "Xcursor.theme: $1" >> ~/.Xresources
	echo "Xcursor.size:  20" >> ~/.Xresources
	echo "updated .Xresources"
	xrdb -merge ~/.Xresources
else
	echo "input linux/$1 does not exist"
fi
