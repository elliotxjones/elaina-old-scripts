#!/bin/bash

#    --highlight-style ~/bin/custom.theme \
pandoc "$1" \
    -f gfm \
    -V linkcolor:blue \
    -V geometry:a4paper \
    -V geometry:margin=2cm \
    -V mainfont="DejaVu Serif" \
    -V monofont="DejaVu Sans Mono" \
    --pdf-engine=xelatex \
    --highlight-style ~/bin/custom.theme \
    --include-in-header ~/bin/chapter-break.tex \
    --include-in-header ~/bin/inline-code.tex \
    --include-in-header ~/bin/bullet-list.tex \
    --css=github-pandoc.css \
    -o "$2"
