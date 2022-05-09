Aether Ansible
==============

Ansible is an automation tool used to install software and configure systems.
It's frequently used either standalone or in concert with other
operations-focused software.

The primary advantage of Ansible is that it is "target neutral" - the system
being configured can be a physical device, a virtual server, a VM image, a
docker container image, etc., which reduces duplication of effort. For example,
the executors used in Jenkins can be a Packer images or physical servers. Being
able to share the same roles to install and configure software on both helps
reduce overhead and increase uniformity.

It also can targets basically any system that has a command line interface,
even unusual platforms with non-Unix CLIs such as on networking equipment or
Windows.

Ansible Docs and Reference
--------------------------

A good place to start learning about Ansible is the [Intro to
Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html).

Additional useful references:

- [Ansible Best Practices: The
  Essentials](https://www.ansible.com/blog/ansible-best-practices-essentials).
- [high quality ansible
  playbooks](https://sysdogs.com/en/on-code-quality-with-ansible/).
- [Jinja2 template
  documentation](https://jinja.palletsprojects.com/en/master/templates/)
- [filters](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html)
- [module return
  values](https://docs.ansible.com/ansible/latest/reference_appendices/common_return_values.html)

We\'re following the Linux Foundation hierarchy and naming scheme for Ansible
roles - see the [ansible/role/\* repos on LF
Gerrit](https://gerrit.linuxfoundation.org/infra/admin/repos), and the [LF
Ansible guide](https://docs.releng.linuxfoundation.org/en/latest/ansible.html).

This aligns with how things work across a variety of tools and systems -
see the [gerrit docs on
replication](https://gerrit.googlesource.com/plugins/replication/+doc/master/src/main/resources/Documentation/config.md),
specifically the [remote.NAME.remoteNameStyle]{.title-ref} section -
if/when these are replicated on GitHub, that config will cause the repo
to be renamed from [ansible/role/\<rolename\>]{.title-ref} to
[ansible-role-\<rolename\>]{.title-ref}, which goes along with how
[Ansible Galaxy has traditionally named
roles](https://galaxy.ansible.com/docs/contributing/creating_role.html#role-names).

Running Playbooks
-----------------

Playbooks are run from within a python virtualenv, to ensure that all the
correct versions are available. The `galaxy` target will create this virtualenv
and also download dependent roles and collections from [ansible
galaxy](https://galaxy.ansible.com/):

    $ make galaxy
    ...
    $ source venv_onfansible/bin/activate

Once you've done this, you can run the `ansible-plabook` command.

Playbooks are stored in the `playbooks` directory. Note that playbooks can be
organized in this way, but the [*_vars directries must be relative to either
the inventory or playbook
files](https://github.com/ansible/ansible/issues/12862#issuecomment-461015045),
and any `files` directories must be relative to the root directory or
`playbooks`.

The convention for naming of playbooks is to name them
`<purpose>-playbook.yml`.

Inventory sources are stored in the `inventory` directory.

A typical invocation would be:

    $ ansible-playbook -i inventory/<source>.ini playbooks/static-playbook.yml


Starting a New Role
-------------------

1. Create the virtualenv with the Makefile, and source the activate
   script:

      $ make venv_onfansible
      ...
      $ source venv_onfansible/bin/activate

2. Run cookiecutter with the path to the role cookiecutter template:

      $ cd roles
      $ cookiecutter ../cookiecutters/role

  Answer the questions given, especially the name which will be the name of the
  role, and it will create a role directory with those answers. The default
  answers will result in Ubuntu 16.04 and 18.04 molecule tests, using a docker
  image that runs the systemd init system, to allow daemons to be run in the
  container.

3. Initialize git and commit the files as created by cookiecutter:

      $ cd <rolename>
      $ git add .
      $ git commit -m "initial <rolename> role"

4. Lint and test the role with `make lint` (runs static checks) and `make test`
   (tests the role with Molecule). This should be done before making changes,
   to make sure the test process works locally on your system.

5. Make changes to the role, running the tests given in #3 periodically. See
   the `Testing`{.interpreted-text role="ref"} section below for how to run
   Molecule tests incrementally.

6. Add comprehensive tests to the files in the `molecule/default/verify.yml`
   file. See the `nginx` role as an example.

Role and Playbook Style Guide
-----------------------------

Use the `.yml` extension for all YAML files. This is a convention used by most
Ansible roles and when autogenerating a role with various tools like Galaxy or
Molecule.

Ansible roles and playbooks should pass both
[ansible-lint](https://github.com/ansible/ansible-lint) and
[yamllint](https://github.com/adrienverge/yamllint) in strict mode, to verify
that they are well structured and formatted.  [yamllint]{.title-ref} in
particular differs from most Ansible examples when it comes to booleans -
lowercase [true]{.title-ref} and [false]{.title-ref} should be used instead of
other "truthy" values like [yes]{.title-ref} and [no]{.title-ref}. There are
some cases when an Ansible modules will require that you use these "truthy"
values, in which case you can [disable
yamllint](https://yamllint.readthedocs.io/en/stable/disable_with_comments.html)
for just that line. `ansible-lint` can also be [disabled per-line or
  per-task](https://github.com/ansible/ansible-lint#false-positives-skipping-rules)
  but this should be avoided when possible.

If you need to separate a long line to pass lint, make use of the YAML `>`
folded block scalar syntax which replaces whitespace/newlines replaced with
single spaces (good for wrapping long lines) or `|` literal block scalar syntax
which will retain newlines but replace whitespace with single spaces (good for
inserting multiple lines of text into the output). More information is
available at [yaml multiline strings](https://yaml-multiline.info/). The flow
scalar syntax is less obvious and easier to accidentally introduce mistakes
with, so using it isn't recommended.

While ansible-lint tends to direct you to solution that improve your roles most
of the time, the [503 warning may introduce additional
complexity](https://github.com/ansible/ansible-lint/issues/419) and may be
skipped.

When listing parameters within a task, put parameters each on their own line
(the YAML style). Even though there are examples of the `key=value` one-line
syntax for assigning parameters, avoid using it in favor of the YAML syntax.
This makes diffs shorter and easier to inspect, and helps with linting.

Roles have to places to define variables - `defaults` and `vars`. The major
difference between these is how [variable precedence works in
Ansible](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable).
In general, you should only define variables that will never need to be
overridden by a user or playbook (for example platform-specific or OS-specific
variables) in the `vars/<platformname>.yml` files. The `defaults/main.yml` file
should contain examples variables or defaults values that work across all
platforms supported by a role.

To ensure the integrity of artifacts and other items downloaded from the
internet as a part of the role, you should provide checksums and keys as a part
of the role. Some examples of this are:

-   Using the `checksum` field on
    [get_url](https://docs.ansible.com/ansible/latest/modules/get_url_module.html)
    and similar modules. This will also save time, as during subsequent runs if
    the checksum matches an already-downloaded file, the download won\'t be
    required.

-   For package signing keys and GPG keys, put them as files within the role
    and use a file lookup when using the
    [apt_key](https://docs.ansible.com/ansible/latest/modules/apt_key_module.html)
    and similar modules. `apt_key` requires an "ASCII Armored" GPG key to be
    used with it - if upstream provides a binary version, convert it with `gpg
    --enarmor file.gpg` and which creates a `file.gpg.asc` version.

When optionally executing a task using `when`, it's easier to follow if you
put the `when` condition right after the name of the task, not at the end of
the action as is shown in many examples:

``` {.yaml}
- name: Run command only on Debian (and Ubuntu)
  when: ansible_os_family == "Debian"
  command:
    cmd: echo "Only run on Debian"
```

The `with_items` and other `with_*` iterators should be put at the end of the
task.

Handlers should be named `<action>-<subject>` for consistency - examples:
`restart-nginx` or `start-postgres`.

If you are iterating on lists that contains password or other secure data that
should not be leaked into the output, set `no_log: true` so the items being
iterated on are not printed.

All templated files should contain a commented line with `{{ ansible_managed
}}`, to indicate that the file is managed by ansbile, when it was created, and
by what user.

Avoid using `tags`, as these are generally used to change the behavior
of a role or playbook in an arbitrary way - instead use information
derived from setup to control optional actions, or use different roles
to separate which tasks are run. Use of tags other than the
`skip_ansible_lint` tag will cause the lint to fail. See also [Ansible:
Tags are a code
smell](https://medium.com/@gswallow/ansible-tags-are-a-code-smell-bf80bd88cb79)
for additional perspective.

If you need to modify behavior in a platform-specific way, use the setup
facts to determine which tasks to run. You can get a list of setup facts
by running `ansible -m setup` against a target system.

Do not change the default value of the
[hash\_behaviour](https://docs.ansible.com/ansible/latest/installation_guide/intro_configuration.html#hash-behaviour)
variable - the default `replace` setting is more deterministic, easier
to understand, and handles removal of items, all of which can\'t be
achieved with other values of this setting.

What goes where?
----------------

Generally, roles are split into two major groups:

### Configuration roles

These roles configure or set up basic system functionality or do basic
scripting and maintenance of the system.

Examples:

-   Configuration of the \"base system\" (anything that is pre-installed
    by the default installation)
    -   Configuring cron, logging, etc.
    -   Adding scripts for system tasks like backup
-   Creating user accounts (see the `provision-users` role)
-   Changing network settings (Firewall, VPN, etc.)

### Installation Roles

These are roles that add software to the base system, in various ways,
and should install and configure software that is not automatically
installed in the base installation.

Examples:

-   Installing software like `nginx`, `acme.sh`, or `postgres`
    -   Creating limited privilege role accounts for running the
        software
    -   Configuring the software installed

### Group Vars

The `group_vars` directory should contain variables specific to a
sub-classification of hosts - this is usually done on a per-site, or
per-function basis. These are named `<groupname>.yml`.

### Host Vars

The `host_vars` contains variables specific to a host, and should have
files named `<hostname>.yml`.

### Inventory

Inventory is the list of hosts and what group they should be assigned
into.

Currently these lists are being kept in flat files in the `inventory`
directory, but in the future they\'ll be dynamically built from NetBox
or a similar IPAM system.

Linting and code quality
------------------------

All YAML files (including Ansible playbooks, roles, etc. ) are scanned
with `yamllint`.

All Ansible playbooks and roles are scanned with `ansible-lint`.  Occasionally,
you may run into issues that look like this:

    CRITICAL Couldn't parse task at molecule/default/verify.yml:27 (couldn't
    resolve module/action 'community.mysql.mysql_query'. This often indicates a
    misspelling, missing collection, or incorrect module path.)

This happens when `ansible-lint` can't find the correct collection. To resolev,
set the variable ANSIBLE_COLLECTIONS_PATHS to the ansible directory - example:

   export ANSIBLE_COLLECTIONS_PATHS=~/Documents/onf/infra/ansible

Python code is formatted with [black](https://github.com/psf/black), and
must pass [flake8](https://flake8.pycqa.org/) and [pylint (py3k compat
check only)](https://www.pylint.org/) .

Testing
-------

Tests are done on a per-role basis using
[Molecule](https://molecule.readthedocs.io/), which can test the role
against Docker containers (the default) or Vagrant VMs (more complicated
to set up).

If the role will run a daemon you should request that the container is
run in privileged mode, which will run an init daemon to start the
services (in most cases, `systemd`). The `-priv` Docker images that are
used includes a working copy of `systemd`, like a physical system would
have, and are created from the
[paulfantom/dockerfiles](https://github.com/paulfantom/dockerfiles)
repo.

If the role depends on other roles to function (needs a database or JRE)
you can install those other roles in the `prepare.yml` playbook. See the
`netbox` role for an example. This prepare playbook will only be run
once during the initial setup of the container/VM, not every time the
`converge` is run.

Individual steps of the test process can be run from Molecule - see the
[test sequence
commands](https://molecule.readthedocs.io/en/latest/getting-started.html#run-test-sequence-commands).

The most frequently used commands during role development are:

- `molecule converge`: Bring up the container and run the playbook against it
- `molecule verify`: Run the `verify.yaml` playbook to test
- `molecule login`: Create an interactive shell session inside the container/VM
  to manually debug problems
- `molecule destroy`: Stop/destroy all the containers
- `molecule test`: Run all the steps automatically

A common devel loop when editing the role is to run:

    molecule converge; molecule verify

If you need more verbose output from the underlying ansible tools add the
`--debug` flag to the `molecule` command, which will pass the `-vvv` verbose
parameter to `ansible-playbook`.

OS Differences
--------------

The setup module isn't regular between OS's with the `ansible_processor_*`
options. OpenBSD has quoted numbers for quantities, Linux does not.
`ansible_processor_count` is sockets on Linux, but the same as number of cores
on OpenBSD.  There are also sometimes differences between Linux distros - YMMV.

Similar issues with network interface configuration - on Linux the
`ansible_eth0['ipv4']` is a dict, but it's a list in OpenBSD.

Known Issues
------------

Currently [ansible-lint throws exceptions when using modules from
collections](https://github.com/ansible/ansible-lint/issues/538), which makes
checking some playbooks difficult with that tool. This primarily affects the
NetBox related tasks.

This repo does not pass the REUSE check because of [REUSE issue
246](https://github.com/fsfe/reuse-tool/issues/246).
