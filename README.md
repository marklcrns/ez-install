# ez-install

ez-install intends to alleviate the pain of installing UNIX binaries, packages,
git repositories, personal configurations, environment setup, etc.

![Demo](./demo.gif)

## Installation

Firstly, clone the repo.

```bash
git clone --recurse-submodules --depth=1 https://github.com/marklcrns/ez-install ~/.ez-install
```

Then, create a soft symlink of the `ez` into `$INSTALL_DIR`, preferably one
included in `$PATH` e.g., `/usr/local/bin`.

```bash
mkdir -p $INSTALL_DIR
ln -s ~/.ez-install/ez $INSTALL_DIR
ln -s ~/.ez-install/generate/ez-gen $INSTALL_DIR

# or simply run from root dir (will install in /usr/local/bin/)

make
```

Finally, `export EZ_INSTALL_HOME` in your `~/.bashrc` or `~/.zshrc` or in any
environment rc file of your shell initialized on startup.

```bash
# Use $HOME instead of `~`. Produce less path problems
export EZ_INSTALL_HOME="${HOME}/.ez-install"
```

## Usage

```bash
ez [ flags ] [ package(s) ]

# from cmdline arguments
ez build-essential git-lfs nvim

# from a file
ez "$(cat packages.txt)"
```

### Reporting

| Report         | Description                                             |
|----------------|---------------------------------------------------------|
| SUCCESS        | Successful installation                                 |
| SKIPPED (exit) | Already installed or failed dependency with exit code   |
| FAILED (exit)  | Failed installation with exit code                      |

For full list of exit codes, run `ez -h`.

## Config

All custom packages, by default, are located in `~/.ez-install.d` and local rc
file in `~/.ez-installrc`

`ez` should install local custom packages over the global ones if existing. Same
for the package's `.pre` and `.post` installations.

| Global Variable           | Description                                                    |
|---------------------------|----------------------------------------------------------------|
| `$LOCAL_PACKAGE_ROOT_DIR` | Local package directory. default=`$EZ_INSTALL_HOME/packages`   |
| `$LOG_SYSLOG`             | Enables system logging using built-in `logger`. default=`true` |
| `$LOG_FILELOG`            | Enables file logging `logger`. default=`true`                  |

> `$LOG_FILELOG` output can be found in `/tmp/%path%to%<INSTALL_DIR>%ez.log` for
> `ez` or `/tmp/%path%to%<INSTALL_DIR>%ez-gen.log` for `ez-gen`

## Package Generator

`ez-gen` makes it easy to create your own custom package installer. Although
package templates are purely written in Bash scripts, it only require little to
no knowledge of bash.

For more options, run `ez-gen -h`.

### Simple Package Generator Usage

```bash
ez-gen -m apt git
```

Will generate
`$LOCAL_PACKAGE_ROOT_DIR/<OS_DISTRIB_ID>/<OS_DISTRIB_RELEASE>/git.apt`.

Normally, if the package is in the repository of one of the [supported package
managers](#supported-package-managers), such as the prevalent `git` is in the
`apt` repository, this step is enough.

Then run `ez git.apt` to install the generated package

### Advanced Package Generator Usage

```bash
ez-gen -m apt -d git git-lfs
```

Will generate
`$LOCAL_PACKAGE_ROOT_DIR/<OS_DISTRIB_ID>/<OS_DISTRIB_RELEASE>/git-lfs.apt`.

As of the time of writting, `git-lfs` installation, with `apt` at least,
requires another step after the package installation, that is `git lfs install`.

> Also, the `-d` flag and its optarg `git` attaches it as a dependency of
> `git-lfs`.

A viable solution is running a pre or post installation process. A built-in
feature runs `<package>.<package-manager>.pre` before the main package
installation and then runs `<package>.<package-manager>.post` after.

In our case, we need to add `git lfs install` in `git.apt.post` which we can
generate with `ez-gen` as well

```bash
ez-gen -m apt -PS git-lfs
```

Here, the `-P` flag tells it to generate a post package installation template
and the `-S` flag to skip the main package installation since its already
existing.

Then open
`$LOCAL_PACKAGE_ROOT_DIR/<OS_DISTRIB_ID>/<OS_DISTRIB_RELEASE>/git-lfs.apt.post`
and add `git lfs install` inside the `_main()` function.

Finally, run `ez git-lfs` and it will try to install `git` first, including its
`.pre` and `.post`, then if successful, will install `git-lfs` likewise.

## Supported Package Managers

- `apt` -- supports `wsl` and `wsl2`
- `pkg`
- `npm`
- `pip`, `pip2`, `pip3`
- `curl`
- `wget`
- `git`

## Tested Distributions

- Ubuntu 20.04
- Ubuntu 20.04 (WSL/WSL2)

## TODO

- [ ] Integrate with [Dotfiles Manager](https://github.com/marklcrns/scripts/blob/master/tools/dotfiles/README.md)
- [ ] More practical package installer template generator
  - [X] Modularize script
  - [X] Option to generate package dependency
  - [X] Interactive package installer generator
  - [ ] Generate package installer from command history
- [X] Handle package dependencies
  - [X] Dependency system
  - [X] Print dependency tree before installation
  - [X] Prevent package installation with missing dependencies
  - [X] Full support for custom package install directory
- [X] More flexible installation
  - [X] Support individual installation via commandline
  - [X] Support JSON install configuration
- [ ] Add more features
  - [ ] Cache all installed packages
  - [ ] Uninstall
  - [ ] Package update
- [ ] OS support
  - [x] Debian/Ubuntu
    - [x] 20.04
    - [x] 18.04
  - [x] Debian/Ubuntu (WSL/WSL2)
    - [x] 20.04
    - [x] 18.04
  - [ ] More OS support coming
- [ ] Package managers support
  - [X] `apt`
  - [X] `apt-add`
  - [X] `pkg`
  - [X] `npm`
  - [X] `pip`
  - [X] `git`
  - [X] `curl`
  - [X] `wget`
  - [X] `local`
  - [ ] `brew`
  - [ ] More support coming
- [ ] Bourne Shell support

