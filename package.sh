#!/bin/bash

# Build run.n
cd tools/runsrc
haxe run.hxml
cd ../..

# Zip haxigniter and test it with haxelib
OUTPUT=${1:-haxigniter.zip}
rm -f $OUTPUT
zip -x .git -r $OUTPUT *
haxelib test $OUTPUT
