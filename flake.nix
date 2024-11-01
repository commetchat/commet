{
  description = "Commet";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "olm-3.2.16" ];
        };
    };

    in {
      defaultPackage.x86_64-linux = with pkgs; stdenv.mkDerivation {
      name = "my-env";
      buildInputs = [
        ninja
        gtk3
        olm
        mpv
        ffmpeg
        mimalloc
        flutter
        dart
        libass
        pkg-config
        android-tools
        android-studio
      ];
    };
  };
}

