{
  description = "Data science environment with R, Python, and Julia integration via Jupyter Lab";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    jupyter = {
      url = "github:KaoruBB/jupyter.nix/add-julia-kernel";
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
        jupyterMcpTools = pkgs.python3Packages.buildPythonPackage rec {
          pname = "jupyter-mcp-tools";
          version = "0.1.6";
          format = "wheel";

          src = pkgs.fetchPypi {
            pname = "jupyter_mcp_tools";
            inherit version format;
            dist = "py3";
            python = "py3";
            abi = "none";
            platform = "any";
            hash = "sha256-RcsYZY1YU6YvrM1ejqF77MOhhQSCpDxJqeS7LIVO/9c=";
          };

          dependencies = with pkgs.python3Packages; [
            aiohttp
            jupyter-server
            requests
          ];

          pythonImportsCheck = [ "jupyter_mcp_tools" ];
        };
        rEnv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            IRkernel # MUST be included for Jupyter kernel support
            tidyverse
            languageserver
          ];
        };
        juliaEnv = pkgs.julia-lts;
        jupyterLab = inputs.jupyter.lib.makeJupyterLab {
          inherit pkgs;
          jupyterEnvPackages =
            ps: with ps; [
              jupyter-collaboration
              pycrdt
              jupyterMcpTools
            ];
          jupyterExtensions = [
            jupyterMcpTools
          ];
          kernels = {
            "python".ipykernel = {
              packages = pythonPackages;
              withPlotly = true;
            };
            "julia".ijulia = {
              julia = juliaEnv;
              project = "@.";
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

            # Enable local caching for Language Server (LSP) and project isolation
            export JULIA_DEPOT_PATH="$PWD/.julia"

            export JULIA_PROJECT="@."
            julia -e 'using Pkg; Pkg.instantiate()'
          '';
        };
      }
    );
}
