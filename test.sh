#!/bin/bash

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
ROLE_DIR="${DIR}/roles/role-to-test"
TEST_DIR="${ROLE_DIR}/tests"

function message()
{
    COLOR="${1}"
    MESSAGE="${2}"
    echo -e "${COLOR}${MESSAGE}${NORMAL}\n"
}

function execution_message()
{
    message "${GREEN}" "Executing : ${@}"
}

# Setting up the test environment
execution_message ansible-playbook "${DIR}/setup.yml"
ansible-playbook "${DIR}/setup.yml"
execution_message sudo -E ansible-playbook "${DIR}/lxd.yml"
sudo -E ansible-playbook "${DIR}/lxd.yml"

# Copying the role to test
execution_message cp -rf "$(pwd)" "${ROLE_DIR}"
cp -rf "$(pwd)" "${ROLE_DIR}"

# Executing tests
execution_message sudo -E ansible-playbook "${TEST_DIR}/test.yml"
sudo -E ansible-playbook "${TEST_DIR}/test.yml"
[[ -f "${TEST_DIR}/test.sh" ]] && "${TEST_DIR}/test.sh"
