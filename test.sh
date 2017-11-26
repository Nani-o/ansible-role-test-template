#!/bin/bash

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
ROLE_DIR="${DIR}/roles/role-to-test"
TEST_DIR="${ROLE_DIR}/tests"

# Setting up the test environment
ansible-playbook "${DIR}/setup.yml"
sudo -E ansible-playbook "${DIR}/lxd.yml"

# Copying the role to test
cp -rf "$(pwd)" "${ROLE_DIR}"

# Executing tests
sudo -E ansible-playbook "${TEST_DIR}/test.yml"
[[ -f "${TEST_DIR}/test.sh" ]] && "${TEST_DIR}/test.sh"
