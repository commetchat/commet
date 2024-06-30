{
  description = "Commet";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {

    defaultPackage.x86_64-linux = with nixpkgs.legacyPackages.x86_64-linux; stdenv.mkDerivation {
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
		shellHook = ''
        # Start Android Studio silently
        android-studio &> /dev/null &
      '';
    };
  };
}

