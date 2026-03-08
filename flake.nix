{
  description = "Data science environment with R, Python, and Julia integration via Jupyter Lab";
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
        pythonPackages =
          ps: with ps; [
            ipykernel # MUST be included for Jupyter kernel support
            numpy
            polars
            jupytext
            plotly
          ];
        pythonEnv = pkgs.python3.withPackages pythonPackages;
        rEnv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            IRkernel # MUST be included for Jupyter kernel support
            tidyverse
            languageserver
          ];
        };
        juliaEnv = pkgs.julia-bin;
        jupyterLab = inputs.jupyter.lib.makeJupyterLab {
          inherit pkgs;
          kernels = {
            "python".ipykernel = {
              packages = pythonPackages;
              withPlotly = true;
            };
            "julia".kernelspec = {
              spec = {
                argv = [
                  "${juliaEnv}/bin/julia"
                  "-i"
                  "--startup-file=no"
                  "--color=yes"
                  "-e"
                  "using IJulia; IJulia.kernel()"
                  "{connection_file}"
                ];
                display_name = "Julia 1.x";
                language = "julia";
              };
            };
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
          name = "my-jupyter-env";
          buildInputs = [
            pythonEnv
            rEnv
            juliaEnv
            jupyterLab
          ];
          shellHook = ''
            echo "Julia development environment is ready!"
            echo "Julia v$(julia --version | cut -d' ' -f3)"

            # Uncomment the following line to isolate the Julia environment within this project.
            # export JULIA_DEPOT_PATH="$PWD/.julia"

            export JULIA_PROJECT="@."
            julia -e 'using Pkg; Pkg.instantiate()'
          '';
        };
      }
    );
}
