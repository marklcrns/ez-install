#!/usr/bin/env bats

# load bats test helpers
load "/opt/bats-test-helpers/bats-support/load.bash"
load "/opt/bats-test-helpers/bats-assert/load.bash"
# load source file
load "../install/common.sh"

@test "install.common.resolve_package_dir() test non-empty PACKAGE_ROOT_DIR" {
  unset PACKAGE_ROOT_DIR
  PACKAGE_ROOT_DIR="/path/to/packages"
  resolve_package_dir
  assert_equal "$PACKAGE_ROOT_DIR" "/path/to/packages"
}

@test "install.common.resolve_package_dir() test non-empty package dir trailing slash stripped" {
  unset PACKAGE_ROOT_DIR
  PACKAGE_ROOT_DIR="/path/to/packages/"
  resolve_package_dir
  assert_equal "$PACKAGE_ROOT_DIR" "/path/to/packages"
}

@test "install.common.resolve_package_dir() test empty PACKAGE_ROOT_DIR" {
  unset PACKAGE_ROOT_DIR
  resolve_package_dir
  assert_equal "$PACKAGE_ROOT_DIR" "$(realpath -s "${EZ_INSTALL_HOME}/generate/packages")"
}

@test "install.common.resolve_package_dir() test non-empty LOCAL_PACKAGE_ROOT_DIR" {
  unset LOCAL_PACKAGE_ROOT_DIR
  LOCAL_PACKAGE_ROOT_DIR="/path/to/local/packages/"
  resolve_package_dir
  assert_equal "$LOCAL_PACKAGE_ROOT_DIR" "/path/to/local/packages"
}

@test "install.common.resolve_package_dir() test empty LOCAL_PACKAGE_ROOT_DIR" {
  unset LOCAL_PACKAGE_ROOT_DIR
  resolve_package_dir
  assert_equal "$LOCAL_PACKAGE_ROOT_DIR" "${HOME}/.ez-install.d/packages"
}

@test "install.common.resolve_package_dir() test PACKAGE_DIR value with non-empty PACKAGE_ROOT_DIR" {
  unset PACKAGE_ROOT_DIR
  unset PACKAGE_DIR
  PACKAGE_ROOT_DIR="/path/to/packages/"
  resolve_package_dir
  assert_equal "$PACKAGE_DIR" "/path/to/packages/${OS_DISTRIB_ID}/${OS_DISTRIB_RELEASE}"
}

@test "install.common.fetch_package() test missing argument" {
  run fetch_package
  assert_failure
  assert_equal "$status" $BASH_SYS_EX_USAGE
}

# FIXME: Test fail probably because common/string.sh:143 returns an error that
# bats catches
# TODO: Require a second argument to store the package path. Follow
# select_package.
@test "install.common.fetch_package() test local package in path" {
  unset PACKAGE_DIR

  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  local package_path="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  touch "${LOCAL_PACKAGE_DIR}/${package_path}"

  # BUG: This does not work because of an error from common/string.sh:143
  # fetch_package package_path
  # assert_equal "$package_path" "${LOCAL_PACKAGE_DIR}/test"

  # NOTE: This is a workaround
  run fetch_package package_path
  assert_success

  rm -rf "${EZ_TMP_DIR}"
}

# FIXME: Test fail probably because common/string.sh:143 returns an error that
# bats catches
# TODO: Require a second argument to store the package path. Follow
# select_package.
@test "install.common.fetch_package() test global package in path" {
  unset LOCAL_PACKAGE_DIR

  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package_path="test"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package_path}"

  # BUG: This does not work because of an error from common/string.sh:143
  # fetch_package package_path
  # assert_equal "$package_path" "${PACKAGE_DIR}/test"

  # NOTE: This is a workaround
  run fetch_package package_path
  assert_success

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.fetch_package() test package not in path" {
  unset PACKAGE_DIR
  unset LOCAL_PACKAGE_DIR
  local package_path="test"

  run fetch_package package_path
  assert_failure
}

