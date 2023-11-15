# athanclark.com

A basic static-site generated website.

## Prereq's

You'll need the following tools installed:

- [nix](https://nixos.org/download)
- [ltext](https://ltext.github.io/)

Nix provides all the other dependencies for the build process of this website, however, it may
take a while for nix to compile and build all of the required dependencies. You can get them
in advance by running `nix-shell`, but it may take quite some time (multiple hours)
for everything to build.

### CSS Libraries

This page uses [pico.css](https://picocss.org) for its Sass library. To add it, you can enter
a nix shell and tell NPM to fetch the dependency:

```bash
nix-shell
npm i
```

## Building

To build the site manually, run the build script:

```bash
nix-shell --command "./build.sh"
```

## Lint

You can also validate the code - currently it just checks the best practices of the BASH scripts,
and performs a link checker:

> Note, this must be run while serving the website for the link checker to behaive correctly.
> Currently it's hardcoded to `localhost:8000`.

```bash
nix-shell --command "./lint.sh"
```

## Watch

Alternatively, you can use the watch script to run `build.sh` whenever source files change:

```bash
nix-shell --command "./watch.sh"
```

## Serve

You can also serve the generated output locally:

```bash
nix-shell --command "./serve.sh"
```
