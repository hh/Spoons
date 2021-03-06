#!/bin/bash

mkdir -p .docs_tmp
../hammerspoon_app/scripts/docs/bin/build_docs.py -e ..//hammerspoon_app/scripts/docs/templates/ -o .docs_tmp -i "Hammerspoon Spoons" -j -t -n Source
cp ..//hammerspoon_app/scripts/docs/templates/{docs.css,jquery.js} .docs_tmp/html/
mv .docs_tmp/html/* docs/
mv .docs_tmp/docs{,_index}.json docs/
