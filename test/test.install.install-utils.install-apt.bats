#!/usr/bin/env bats

# load bats test helpers
load "/opt/bats-test-helpers/bats-support/load.bash"
load "/opt/bats-test-helpers/bats-assert/load.bash"
# load source file
load "../install/install-utils/install-apt.sh"
load "../install/common.sh"

# Test is_apt_installed

@test "install.install-utils.install-apt.is_apt_installed() test apt is installed in debian" {
  local expected_status=$BASH_EX_NOTFOUND

  if [[ -f "/etc/debian_version" ]]; then
    expected_status=$BASH_EX_OK
  fi

  run is_apt_installed
  assert_equal "$status" "$expected_status"
}

# Test apt_update

@test "install.install-utils.install-apt.apt_update() test update command returned" {
  local VERBOSE=true
  local expected_status=$BASH_EX_OK

  if ! [[ -f "/etc/debian_version" ]]; then
    expected_status=$BASH_EX_NOTFOUND
  fi

  run apt_update
  assert_equal "$status" "$expected_status"

  [[ "${lines[0]}" =~ "apt update -y" ]]
}

@test "install.install-utils.install-apt.apt_update() test update command returned with VERBOSE=false" {
  local VERBOSE=false
  local expected_status=$BASH_EX_OK

  if ! [[ -f "/etc/debian_version" ]]; then
    expected_status=$BASH_EX_NOTFOUND
  fi

  run apt_update
  assert_equal "$status" "$expected_status"

  [[ "${lines[0]}" =~ "apt update -y &> /dev/null" ]]
}

@test "install.install-utils.install-apt.apt_update() test -s as_root flag correct usage" {
  local VERBOSE=true
  local expected_status=$BASH_EX_OK

  if ! [[ -f "/etc/debian_version" ]]; then
    expected_status=$BASH_EX_NOTFOUND
  fi

  if ! command -v "sudo" &>/dev/null; then
    expected_status=$BASH_EX_MISUSE
  fi

  run apt_update -s true
  assert_equal "$status" "$expected_status"

  # If sudo is not installed, then the command will not be run
  if [[ "$status" -eq "$BASH_EX_OK" ]]; then
    [[ "${lines[0]}" =~ "sudo apt update -y" ]]
  else
    [[ "${lines[0]}" =~ "" ]]
  fi
}

@test "install.install-utils.install-apt.apt_update() test invalid -x flag" {
  run apt_update -x
  assert_failure
  assert_equal "$status" "$BASH_SYS_EX_USAGE"

  [[ "${lines[0]}" =~ "" ]]
}

# Test apt_upgrade

@test "install.install-utils.install-apt.apt_upgrade() test upgrade command returned" {
  local VERBOSE=true
  local expected_status=$BASH_EX_OK

  if ! [[ -f "/etc/debian_version" ]]; then
    expected_status=$BASH_EX_NOTFOUND
  fi

  run apt_upgrade
  assert_equal "$status" "$expected_status"

  [[ "${lines[0]}" =~ "apt upgrade -y" ]]
}

@test "install.install-utils.install-apt.apt_upgrade() test upgrade command returned with VERBOSE=false" {
  local VERBOSE=false
  local expected_status=$BASH_EX_OK

  if ! [[ -f "/etc/debian_version" ]]; then
    expected_status=$BASH_EX_NOTFOUND
  fi

  run apt_upgrade
  assert_equal "$status" "$expected_status"

  [[ "${lines[0]}" =~ "apt upgrade -y &> /dev/null" ]]
}


@test "install.install-utils.install-apt.apt_upgrade() test -s as_root flag correct usage" {
  local VERBOSE=true
  local expected_status=$BASH_EX_OK

  if ! [[ -f "/etc/debian_version" ]]; then
    expected_status=$BASH_EX_NOTFOUND
  fi

  if ! command -v "sudo" &>/dev/null; then
    expected_status=$BASH_EX_MISUSE
  fi

  run apt_upgrade -s true
  assert_equal "$status" "$expected_status"

  # If sudo is not installed, then the command will not be run
  if [[ "$status" -eq "$BASH_EX_OK" ]]; then
    [[ "${lines[0]}" =~ "sudo apt upgrade -y" ]]
  else
    [[ "${lines[0]}" =~ "" ]]
  fi
}

@test "install.install-utils.install-apt.apt_upgrade() test -a args flag correct usage" {
  local VERBOSE=true
  local expected_status=$BASH_EX_OK

  if ! [[ -f "/etc/debian_version" ]]; then
    expected_status=$BASH_EX_NOTFOUND
  fi

  local args="--autoremove --purge"

  run apt_upgrade -a "${args}" true
  assert_equal "$status" "$expected_status"

  # If sudo is not installed, then the command will not be run
  [[ "${lines[0]}" =~ "apt upgrade -y ${args}" ]]
}

@test "install.install-utils.install-apt.apt_upgrade() test invalid -x flag" {
  run apt_upgrade -x
  assert_failure
  assert_equal "$status" "$BASH_SYS_EX_USAGE"

  [[ "${lines[0]}" =~ "" ]]
}

# TODO: Test apt_add_repo

@test "install.install-utils.install-apt.apt_add_repo() test missing argument" {
  run apt_add_repo
  assert_failure
  assert_equal "$status" $BASH_SYS_EX_USAGE
}

# TODO: Test apt_install

# TODO: Test apt_uninstall

