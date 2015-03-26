#!/bin/bash
echo MANIFEST >MANIFEST

l=" README Build.PL Changes $(find lib -name '*.pm') $(find bin -name '*.pl') $(find t -type f | grep -v \.svn)"
for f in $l; do 
  echo $f >> MANIFEST
done