@test "install.common.has_package() test package exist in local path but not in global path" {
  unset PACKAGE_DIR

  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  touch "${LOCAL_PACKAGE_DIR}/${package}"

  run has_package "${package}"
  assert_success

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.has_package() test package exist in global path but not in local path" {
  unset LOCAL_PACKAGE_DIR

  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}"

  run has_package "${package}"
  assert_success

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.has_package() test package exist in both local and global path" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${LOCAL_PACKAGE_DIR}/${package}"
  touch "${PACKAGE_DIR}/${package}"

  run has_package "${package}"
  assert_success

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.has_package() test package does not exist in both local and global path" {
  local package="test"

  run has_package "${package}"
  assert_failure

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.list_selector() test -t timeout flag correct usage" {
  local selected
  local list=("item1" "item2" "item3")

  run list_selector -t 0.5 selected "${list[@]}"
  assert_failure
}

# FIXME: Bats does not wait for timeout. read `prompt` cannot be captured by
# bats output ${lines[@]}.
#
# @test "install.common.list_selector() test -p prompt flag correct usage" {
#   local selected
#   local list=("item1" "item2" "item3")
#   local prompt="Sample prompt message: "
#
#   # output all to stdout
#   run list_selector -t 0.5 -p "Sample prompt message: " selected "${list[@]}" 2>&1 | grep -q "${prompt}"
#   assert_success
# }

@test "install.common.list_selector() test selected item exist" {
  local selected
  local list=("item1" "item2" "item3")

  run list_selector selected "${list[@]}" <<< "1"
  assert_success
}

@test "install.common.list_selector() test selected item returned accurately" {
  local selected
  local list=("item1" "item2" "item3")

  list_selector selected "${list[@]}" <<< "1"
  assert_equal "$selected" "item1"
}

@test "install.common.list_selector() test selected item does not exist" {
  local selected
  local list=("item1" "item2" "item3")

  run list_selector -t 0.5 selected "${list[@]}" <<< "4"
  assert_failure
}

@test "install.common.list_selector() test skip to select an item" {
  local selected
  local list=("item1" "item2" "item3")

  run list_selector selected "${list[@]}" <<< "0"
  assert_success
}

@test "install.common.print_packages() test one package in local path" {
  unset PACKAGE_DIR

  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  local package="test-local"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  touch "${LOCAL_PACKAGE_DIR}/${package}"

  run print_packages "${package}"
  assert_success

  [[ "${lines[0]}" =~ "${LOCAL_PACKAGE_DIR}/${package}" ]]

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.print_packages() test one package in global path" {
  unset LOCAL_PACKAGE_DIR

  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test-global"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}"

  run print_packages "${package}"
  assert_success

  [[ "${lines[0]}" =~ "${PACKAGE_DIR}/${package}" ]]

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.print_packages() test one package in both local and global path" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${LOCAL_PACKAGE_DIR}/${package}-local"
  touch "${PACKAGE_DIR}/${package}-global"

  run print_packages "${package}"
  assert_success

  [[ "${lines[0]}" =~ "${PACKAGE_DIR}/${package}-global" ]]
  [[ "${lines[1]}" =~ "${LOCAL_PACKAGE_DIR}/${package}-local" ]]

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.print_packages() test one identical package in both local and global path" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${LOCAL_PACKAGE_DIR}/${package}"
  touch "${PACKAGE_DIR}/${package}"

  run print_packages "${package}"
  assert_success

  [[ "${lines[0]}" =~ "${PACKAGE_DIR}/${package}" ]]
  [[ "${lines[1]}" =~ "${LOCAL_PACKAGE_DIR}/${package}" ]]

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.print_package() test similar package with multiple different file extension" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}.apt"
  touch "${PACKAGE_DIR}/${package}.git"
  touch "${PACKAGE_DIR}/${package}.npm"
  touch "${LOCAL_PACKAGE_DIR}/${package}.apt"
  touch "${LOCAL_PACKAGE_DIR}/${package}.git"
  touch "${LOCAL_PACKAGE_DIR}/${package}.npm"

  run print_packages "${package}"
  assert_success

  [[ "${lines[0]}" =~ "${PACKAGE_DIR}/${package}.apt" ]]
  [[ "${lines[1]}" =~ "${PACKAGE_DIR}/${package}.git" ]]
  [[ "${lines[2]}" =~ "${PACKAGE_DIR}/${package}.npm" ]]
  [[ "${lines[3]}" =~ "${LOCAL_PACKAGE_DIR}/${package}.apt" ]]
  [[ "${lines[4]}" =~ "${LOCAL_PACKAGE_DIR}/${package}.git" ]]
  [[ "${lines[5]}" =~ "${LOCAL_PACKAGE_DIR}/${package}.npm" ]]

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.print_package() test specific package with multiple different file extension" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}.apt"
  touch "${PACKAGE_DIR}/${package}.git"
  touch "${PACKAGE_DIR}/${package}.npm"
  touch "${LOCAL_PACKAGE_DIR}/${package}.apt"
  touch "${LOCAL_PACKAGE_DIR}/${package}.git"
  touch "${LOCAL_PACKAGE_DIR}/${package}.npm"

  run print_packages "${package}.apt"
  assert_success

  [[ "${lines[0]}" =~ "${PACKAGE_DIR}/${package}.apt" ]]
  [[ "${lines[3]}" =~ "${LOCAL_PACKAGE_DIR}/${package}.apt" ]]

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.print_package() test existing package ignore existing pre and post hook installer" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}.apt"
  touch "${PACKAGE_DIR}/${package}.pre"
  touch "${LOCAL_PACKAGE_DIR}/${package}.apt"
  touch "${LOCAL_PACKAGE_DIR}/${package}.post"

  run print_packages "${package}"
  assert_success

  [[ "${lines[0]}" =~ "${PACKAGE_DIR}/${package}.apt" ]]
  [[ "${lines[1]}" =~ "${LOCAL_PACKAGE_DIR}/${package}.apt" ]]

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.print_package() test non-existing package ignore existing pre and post hook installer" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}.pre"
  touch "${LOCAL_PACKAGE_DIR}/${package}.post"

  run print_packages "${package}"
  assert_success

  [[ "${lines[0]}" =~ "" ]]

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.print_packages() test no package in both local and global path" {
  unset PACKAGE_DIR
  unset LOCAL_PACKAGE_DIR

  run print_packages "${package}"
  assert_success

  [[ "${lines[0]}" =~ "" ]]
}

