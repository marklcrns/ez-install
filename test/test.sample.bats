#!/usr/bin/env bats

# This is a sample test file using bats.

load "/opt/bats-test-helpers/bats-support/load.bash"
load "/opt/bats-test-helpers/bats-assert/load.bash"
load "/opt/bats-test-helpers/bats-mock/stub.bash"

@test "sample test" {
  four=4
  [ "$four" -eq 4 ]
}
