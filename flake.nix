{
  description = "youtube-dl";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    youtube-dl = {
      url = "github:ytdl-org/youtube-dl/master";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, youtube-dl }:
    {
      overlays.default = final: prev: {
        youtube-dl = self.packages.${prev.system}.default;
      };
    } // flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          pythonPackage = pkgs.python310Packages;
        in
        rec {
          packages.default = pythonPackage.buildPythonPackage rec {
            pname = "youtube-dl";
            version = with youtube-dl; "unstable-${builtins.substring 0 4 lastModifiedDate}-${builtins.substring 4 2 lastModifiedDate}-${builtins.substring 6 2 lastModifiedDate}";
            src = youtube-dl;

            patches = [
              (builtins.toFile "version.patch" ''
                --- a/youtube_dl/version.py
                +++ b/youtube_dl/version.py
                @@ -1,3 +1,3 @@
                 from __future__ import unicode_literals

                -__version__ = '2021.12.17'
                +__version__ = '${version} (${youtube-dl.shortRev})'
              '')
            ];

            nativeBuildInputs = with pkgs; [ installShellFiles makeWrapper ];
            buildInputs = with pkgs; [ zip atomicparsley ffmpeg rtmpdump ];
            setupPyBuildFlags = [ "build_lazy_extractors" ];

            doCheck = false;
            # checkInputs = [ pythonPackage.unittest2 ];
            # checkPhase = "unit2 discover";

            postInstall = ''
              python devscripts/bash-completion.py
              python devscripts/fish-completion.py
              python devscripts/zsh-completion.py
              installShellCompletion --bash youtube-dl.bash-completion
              installShellCompletion youtube-dl.{fish,zsh}
            '';
          };
        });
}
