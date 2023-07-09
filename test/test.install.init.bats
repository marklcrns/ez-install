#!/usr/bin/env bats

# load bats test helpers
load "/opt/bats-test-helpers/bats-support/load.bash"
load "/opt/bats-test-helpers/bats-assert/load.bash"
# load source file
load "../install/init.sh"

# NOTE: handle_package_args() modifies output_path, execute, force, as_root
# variables locally. Therefore, to properly test for correct usage, we don't
# use `run` command as it will wipe local variables after execution which is
# crucially required by handle_package_args() to retain local variables.
# See https://github.com/bats-core/bats-core/blob/master/docs/source/gotchas.rst#why-cant-my-function-return-results-via-a-variable-when-using-run


@test "install.init.handle_package_args() test -o output_path flag correct usage" {
  local test_path="/path/to/"
  assert_equal "$output_path" ""
  handle_package_args -o "$test_path"
  assert_equal "$output_path" "$test_path"
}

@test "install.init.handle_package_args() test -o output_path flag missing OPTARG" {
  assert_equal "$output_path" ""
  run handle_package_args -o
  assert_failure
}

@test "install.init.handle_package_args() test -e execute flag correct usage" {
  local test_execute="true"
  assert_equal "$execute" ""
  handle_package_args -e "$test_execute"
  assert_equal "$execute" "$test_execute"
}

@test "install.init.handle_package_args() test -e execute flag missing OPTARG" {
  assert_equal "$execute" ""
  run handle_package_args -e
  assert_failure
}

@test "install.init.handle_package_args() test -f force flag correct usage" {
  local test_force="true"
  assert_equal "$force" ""
  handle_package_args -f "$test_force"
  assert_equal "$force" "$test_force"
}

@test "install.init.handle_package_args() test -f force flag missing OPTARG" {
  assert_equal "$force" ""
  run handle_package_args -f
  assert_failure
}

@test "install.init.handle_package_args() test -s as_root flag correct usage" {
  local test_as_root="true"
  assert_equal "$as_root" ""
  handle_package_args -s "$test_as_root"
  assert_equal "$as_root" "$test_as_root"
}

@test "install.init.handle_package_args() test -s as_root flag missing OPTARG" {
  assert_equal "$as_root" ""
  run handle_package_args -s
  assert_failure
}

@test "install.init.handle_package_args() test invalid -x flag" {
  run handle_package_args -x
  assert_failure
  assert_equal "$status" "$BASH_SYS_EX_USAGE"
}

