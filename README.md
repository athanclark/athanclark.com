# athanclark.com

A basic static-site generated website.

## Prereq's

You'll need the following tools installed:

- [nix](https://nixos.org/download)
- [ltext](https://ltext.github.io/)

After they're installed, you'll have to enter a nix shell, then install the node
dependencies.

```bash
nix-shell
npm i
```

## Building

To build the site manually, run the build script:

```bash
./build.sh
```

## Watch

Alternatively, you can use `watchexec` (included in the nix shell) to rebuild your
changes:

```bash
watchexec -w pages -w template -w styles -w build.sh ./build.sh
```
