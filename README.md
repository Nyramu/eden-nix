# eden-nix

[![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-78C0E8?logo=nixos&logoColor=white)](https://nixos.org)
[![License: GPL-3.0-or-later](https://img.shields.io/badge/License-GPL--3.0--or--later-blue.svg)](./LICENSE)

Nix flake for the [Eden](https://eden-emu.dev) Nintendo Switch emulator.

## Upstream

|             |                                                         |
| ----------- | ------------------------------------------------------- |
| **Project** | [eden-emu/eden](https://git.eden-emu.dev/eden-emu/eden) |
| **License** | GPL-3.0-or-later                                        |

## What is this?

A Nix flake that provides an Home Manager module and ready-to-use packages.

## Installation

Add this flake input:

```nix
{
  inputs = {
    eden.url = "github:Nyramu/eden-nix";
  };
}
```

Then import the Home Manager module:

```nix
{
  imports = [ inputs.eden.homeModules.default ];
}
```

### Cache

This flake sets `extra-substituters` and `extra-trusted-public-keys` via
`nixConfig`, but you can set the cache manually by adding the following in your
`configuration.nix`:

```nix
{
  nix.settings = rec {
    substituters = [ "https://eden-nix.cachix.org" ];
    trusted-substituters = substituters;
  
    trusted-public-keys = [
      "eden-nix.cachix.org-1:BrC9tVNflA7yeLft5i2SjZTlGs46cBpUgULgHbMj8/E="
    ];
  };
}
```

## Usage

Enable Eden via the Home Manager module:

```nix
{ ... }:

{
  programs.eden = {
    enable = true;
  };
}
```

This module uses the standard amd64 build by default, which is stored on Cachix.
You can change the package by doing:

```nix
{ inputs, pkgs, ... }:

{
  programs.eden = {
    enable = true;
    package = inputs.eden.packages.${pkgs.stdenv.hostPlatform.system}.zen4;
  };
}
```

Currently available packages:

- `default`: Standard amd64 binary
- `zen4`: Zen 4 + PGO optimizations wrapped Appimage

Every package installs Eden (binary or wrapped Appimage, depending on the
package) and creates a `.desktop` entry. You can launch it from your application
launcher or terminal: `$ eden`

## License

This packaging flake is [GPL-3.0-or-later](./LICENSE) licensed (matches
upstream). Upstream Eden is
[GPL-3.0-or-later](https://git.eden-emu.dev/eden-emu/eden/src/branch/master/LICENSE.txt).
