#!/bin/bash

echo "--------------------------------"
echo "  Building athanclark.com"
echo "--------------------------------"

rm -r build/
rm -r docs/
mkdir -p build/
mkdir -p build/idents/
mkdir -p build/titles/{,blog/,portfolio/}
mkdir -p build/descs/{,blog/,portfolio/}
mkdir -p build/dates/{,blog/,portfolio/}
mkdir -p build/metas/{,blog/,portfolio/}
mkdir -p build/stage1/{,blog/,portfolio/}
mkdir -p build/stage2/{,blog/,portfolio/}
mkdir -p docs/{,blog/,portfolio/}

generateblogposts() {
    local title
    local actualtitle
    local desc
    local actualdesc
    local date
    local actualdate
    local ident
    local post
    local meta
    # Create a list of blog posts

    for post in pages/blog/*.md; do
        # TODO create a latest-posts widgit, append to blog page
        post=$(basename "$post" .md)
        pandoc -s --template template/title.html \
                pages/blog/"$post".md -o build/titles/blog/"$post".title -t html
        title=build/titles/blog/$post.title
        actualtitle=$(cat "$title")
        pandoc -s --template template/desc.html \
                pages/blog/"$post".md -o build/descs/blog/"$post".desc -t html
        desc=build/descs/blog/$post.desc
        actualdesc=$(cat "$desc")
        pandoc -s --template template/date.html \
                pages/blog/"$post".md -o build/dates/blog/"$post".date -t html
        date=build/dates/blog/$post.date
        actualdate=$(cat "$date")
        meta=build/metas/blog/$post.html

        # Build the actual blog post's page
        pandoc --toc -s --template template/blog-post.html pages/blog/"$post".md \
                -o build/stage1/blog/"$post".html

        # Build the blog post's meta
        pandoc -s --template template/meta.html pages/blog/"$post".md \
                -o "$meta"

        ltext --raw "$meta" \
                --raw build/idents/blog \
                --raw build/stage1/blog/"$post".html \
                "template/wrapper.html $meta build/idents/blog build/stage1/blog/$post.html" \
                > build/stage2/blog/"$post".html

        echo -e "$actualdate\t$actualtitle\t/blog/$post.html\t$actualdesc" >> build/stage1/blog-posts.md
    done

    sort -r build/stage1/blog-posts.md > build/stage1/blog-posts.md.tmp
    echo "## Blog Posts" | cat build/stage1/blog-posts.md.tmp > build/stage1/blog-posts.md
    rm build/stage1/blog-posts.md.tmp
    sed -i -E 's/^(.+)\t(.+)\t(.+)\t(.+)$/- [\2](\3) - \1\n  <br \/>\n  \4/' build/stage1/blog-posts.md
    pandoc build/stage1/blog-posts.md -o build/stage1/blog-posts.html
    cat build/stage1/blog.html build/stage1/blog-posts.html > build/stage1/blog-tmp.html
    mv build/stage1/blog-tmp.html build/stage1/blog.html
}

generateportfolioprojects() {
    local project
    local title
    local actualtitle
    local desc
    local actualdesc
    local meta
    # Create a list of projects
    # echo "## Projects" > build/stage1/portfolio-projects.md

    for project in pages/portfolio/*.md; do
        # TODO create a latest-projects widgit, append to portfolio page
        project=$(basename "$project" .md)
        pandoc -s --template template/title.html \
                pages/portfolio/"$project".md -o build/titles/portfolio/"$project".title -t html
        title=build/titles/portfolio/$project.title
        actualtitle=$(cat "$title")
        pandoc -s --template template/desc.html \
                pages/portfolio/"$project".md -o build/descs/portfolio/"$project".desc -t html
        desc=build/descs/portfolio/$project.desc
        actualdesc=$(cat "$desc")
        meta=build/metas/portfolio/$project.html

        # Build the actual portfolio project's page
        pandoc --toc -s --template template/portfolio-project.html pages/portfolio/"$project".md \
                -o build/stage1/portfolio/"$project".html

        # Build the portfolio project's meta
        pandoc -s --template template/meta.html pages/portfolio/"$project".md \
                -o "$meta"

        ltext --raw "$meta" \
                --raw build/idents/portfolio \
                --raw build/stage1/portfolio/"$project".html \
                "template/wrapper.html $meta build/idents/portfolio build/stage1/portfolio/$project.html" \
                > build/stage2/portfolio/"$project".html

        # TODO make categories generate automatically; currently manually done
        # via portfolio.md
        # # FIXME add correct project title as name, and date & stuff
        # echo "- [$actualtitle](/portfolio/$project.html)" >> build/stage1/portfolio-projects.md
        # echo "  <br />" >> build/stage1/portfolio-projects.md
        # echo "  $actualdesc" >> build/stage1/portfolio-projects.md
    done

    # pandoc build/stage1/portfolio-projects.md -o build/stage1/portfolio-projects.html
    # cat build/stage1/portfolio.html build/stage1/portfolio-projects.html > build/stage1/portfolio-tmp.html
    # mv build/stage1/portfolio-tmp.html build/stage1/portfolio.html
}

generatepages() {
    local page
    local title
    local actualtitle
    local desc
    local actualdesc
    local ident
    local meta

    # Create the sitenav
    if ! test -f template/top-level-pages.md; then
        touch template/top-level-pages.md
    fi

    for page in pages/*.md; do
        page=$(basename "$page" .md)
        pandoc -s --template template/title.html pages/"$page".md -o build/titles/"$page".title -t html
        title=build/titles/$page.title
        actualtitle=$(cat "$title")
        pandoc -s --template template/desc.html pages/"$page".md -o build/descs/"$page".desc -t html
        desc=build/descs/$page.desc
        ident=build/idents/$page
        echo "$page" > "$ident"
        meta=build/metas/$page.html

        # include page in sitenav if it doesn't exist
        if grep -Fq "$page.html" template/top-level-pages.md; then
            echo "$page.html found"
        else
            echo "- [$actualtitle](/$page.html)" >> template/top-level-pages.md
        fi

        # build the page's body
        # FIXME table of contents should only exist for blog posts
        # pandoc --toc -s --template template/pandoc.html pages/$page.md -o build/stage1/$page.html
        pandoc pages/"$page".md -o build/stage1/"$page".html

        # Build the blog page's meta
        pandoc -s --template template/meta.html pages/"$page".md \
                -o "$meta"

        # Blog
        if [ "$page" = "blog" ]; then
            generateblogposts
        fi

        # Portfolio
        if [ "$page" = "portfolio" ]; then
            generateportfolioprojects
        fi

        ltext --raw "$meta" \
              --raw "$ident" \
              --raw build/stage1/"$page".html \
              "template/wrapper.html $meta $ident build/stage1/$page.html" \
              > build/stage2/"$page".html
    done

    # Translate the sitenav into html
    pandoc template/top-level-pages.md -o build/sitenav.html

    # Include the sitenav in every page
    for page in build/stage2/*.html; do
        page=$(basename "$page" .html)
        ltext --raw build/sitenav.html "build/stage2/$page.html build/sitenav.html" \
              > docs/"$page".html
    done
    for post in build/stage2/blog/*.html; do
        post=$(basename "$post" .html)
        ltext --raw build/sitenav.html "build/stage2/blog/$post.html build/sitenav.html" \
              > docs/blog/"$post".html
    done
    for project in build/stage2/portfolio/*.html; do
        project=$(basename "$project" .html)
        ltext --raw build/sitenav.html "build/stage2/portfolio/$project.html build/sitenav.html" \
              > docs/portfolio/"$project".html
    done
}

generatepages

sass -q styles/main.scss docs/main.css

css-html-js-minify --quiet --overwrite docs/
css-html-js-minify --quiet --hash docs/

# FIXME make ltext work within lines
cachebustcss() {
    local css
    cd docs/
    css=$(ls main-*.min.css)
    cd ../
    sed -i "s/STYLES/\/$css/g" docs/*.html
    sed -i "s/STYLES/\/$css/g" docs/**/*.html
}

cachebustcss

cp -r images docs/images
