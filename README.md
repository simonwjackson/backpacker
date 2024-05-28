<h3 align="center">
    <img src="./.github/assets/backpacker-logo.jpg" width="300px"/>
</h3>
<h1 align="center">
    backpacker | <a href="https://nixos.org">Nix</a> configs
</h1>

<div align="center">
    <img alt="Static Badge" src="https://img.shields.io/badge/State-Forever_WIP-ff7b72?style=for-the-badge&logo=fireship&logoColor=ff7b72&labelColor=161B22">
    <a href="https://github.com/simonwjackson/backpacker/pulse">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/simonwjackson/backpacker?style=for-the-badge&logo=github&logoColor=D9E0EE&labelColor=302D41&color=9fdf9f"/>
    </a>
    <a href="https://github.com/simonwjackson/backpacker/tree/main/LICENSE">
      <img alt="License" src="https://img.shields.io/badge/License-MIT-907385605422448742?style=for-the-badge&logo=agpl&color=DDB6F2&logoColor=D9E0EE&labelColor=302D41">
    </a>
    <br/>
    <img alt="Static Badge" src="https://img.shields.io/badge/NixOS-unstable-d2a8ff?style=for-the-badge&logo=NixOS&logoColor=cba6f7&labelColor=161B22">
    <a href="https://snowfall.org/guides/lib/quickstart/">
      <img alt="Static Badge" src="https://img.shields.io/badge/Powered_by-Snowfall-79c0ff?style=for-the-badge&logo=nixos&logoColor=79c0ff&labelColor=161B22">
    </a>
    <br/>
    <a href="https://www.buymeacoffee.com/simonwjackson">
      <img alt="Buy me a coffee" src="https://img.shields.io/badge/Buy%20me%20a%20coffee-grey?style=for-the-badge&logo=buymeacoffee&logoColor=D9E0EE&label=Sponsor&labelColor=302D41&color=ffff99" />
    </a>
</div>

## Overview

Here's a quick and incomplete tour of what is going on in the repository:</p>

| Directory  | Purpose                                                                                                                              |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `modules`  | Stores **NixOS** and **Home-manager** modules. These are the main building block: Every `system` receives the options these declare. |
| `systems`  | Stores **NixOS** system configurations. These are also often called `hosts`                                                          |
| `homes`    | Stores **Home-manager** configurations, which are associated with a `system`                                                         |
| `lib`      | A shared library of functions and variables, available everywhere in the flake at `lib.backpacker.*`                                |
| `packages` | Packages I could not find in [`nixpkgs`](https://github.com/nixos/nixpkgs), and packaged myself for use in this flake.               |
| `shells`   | **Nix** shells for bootstrapping, etc.                                                                                               |

Others are not as important. [Snowfall Guide/Reference](https://snowfall.org/guides/lib/quickstart/)

## System Management Commands

This repository provides a set of convenient commands for managing the NixOS configurations. These commands are implemented using [`just`](https://github.com/casey/just), a handy command runner. Here's a table of the available commands:

| Command                           | Description                                                                                                                                                   |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `just`                            | Displays a list of available commands.                                                                                                                        |
| `just switch [HOST] [BUILD_HOST]` | Switches to the system configuration for the specified `HOST`. Optionally, you can provide a custom `BUILD_HOST`. If not provided, it defaults to the `HOST`. |
| `just build [HOST]`               | Builds the system configuration for the specified `HOST`.                                                                                                     |
| `just dry[-run] [HOST]`           | Performs a dry run of the system configuration for the specified `HOST`.                                                                                      |
| `just evolve [ARGS]`              | Updates the flake and switches to the new configuration. You can pass additional arguments to `just switch` using `ARGS`.                                     |
| `just evolve-all [ARGS]`          | Updates the flake and deploys the new configuration to all systems.                                                                                           |
| `just up [ARGS]`                  | Updates all flake inputs or specific inputs. You can specify the inputs to update using `ARGS`.                                                               |
| `just history`                    | Shows the system profile history.                                                                                                                             |
| `just repl`                       | Opens the Nix REPL with the nixpkgs flake.                                                                                                                    |
| `just clean`                      | Removes all system generations older than 7 days.                                                                                                             |
| `just gc`                         | Garbage collects all unused Nix store entries.                                                                                                                |

To use these commands, make sure you have `just` installed on your system. Then, navigate to the root directory of this repository and run the desired command using `just <command>`.

For example, to switch to the system configuration for a specific host, you can run:

```bash
just switch my-host
```
