# jupyter-nixflake-template

A modern, reproducible data science template using Nix Flakes. 
This template provides a unified environment for **Python**, **R**, and **Julia** that works seamlessly across both Jupyter Lab and your terminal (REPL).

## Key Features

- **Multi-language Support**: Pre-configured kernels for Python (ipykernel), R (IRkernel), and Julia (IJulia).
- **Environment Consistency**: The exact same package set is shared between Jupyter Lab and your shell environment (via `direnv` or `nix develop`).
- **Reproducibility**: Powered by Nix Flakes, ensuring every collaborator works in the identical environment regardless of their OS (Linux/macOS).
- **Jupytext Integration**: Easily convert between Notebooks (.ipynb) and scripts (.py, .R) for better version control.

## Getting Started

### 1. Prerequisites

- [Nix](https://nixos.org/download.html) with Flakes enabled.
- [direnv](https://direnv.net/) (highly recommended for automatic environment loading).

### 2. Launching the Environment

Simply enter the directory. If you use `direnv`, run `direnv allow`.

#### To start Jupyter Lab:
```bash
nix run
# or
nix run .#jupyterLab
```

#### To develop in the terminal (REPL):
```bash
python  # Python REPL with numpy, polars, etc.
R       # R REPL with tidyverse, etc.
julia   # Julia REPL
```

## Customization

You can easily add or remove packages by editing `flake.nix`.

### Python
Add packages to the `pythonPackages` list:
```nix
pythonPackages = ps: with ps; [
  numpy
  polars
  pandas
  scikit-learn
  # ...
];
```

### R
Add packages to the `rEnv` definition:
```nix
rEnv = pkgs.rWrapper.override {
  packages = with pkgs.rPackages; [
    tidyverse
    ggplot2
    # ...
  ];
};
```

### Julia
Julia packages are managed via the standard Julia package manager. 
The template is configured to use a local `.julia` directory within the project to keep it isolated.
To use Julia in Jupyter, ensure you have run `using Pkg; Pkg.add("IJulia")` in the Julia REPL.

## License

[MIT LICENSE](./LICENSE)
