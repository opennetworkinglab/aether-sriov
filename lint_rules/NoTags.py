# SPDX-FileCopyrightText: © 2020 Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

# NoTags.py
# ansible-lint rule to mark all tags as errors

from __future__ import absolute_import
from ansiblelint import AnsibleLintRule


class NoTags(AnsibleLintRule):
    id = "ONF0001"
    shortdesc = "Don't use tags to modify runtime behavior"
    description = (
        "Tags can change which tasks Ansible performs when running a role or"
        "playbook, which is undesirable. Reorganize your roles to not require"
        "them, optionally using setup facts or platform vars as workarounds."
    )
    tags = ["idiom"]
    severity = "HIGH"

    def matchtask(self, file, task):  # pylint: disable=W0613, R0201

        # Task should not have tags
        if "tags" in task:

            # allow if only tag is the skip_ansible_lint tag
            if task["tags"] == ["skip_ansible_lint"]:
                return False

            return True

        return False
