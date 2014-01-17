#!/bin/sh

# symlink all files with dots prefixed on them to the home directory
find `pwd` -name ".*" -type f -exec ln -sfn {} ~/ \;
echo 'source ~/.phils_bash_settings' >> ~/.bash_profile

# create a bin directory
mkdir -p ~/bin

# symlink files in bin directory
find `pwd`/bin -type f -exec ln -sfn {} ~/bin/ \; 
