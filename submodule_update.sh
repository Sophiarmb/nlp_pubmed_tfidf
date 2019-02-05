#!/bin/bash

# Update the GitHub submodules to retrieve latest content
git submodule foreach git pull origin master
git submodule foreach git checkout master
