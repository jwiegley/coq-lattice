{
  description = "A reflection-based proof tactic for lattices in Coq";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Build the lattice library for a given coqPackages set
        mkLattice = coqPkgs: coqPkgs.mkCoqDerivation {
          pname = "coq-lattice";
          version = "1.0";
          src = self;
          buildPhase = ''
            make -j$NIX_BUILD_CORES
          '';
          installFlags = [
            "COQLIB=$(out)/lib/coq/${coqPkgs.coq.coq-version}/"
          ];
        };

        # Default Coq version for dev shell and primary build
        coqPkgs = pkgs.coqPackages_8_20;
        lattice = mkLattice coqPkgs;

      in {
        packages = {
          default = lattice;
          coq_8_18 = mkLattice pkgs.coqPackages_8_18;
          coq_8_19 = mkLattice pkgs.coqPackages_8_19;
          coq_8_20 = mkLattice pkgs.coqPackages_8_20;
          coq_9_0 = mkLattice (pkgs.coqPackages_9_0 // {
            mkCoqDerivation = args: pkgs.coqPackages_9_0.mkCoqDerivation (args // {
              propagatedBuildInputs = [ pkgs.coqPackages_9_0.stdlib ];
            });
          });
        };

        checks = {
          # Primary build with warnings as errors
          build = lattice;

          # Format and style checks
          format = pkgs.runCommand "format-check" {
            src = self;
          } ''
            cd $src
            echo "==> Checking for tabs..."
            if grep -nP '\t' Lattice.v; then
              echo "ERROR: Found tabs (use spaces)" && exit 1
            fi
            echo "==> Checking for trailing whitespace..."
            if grep -nP '\s+$' Lattice.v; then
              echo "ERROR: Found trailing whitespace" && exit 1
            fi
            echo "==> Checking for trailing newline..."
            if [ -n "$(tail -c 1 Lattice.v)" ]; then
              echo "ERROR: File does not end with newline" && exit 1
            fi
            echo "Format checks passed"
            touch $out
          '';

          # Lint: check for issues beyond what the compiler catches
          lint = pkgs.runCommand "lint-check" {
            src = self;
          } ''
            cd $src
            echo "==> Checking for Admitted/admit usage..."
            if grep -nE '^\s*(Admitted|admit)\b' Lattice.v; then
              echo "WARNING: Found Admitted/admit in Lattice.v (noted, not blocking)"
            fi
            echo "==> Checking for trailing whitespace..."
            if grep -nP '\s+$' Lattice.v; then
              echo "ERROR: Found trailing whitespace" && exit 1
            fi
            echo "Lint checks passed"
            touch $out
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = [
            coqPkgs.coq
            pkgs.lefthook
            pkgs.python3
            pkgs.gnumake
          ];
          shellHook = ''
            echo "coq-lattice dev shell"
            echo "  Coq $(coqc --version | head -1)"
            echo "  Run 'make' to build"
            echo "  Run 'make check' for all checks"
            echo "  Run 'make timing' for performance profiling"
          '';
        };
      }
    );
}
