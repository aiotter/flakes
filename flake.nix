{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    overlays.default = final: prev: { inherit (self.packages.${final.system}) reload; };

    packages = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        default = reload;

        reload = pkgs.buildNpmPackage {
          pname = "reload";
          version = "4.7.0";
          src = pkgs.fetchFromGitHub {
            owner = "alallier";
            repo = "reload";
            rev = "3.3.0";
            hash = "sha256-kbkd+TkTEcUOq62ageUMoHKE+UjDjicvXu4lkNsJVAQ=";
          };
          npmDepsHash = "sha256-x3uTFXQUNCbLITHrJZPpagiO9arAS6wu7+khvkZLcuw=";
          dontNpmBuild = true;

          meta = {
            description = "node module to reload your browser when your code changes";
            homepage = "https://github.com/alallier/reload";
            license = pkgs.lib.licenses.mit;
          };
        };
      });
  };
}
