# ez-install

ez-install intends to alleviate the pain of installing UNIX binaries, packages,
git repositories, personal configurations, environment setup, etc., which makes
starting from scratch less painful.

## Usage

```sh
./ez-install -y
```

## TODO

- [ ] More practical package installer template generator
  - [ ] Modularize script
  - [ ] Option to generate package dependency
  - [ ] Interactive package installer generator
  - [ ] Generate package installer from command history
- [ ] Handle package dependencies
  - [ ] Dependency system
  - [ ] Print dependency tree before installation
- [ ] Easier configuration
  - [ ] Abstract away source code
  - [ ] Support JSON install configuration
- [ ] More flexible installation
  - [ ] Support individual installation via commandline
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
