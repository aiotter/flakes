```bash
# Installs "esp" toolchain
$ nix run github:aiotter/flakes/esp-rust#install

# Or manually
$ nix build github:aiotter/flakes/esp-rust#rust.sysroot --out-link ${RUSTUP_HOME:-~/.rustup}/toolchains/esp
```
