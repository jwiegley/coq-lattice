args@{ version ? "lattice_8_15" }:
(import ./default.nix args).${version}
