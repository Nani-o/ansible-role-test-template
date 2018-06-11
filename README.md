Template for testing roles
==========================

This an Ansible project template that I use with travis to test my roles. The main idea behind this is :

  - Setting up an ansible project
  - Play my lxd role to deploy a container using ENVIRONMENT variables
  - Play the role to test on the container checking for :
    - syntax
    - correct execution
    - idempotence
  - Execute specific tests if supplied

Requirements
------------

  - Ubuntu 14.04
  - Ubuntu 16.04

The purpose of this project is to be used with travis, as of now it means running on Ubuntu trusty.

### test folder

In order to use this template, the role to be tested should have a **tests** folder with a **test.yml** playbook.

```
tests
 |-- test.yml ............ The playbook meant to run the role, use role-to-test as a placeholder for the role name
 |-- post-check.yml ...... Optionnal playbook for running any test you'd like with Ansible
 |-- test.sh ............. Optionnal script for running any test you'd like with Ansible
```

Here's what **test.yml** should like :

```YAML
---
- hosts: container
  roles:
    - role-to-test
```

### .travis.yml file

Inside your **.travis.yml** use **test_os** as environment variable for defining the operating system you would like to test.
The images are retrieved from [linuxcontainers.org](https://images.linuxcontainers.org), for clarity instead of using the alias required by the lxd API (e.g : os/version/arch) use this naming scheme :

test_os value | lxd alias
------------- | ---------
centos7 | centos/7/amd64
ubuntu16.04 | ubuntu/16.04/amd64
debian9 | debian/9/amd64
... | ...

Here's what your **.travis.yml** should like :

```YAML
---
dist: trusty
language: python
python: "2.7"

sudo: true

env:
  - test_os: centos7
  - test_os: centos6
  - test_os: ubuntu16.04
  - test_os: ubuntu14.04
  - test_os: debian9
  - test_os: debian8

install:
  # Cloning testing template
  - sudo mkdir /etc/ansible
  - sudo chown -R "${USER}:" /etc/ansible
  - git clone https://github.com/Nani-o/ansible-template-role-test /etc/ansible

script:
  # Run tests
  - bash /etc/ansible/test.sh
```

Example
-------

Most of [my roles](https://github.com/search?q=user%3ANani-o+ansible-role&type=Repositories) use this template, for example check my [netdata](https://github.com/Nani-o/ansible-role-netdata) role.

License
-------

MIT

Author Information
------------------

Sofiane MEDJKOUNE
