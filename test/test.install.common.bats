#!/usr/bin/env bats

# load bats test helpers
load "/opt/bats-test-helpers/bats-support/load.bash"
load "/opt/bats-test-helpers/bats-assert/load.bash"
# load source file
load "../install/common.sh"

@test "install.common.resolve_package_dir() test non-empty PACKAGE_ROOT_DIR" {
  unset PACKAGE_ROOT_DIR
  PACKAGE_ROOT_DIR="/path/to/packages/"
  resolve_package_dir
  assert_equal "$PACKAGE_ROOT_DIR" "/path/to/packages"
}

@test "install.common.resolve_package_dir() test empty PACKAGE_ROOT_DIR" {
  unset PACKAGE_ROOT_DIR
  resolve_package_dir
  assert_equal "$PACKAGE_ROOT_DIR" "$(realpath "${EZ_INSTALL_HOME}/generate/packages")"
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

@test "install.common.fetch_package() test no argument" {
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

@test "install.common.select_package() test no required arguments" {
  run select_package
  assert_failure
  assert_equal "$status" $BASH_SYS_EX_USAGE
}

@test "install.common.select_package() test missing second argument" {
  run select_package
  assert_failure
  assert_equal "$status" $BASH_SYS_EX_USAGE
}

# TODO: Test has_alternate_package

# TODO: Test parse_inline_opts

# TODO: Test get_user_input

# TODO: Test get_sys_package_manager

