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

# TODO: Test fetch_package

# TODO: Test has_package

# TODO: Test select_package

# TODO: Test has_alternate_package

# TODO: Test parse_inline_opts

# TODO: Test get_user_input

# TODO: Test get_sys_package_manager

