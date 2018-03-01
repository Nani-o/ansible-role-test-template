#!/bin/bash
####################################################################################

# Exit on failure
set -e

# Set dir vars
DIR="$( cd "$(dirname "$0")" ; pwd -P )"
ROLE_DIR="${DIR}/roles/role-to-test"
TEST_DIR="${ROLE_DIR}/tests"

# Set colors.
NORMAL=$'\E(B\E[m'
RED=$'\E[31m'
GREEN=$'\E[32m'
CYAN=$'\E[36m'

# Display functions
function message()
{
    COLOR="${1}"
    shift
    MESSAGE="${@}"
    echo -e "${COLOR}${MESSAGE}${NORMAL}\n"
}
function execution_message()
{
    message "${CYAN}" "Executing : ${@}"
}
####################################################################################

# Installing Ansible
sudo -H pip install ansible python-netaddr

####################################################################################

# Setting up the test environment
message "${GREEN}" "Setting up the environment for testing"
execution_message ansible-playbook "${DIR}/setup.yml"
ansible-playbook "${DIR}/setup.yml"
execution_message sudo -E ansible-playbook "${DIR}/lxd.yml"
sudo -E ansible-playbook "${DIR}/lxd.yml"

# Copying the role to test
message "${GREEN}" "Copying the role to test"
execution_message cp -rf "$(pwd)" "${ROLE_DIR}"
cp -rf "$(pwd)" "${ROLE_DIR}"

####################################################################################

# Run role setup if present
[[ -f "${TEST_DIR}/setup.yml" ]] && (execution_message sudo -E ansible-playbook "${TEST_DIR}/setup.yml" && sudo -E ansible-playbook "${TEST_DIR}/setup.yml")

# Syntax Checking
message "${GREEN}" "Checking role syntax"
execution_message sudo -E ansible-playbook "${TEST_DIR}/test.yml" --syntax-check
sudo -E ansible-playbook "${TEST_DIR}/test.yml" --syntax-check

# Execution of the role
message "${GREEN}" "Executing the role"
execution_message sudo -E ansible-playbook "${TEST_DIR}/test.yml"
sudo -E ansible-playbook "${TEST_DIR}/test.yml"

# Idempotency of the role
message "${GREEN}" "Testing idempotency"
idempotence=$(mktemp)
execution_message sudo -E ansible-playbook "${TEST_DIR}/test.yml"
sudo -E ansible-playbook "${TEST_DIR}/test.yml" | tee -a ${idempotence}

tail ${idempotence} | grep -q 'changed=0.*failed=0' \
  && (message "${GREEN}" "Idempotence test: pass") \
  || (message "${RED}" "Idempotence test: fail" && exit 1)

# Run additional tests if present
[[ -f "${TEST_DIR}/post-check.yml" ]] && (execution_message sudo -E ansible-playbook "${TEST_DIR}/post-check.yml" && sudo -E ansible-playbook "${TEST_DIR}/post-check.yml")
[[ -f "${TEST_DIR}/test.sh" ]] && (execution_message sudo -E "${TEST_DIR}/test.sh" && sudo -E "${TEST_DIR}/test.sh")

exit 0
