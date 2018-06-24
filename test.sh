#!/bin/bash
#
# This script is meant to be run on travis for testing an Ansible role
#
####################################################################################

# Exit on failure
set -eE

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

function error_message() {
    message "${RED}" "${@}"
}

function execute() {
    execution_message "${@}"
    ${@}
}

function travis_fold_start() {
    echo -en "travis_fold:start:${1}\r"
}

function travis_fold_end() {
    echo -e "travis_fold:end:${1}\r"
}

function travis_time_start() {
    time_uuid=$(printf %08x $(( RANDOM * RANDOM )))
    start_timestamp=$(date +%s%N)
    echo -e "travis_time:start:${time_uuid}\r"
}

function travis_time_end() {
    finish_timestamp=$(date +%s%N)
    duration_timestamp="$((${finish_timestamp}-${start_timestamp}))"
    echo -e "travis_time:end:${time_uuid}:start=${start_timestamp},finish=${finish_timestamp},duration=${duration_timestamp}\r"
}

function travis_label_start() {
    travis_fold_start "${1}"
    travis_time_start
}

function travis_label_end() {
    travis_time_end
    travis_fold_end "${1}"
}

function fold() {
    fold_name="${1}"
    shift
    travis_fold_start "${fold_name}"
    ${@}
    travis_fold_end "${fold_name}"
}

# Trap exit
function finish() {
    travis_label_end "${fold_name}"
}
trap finish ERR

####################################################################################

# Test and setup functions

function install_ansible() {
    # Installing Ansible
    ansible_version=$(pip search ansible | grep -e '^ansible (' | awk '{print $2}')
    message "${GREEN}" "Installing ansible ${ansible_version}"
    execute sudo -H pip install ansible netaddr
}

function setup_env() {
    # Get the os tested
    lxd_alias=$(echo ${test_os} | tr "[[:upper:]]" "[[:lower:]]" | sed -E 's@([a-z]*)([0-9].*)@\1/\2/amd64@g')
    lxd_containers_names="['$(echo "${containers}" | sed "s/,/','/g")']"

    # Setting up the test environment
    message "${GREEN}" "Setting up the environment for testing on ${test_os} with lxd container ${lxd_alias}"
    execute ansible-playbook "${DIR}/setup.yml" "${ansible_debug}"
    execute sudo -E ansible-playbook "${DIR}/lxd.yml" --extra-vars "lxd_alias=${lxd_alias}" --extra-vars "lxd_containers_names=${lxd_containers_names}" "${ansible_debug}"

    # Copying the role to test
    message "${GREEN}" "Copying the role to test"
    execute cp -rf "$(pwd)" "${ROLE_DIR}"

    # Run role setup if present
    [[ -f "${TEST_DIR}/setup.yml" ]] && execute sudo -E ansible-playbook "${TEST_DIR}/setup.yml" "${ansible_debug}"

    # Get inventory if supplied
    [[ -e "${TEST_DIR}/inventory" ]] && execute cp -rf "${TEST_DIR}/inventory" /etc/ansible/
}

function test_syntax() {
    # Syntax Checking
    message "${GREEN}" "Checking role syntax"
    execute sudo -E ansible-playbook "${TEST_DIR}/test.yml" --syntax-check
}

function test_role() {
    # Execution of the role
    message "${GREEN}" "Executing the role"
    execute sudo -E ansible-playbook -b --become-method=su "${TEST_DIR}/test.yml" "${ansible_debug}"
}

function test_idempotency() {
    # Idempotency of the role
    message "${GREEN}" "Testing idempotency"
    execute sudo -E ansible-playbook -b --become-method=su "${TEST_DIR}/test.yml" "${ansible_debug}"

    tail "${DIR}"/ansible.log | grep -q 'changed=0.*failed=0' \
      && (message "${GREEN}" "Idempotence test: pass") \
      || (message "${RED}" "Idempotence test: fail" && exit 1)
}

function test_extras() {
    # Run additional tests if present
    message "${GREEN}" "Running post-checks if present"
    [[ -f "${TEST_DIR}/post-check.yml" ]] && execute sudo -E ansible-playbook -b --become-method=su "${TEST_DIR}/post-check.yml" "${ansible_debug}"
    [[ -f "${TEST_DIR}/test.sh" ]] && execute sudo -E "${TEST_DIR}/test.sh"
}

####################################################################################

# Get ENV vars
[[ -z "${test_os}" ]] && (error_message "ENV_VAR test_os not defined" && exit 1)
containers="${containers:-container}"
debug="${debug:-false}"
[[ "${debug,,}" == "true" ]] && ansible_debug="-v"

####################################################################################

# Executing setups and tests inside travis fold
fold "install_ansible" install_ansible
fold "setup_env" setup_env
fold "test_syntax" test_syntax
fold "test_role" test_role
fold "test_idempotency" test_idempotency
fold "test_extras" test_extras

####################################################################################

exit 0
