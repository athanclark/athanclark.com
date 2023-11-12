#!/bin/bash

rm -r build/
rm -r docs/
mkdir -p build/
mkdir -p build/idents/
mkdir -p build/titles/
mkdir -p build/descs/
mkdir -p build/metas/
mkdir -p build/metas/blog/
mkdir -p build/stage1/
mkdir -p build/stage1/blog/
mkdir -p build/stage2/
mkdir -p build/stage2/blog/
mkdir -p docs/
mkdir -p docs/blog/

generatepages() {
    local page
    local title
    local actualtitle
    local desc
    local ident
    local post
    local meta

    # Create the sitenav
    if ! test -f template/top-level-pages.md; then
        touch template/top-level-pages.md
    fi

    for page in pages/*.md; do
        page=`basename $page .md`
        pandoc -s --template template/title.html pages/$page.md -o build/titles/$page.title -t html
        title=build/titles/$page.title
        actualtitle=`cat $title`
        pandoc -s --template template/desc.html pages/$page.md -o build/descs/$page.desc -t html
        desc=build/descs/$page.desc
        ident=build/idents/$page
        echo "$page" > $ident

        # include page in sitenav if it doesn't exist
        if grep -Fq "$page.html" template/top-level-pages.md; then
            echo "$page.html found"
        else
            echo "- [$actualtitle](/$page.html)" >> template/top-level-pages.md
        fi

        # build the page's body
        # FIXME table of contents should only exist for blog posts
        # pandoc --toc -s --template template/pandoc.html pages/$page.md -o build/stage1/$page.html
        pandoc pages/$page.md -o build/stage1/$page.html

        if [ $page = "blog" ]; then
            # Create a list of blog posts
            echo "## Blog Posts" > build/stage1/blog-posts.md

            for post in pages/blog/*.md; do
                # TODO create a latest-posts widgit, append to blog page
                post=`basename $post .md`
                meta=build/metas/blog/$post.html

                # Build the actual blog post's page
                pandoc --toc -s --template template/blog-post.html pages/blog/$post.md \
                       -o build/stage1/blog/$post.html

                # Build the blog post's meta
                pandoc -s --template template/meta.html pages/blog/$post.md \
                       -o $meta

                ltext --raw $meta \
                      --raw build/idents/blog \
                      --raw build/stage1/blog/$post.html \
                      "template/wrapper.html $meta build/idents/blog build/stage1/blog/$post.html" \
                      > build/stage2/blog/$post.html

                # FIXME add correct blog post title as name, and date & stuff
                echo "- [$post](/blog/$post.html)" >> build/stage1/blog-posts.md
            done

            pandoc build/stage1/blog-posts.md -o build/stage1/blog-posts.html
            cat build/stage1/blog.html build/stage1/blog-posts.html > build/stage1/blog-tmp.html
            mv build/stage1/blog-tmp.html build/stage1/blog.html
        fi

        meta=build/metas/$page.html

        # Build the blog page's meta
        pandoc -s --template template/meta.html pages/$page.md \
                -o $meta

        ltext --raw $meta \
              --raw $ident \
              --raw build/stage1/$page.html \
              "template/wrapper.html $meta $ident build/stage1/$page.html" \
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
    for post in build/stage2/blog/*.html; do
        post=`basename $post .html`
        ltext --raw build/sitenav.html "build/stage2/blog/$post.html build/sitenav.html" \
              > docs/blog/$post.html
    done
}

generatepages

sass styles/main.scss docs/main.css

css-html-js-minify --overwrite docs/

cp -r images docs/images
