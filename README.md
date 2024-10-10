<h3 align="center">
    <img src="./.github/assets/backpacker-logo.jpg" width="300px"/>
</h3>
<h1 align="center">
    backpacker | My <a href="https://github.com/nix-community/nix-on-droid">Nix-on-Droid</a> configs
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
    <img alt="Static Badge" src="https://img.shields.io/badge/Nix On Droid-24.05-d2a8ff?style=for-the-badge&logo=NixOS&logoColor=cba6f7&labelColor=161B22">
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

