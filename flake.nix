{
  description = "Elixir chlorine development flake";

  inputs =
    {
      nixpkgs.url = "github:nixos/nixpkgs";
      flake-utils.url = "github:numtide/flake-utils";
    };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        elixir = with pkgs; (beam.packagesWith erlangR24).elixir.override {
          version = "1.12.1";
          sha256 = "sha256-gRgGXb4btMriQwT/pRIYOJt+NM7rtYBd+A3SKfowC7k=";
          minimumOTPVersion = "22";
        };
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = [
            elixir
            pkgs.glibcLocales
          ];
        };
      }
    );
}
