{
  description = "Spring92 Walking Challenge";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.buildNimPackage {
          pname = "spring92";
          version = "0.2.0";
          src = ./.;
          # Run `nix shell nixpkgs#nim_lk -c nim_lk > lock.json` to generate lock file
          lockFile = ./lock.json;
          nimFlags = [
            "--deepcopy:on"
            "-d:release"
            "-d:ssl"
            "--mm:none"
          ];
          buildInputs = with pkgs; [
            nim-2_0
            nimble
            sqlite
            openssl
            imagemagick
          ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postFixup = ''
            wrapProgram $out/bin/main \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.sqlite ]}" \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.imagemagick ]}"
          '';
          meta.mainProgram = "main";
        };
      }
    );
}
