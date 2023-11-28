---
title: Wage Calculator
title-suffix: Portfolio
keywords: [Finance, WebAssembly, Rust, Yew, SPA, Serverless]
date: 2023-10-04 -- 2023-10-06
website: https://wagecalculator.github.io
abstract-title: Summary
abstract:
  This web application is a simple wage calculator - a tool to compare wage rates for common
  pay schedules. It's written entirely in Rust, doesn't have a complex server, and is hosted
  on a GitHub page.
---

## Notable Features

- The user interface is written with [Yew](https://yew.rs/) (a [Rust](https://www.rust-lang.org/)
  library).
- The front-end is a WebAssembly powered rendition of the user-interface.
- The back-end renders the same user-interface to HTML, which gets
  [hydrated](https://en.wikipedia.org/wiki/Hydration_(web_development)) by the front-end.
- Simple, light-weight UI styling through [Pico.css](https://picocss.com/).

## Code Snippets

The majority of the user interface looks like the following:

```rust
// ...
<article>
    <label for="biweekly-rate">
        { "Bi-Weekly" }
        <input
            type="number"
            class="currency"
            id="biweekly-rate"
            value={ format!("{:.2}", state_value.annual / (WEEKS_PER_YEAR / 2.0)) }
            onchange={ on_change_biweekly }
        />
    </label>
</article>
// ...
```

Where the state is a very simple Struct:

```rust
struct State {
    annual: f64,
    hourly: f64,
    hours: f64,
}
```

Most of the code just follows that simple tactic. The build process is a bit more interesting
though. It uses [λtext](/portfolio/ltext.html) to splice the front-end code with the back-end
code:

```bash
#!/bin/bash

trunk build && \
    # First it creates a parameter on /docs/index.html
    { echo '{{ body }}'; cat docs/index.html; } > docs/index.html.tmp && \
    mv docs/index.html.tmp docs/index.html && \
    # then uses the parameter just after <body>
    sed -i '/<body>/a {{ body }}' docs/index.html && \
    # generates the front-end code
    cargo run --features hydration > docs/body.html && \
    # then inserts it, replacing the parameter to docs/index.html
    ltext 'docs/index.html docs/body.html' --raw docs/body.html > docs/index.html.tmp && \
    rm docs/body.html && \
    mv docs/index.html.tmp docs/index.html
    # all done
```

Though this was a very simple project and did not take me a great deal of time, it was still
very interesting and I found it to be a great exercise.
