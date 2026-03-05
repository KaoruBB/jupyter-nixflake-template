{
  description = "Data science environment with R and Jupyter integration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    jupyter = {
      url = "github:kirelagin/jupyter.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      jupyter,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        pythonEnv = pkgs.python3.withPackages (ps: [
          ps.jupytext
        ]);
        rEnv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            IRkernel
            tidyverse
            languageserver
          ];
        };
        jupyterLab = inputs.jupyter.lib.makeJupyterLab {
          inherit pkgs;
          kernels = {
            "R".kernelspec = {
              spec = {
                argv = [
                  "${rEnv}/bin/R"
                  "--slave"
                  "-e"
                  "IRkernel::main()"
                  "--args"
                  "{connection_file}"
                ];
                display_name = "R 4.x";
                language = "R";
              };
            };
          };
        };
      in
      {
        packages.jupyterLab = jupyterLab;
        packages.default = jupyterLab;

        devShells.default = pkgs.mkShell {
          name = "my-r-jupyter-env";
          buildInputs = [
            jupyterLab
            pythonEnv
            rEnv
          ];
        };
      }
    );
}
