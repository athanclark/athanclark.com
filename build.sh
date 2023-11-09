#!/bin/bash

rm -r build/
rm -r docs/
mkdir -p build/
mkdir -p build/incomplete/
mkdir -p build/stage1/
mkdir -p build/stage2/
mkdir -p docs/

generatepages() {
    local page
    local title
    local actualtitle
    local desc

    # Create the sitenav
    if ! test -f template/top-level-pages.md; then
        touch template/top-level-pages.md
    fi

    for page in pages/*.md; do
        page=`basename $page .md`
        title=pages/$page.title
        if ! test -f $title; then
            echo $page > $title
        fi
        actualtitle=`cat $title`
        desc=pages/$page.desc
        if ! test -f $desc; then
            touch $desc
        fi

        # include page in sitenav if it doesn't exist
        if grep -Fq "$page.html" template/top-level-pages.md; then
            echo "$page.html found"
        else
            echo "- [$actualtitle]($page.html)" >> template/top-level-pages.md
        fi

        # build the page's body
        # FIXME table of contents should only exist for blog posts
        pandoc --toc -s --template template/pandoc.html pages/$page.md -o build/stage1/$page.html
        ltext --raw $title --raw $desc \
              "template/wrapper.html $title $desc build/stage1/$page.html" \
              > build/stage2/$page.html
    done

    # Translate the sitenav into html
    pandoc template/top-level-pages.md -o build/sitenav.html

    # Include the sitenav in every page
    for page in build/stage2/*.html; do
        page=`basename $page .html`
        ltext --raw build/sitenav.html "build/stage2/$page.html build/sitenav.html" \
              > docs/$page.html
    done
}

generatepages

sass styles/main.scss docs/main.css

css-html-js-minify --overwrite docs/
