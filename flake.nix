{
  description = "Flutter Development Environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
            permittedInsecurePackages = [ "olm-3.2.16" ];
          };
        };
        aapt2buildToolsVersion = "34.0.0";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [
            "30.0.3"
            aapt2buildToolsVersion
          ];
          platformVersions = [
            "28"
            "29"
            "30"
            "31"
            "32"
            "33"
            "34"
          ];
          includeNDK = true;
          ndkVersions = [ "21.4.7075529" ];
          cmakeVersions = [ "3.18.1" ];
          abiVersions = [
            "armeabi-v7a"
            "arm64-v8a"
          ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell =
          with pkgs;
          mkShell rec {
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            ANDROID_JAVA_HOME = jdk17.home;
            JAVA_8_HOME = jdk8.home;
            JAVA_17_HOME = jdk17.home;
            SHELL = "${pkgs.bashInteractive}/bin/bash";
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_SDK_ROOT}/build-tools/${aapt2buildToolsVersion}/aapt2";
            buildInputs = [
              flutter
              androidSdk
              jdk17
              ninja
              gtk3
              olm
              mpv
              ffmpeg
              mimalloc
              libepoxy
              dart
              libass
              pkg-config
              android-tools
              android-studio
              bashInteractive
            ];
          };
      }
    );
}
