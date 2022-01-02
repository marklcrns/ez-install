# ez-install

ez-install intends to alleviate the pain of installing UNIX binaries, packages,
git repositories, personal configurations, environment setup, etc.

![Demo](./demo.gif)

## Installation

Firstly, clone the repo.

```sh
git clone --depth=1 https://github.com/marklcrns/ez-install ~/.ez-install
```

Then, create a soft symlink of the `ez` into `${INSTALL_DIR}`, preferably one
included in `$PATH` e.g., `/usr/local/bin`.

```sh
mkdir -p ${INSTALL_DIR}
ln -s ~/.ez/ez ${INSTALL_DIR}

# or simply run from root dir (will install in /usr/local/bin/)

make
```

Finally, `export EZ_INSTALL_HOME` in your `~/.bashrc` or `~/.zshrc` or in any
environment rc file of your shell initialized on startup.

```sh
export EZ_INSTALL_HOME='~/.ez-install'
```

## Usage

```sh
./ez-install [ flags ] [ package(s) ]

# from cmdline arguments
./ez-install build-essential git-lfs nvim

# from a file
./ez-install "$(cat packages.txt)"
```

## Config

All custom packages, by default, are located in `~/.ez-install.d` and local rc
file in `~/.ez-installrc`

## TODO

- [ ] More practical package installer template generator
  - [X] Modularize script
  - [X] Option to generate package dependency
  - [ ] Interactive package installer generator
  - [ ] Generate package installer from command history
- [ ] Handle package dependencies
  - [X] Dependency system
  - [X] Print dependency tree before installation
  - [X] Prevent package installation with missing dependencies
  - [ ] Full support for custom package install script directory
- [X] More flexible installation
  - [X] Support individual installation via commandline
  - [ ] Support JSON install configuration
- [ ] Add more features
  - [ ] Cache all installed packages
  - [ ] Uninstall script
  - [ ] Package update script
    - [ ] Package version watcher
- [ ] OS support
  - [x] Ubuntu
    - [x] 20.04 Focal Fossa
    - [x] 18.04 Bionic Beaver
  - [x] Ubuntu (WSL/WSL2)
    - [x] 20.04 Focal Fossa
    - [x] 18.04 Bionic Beaver
  - [ ] More OS support coming
- [ ] Bourne Shell support

