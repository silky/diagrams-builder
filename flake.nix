{
  description = ".";

  inputs.stacklock2nix.url = "github:cdepillabout/stacklock2nix/main";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, stacklock2nix }:
    let
      # System types to support.
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor =
        forAllSystems (system: import nixpkgs { inherit system; overlays = [ stacklock2nix.overlay self.overlay ]; });
    in
    {
      overlay = final: prev: {
        diagrams-builder-stacklock = final.stacklock2nix {
          stackYaml = ./stack.yaml;

          baseHaskellPkgSet = final.haskell.packages.ghc902;
          additionalHaskellPkgSetOverrides = hfinal: hprev: {
          };

          # Additional packages that should be available for development.
          additionalDevShellNativeBuildInputs = stacklockHaskellPkgSet: [
            final.cabal-install
            final.stack
          ];

          all-cabal-hashes = final.fetchurl {
            name = "all-cabal-hashes";
            url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/9ab160f48cb535719783bc43c0fbf33e6d52fa99.tar.gz";
            sha256 = "sha256-QC07T3MEm9LIMRpxIq3Pnqul60r7FpAdope6S62sEX8=";
          };
        };

        # One of our local packages.
        diagrams-builder-app = final.diagrams-builder-stacklock.pkgSet.diagrams-builder-app;

        # You can also easily create a development shell for hacking on your local
        # packages with `cabal`.
        diagrams-builder-dev-shell = final.diagrams-builder-stacklock.devShell;
      };

      packages = forAllSystems (system: {
        diagrams-builder-app = nixpkgsFor.${system}.diagrams-builder-app;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.diagrams-builder-app);

      devShells = forAllSystems (system: {
        diagrams-builder-dev-shell = nixpkgsFor.${system}.diagrams-builder-dev-shell;
      });

      devShell = forAllSystems (system: self.devShells.${system}.diagrams-builder-dev-shell);
    };
}
