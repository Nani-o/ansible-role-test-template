#!/bin/bash
#
# This script is meant to be run on travis for testing an Ansible role
#
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
function message() {
    COLOR="${1}"
    shift
    MESSAGE="${@}"
    echo -e "${COLOR}${MESSAGE}${NORMAL}\n"
}

function execution_message() {
    message "${CYAN}" "Executing : ${@}"
}

function execute() {
    execution_message "${@}"
    ${@}
}

####################################################################################

# Installing Ansible
sudo -H pip install ansible netaddr

####################################################################################

# Get the os tested
lxd_alias=$(echo ${test_os} | tr "[[:upper:]]" "[[:lower:]]" | sed -E 's@([a-z]*)([0-9].*)@\1/\2/amd64@g')
lxd_containers_names="['$(echo "${containers:-container}" | sed "s/,/','/g")']"

# Setting up the test environment
message "${GREEN}" "Setting up the environment for testing on ${test_os} with lxd container ${lxd_alias}"
execute ansible-playbook "${DIR}/setup.yml"
execute sudo -E ansible-playbook "${DIR}/lxd.yml" --extra-vars "lxd_alias=${lxd_alias}" --extra-vars "lxd_containers_names=${lxd_containers_names}"

# Copying the role to test
message "${GREEN}" "Copying the role to test"
execute cp -rf "$(pwd)" "${ROLE_DIR}"

####################################################################################

# Run role setup if present
[[ -f "${TEST_DIR}/setup.yml" ]] && execute sudo -E ansible-playbook "${TEST_DIR}/setup.yml"

# Get inventory if supplied
[[ -e "${TEST_DIR}/inventory" ]] && execute cp -rf "${TEST_DIR}/inventory" /etc/ansible/

# Syntax Checking
message "${GREEN}" "Checking role syntax"
execute sudo -E ansible-playbook "${TEST_DIR}/test.yml" --syntax-check

# Execution of the role
message "${GREEN}" "Executing the role"
execute sudo -E ansible-playbook "${TEST_DIR}/test.yml"

# Idempotency of the role
message "${GREEN}" "Testing idempotency"
idempotence=$(mktemp)
execution_message sudo -E ansible-playbook "${TEST_DIR}/test.yml"
sudo -E ansible-playbook "${TEST_DIR}/test.yml" | tee -a ${idempotence}

tail ${idempotence} | grep -q 'changed=0.*failed=0' \
  && (message "${GREEN}" "Idempotence test: pass") \
  || (message "${RED}" "Idempotence test: fail" && exit 1)

# Run additional tests if present
[[ -f "${TEST_DIR}/post-check.yml" ]] && execute sudo -E ansible-playbook "${TEST_DIR}/post-check.yml"
[[ -f "${TEST_DIR}/test.sh" ]] && execute sudo -E "${TEST_DIR}/test.sh"

exit 0