@test "install.common.select_package() test missing first argument" {
  run select_package
  assert_failure
  assert_equal "$status" "$BASH_SYS_EX_USAGE"
}

@test "install.common.select_package() test missing second argument" {
  run select_package selected
  assert_failure
  assert_equal "$status" "$BASH_SYS_EX_USAGE"
}

@test "install.common.select_package() test selected package does not exist" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"

  local selected

  run select_package selected "${package}"
  assert_failure
  assert_equal "$status" "$BASH_EZ_EX_PAC_NOTFOUND"

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.select_package() test selected package exist and defaulted from selection" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}1-global"

  local selected

  select_package selected "${package}"
  assert_success
  assert_equal "$selected" "${PACKAGE_DIR}/${package}1-global"

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.select_package() test selected package exist from sorted list" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}1-global"
  touch "${PACKAGE_DIR}/${package}2-global"
  touch "${LOCAL_PACKAGE_DIR}/${package}1-local"
  touch "${LOCAL_PACKAGE_DIR}/${package}2-local"

  local selected

  select_package selected "${package}" <<< "1"
  assert_success
  assert_equal "$selected" "${PACKAGE_DIR}/${package}1-global"

  rm -rf "${EZ_TMP_DIR}"
}

@test "install.common.select_package() test selected package with exclusion" {
  EZ_TMP_DIR="${HOME}/ez-tmp-dir"
  LOCAL_PACKAGE_DIR="${EZ_TMP_DIR}/local"
  PACKAGE_DIR="${EZ_TMP_DIR}/global"
  local package="test"
  mkdir -p "${LOCAL_PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  touch "${PACKAGE_DIR}/${package}1-global"
  touch "${PACKAGE_DIR}/${package}2-global"
  touch "${LOCAL_PACKAGE_DIR}/${package}1-local"
  touch "${LOCAL_PACKAGE_DIR}/${package}2-local"

  local selected

  select_package selected "${package}" "global" <<< "1"
  assert_success
  assert_equal "$selected" "${LOCAL_PACKAGE_DIR}/${package}1-local"

  rm -rf "${EZ_TMP_DIR}"
}

# TODO: Test parse_inline_opts

@test "install.common.parse_inline-opts() test no required arguments" {
  run parse_inline_opts
  assert_failure
  assert_equal "$status" "$BASH_SYS_EX_USAGE"
}

# TODO: Test get_user_input

# TODO: Test get_sys_package_manager

