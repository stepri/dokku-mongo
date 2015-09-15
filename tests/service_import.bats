#!/usr/bin/env bats
load test_helper

setup() {
  export ECHO_DOCKER_COMMAND="false"
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
  echo "data" > "$PLUGIN_DATA_ROOT/fake.dump.tar"
}

teardown() {
  export ECHO_DOCKER_COMMAND="false"
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
  rm -f "$PLUGIN_DATA_ROOT/fake.dump.tar"
}

@test "($PLUGIN_COMMAND_PREFIX:import) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:import"
  assert_contains "${lines[*]}" "Please specify a name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:import) error when service does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:import" not_existing_service
  assert_contains "${lines[*]}" "service not_existing_service does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:import) error when data is not provided" {
  run dokku "$PLUGIN_COMMAND_PREFIX:import" l
  assert_contains "${lines[*]}" "No data provided on stdin"
}

@test "($PLUGIN_COMMAND_PREFIX:import) success" {
  export ECHO_DOCKER_COMMAND="true"
  run dokku "$PLUGIN_COMMAND_PREFIX:import" l < "$PLUGIN_DATA_ROOT/fake.dump.tar"
  password="$(cat "$PLUGIN_DATA_ROOT/l/PASSWORD")"
  assert_output "docker exec -i dokku.mongo.l bash -c DIR=\$(mktemp -d) && tar xf - -C \"\$DIR\" && mongorestore -d l -u \"l\" -p \"$password\" --authenticationDatabase \"l\" \$(find \"\$DIR\" -mindepth 1 -maxdepth 1 -type d | head -n1) && rm -rf \"\$DIR\""
}
