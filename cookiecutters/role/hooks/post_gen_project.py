#!/usr/bin/env python3
#
# SPDX-FileCopyrightText: 2020 Open Networking Foundation <support@opennetworking.org>
# SPDX-License-Identifier: Apache-2.0

# role/hooks/post_gen_project.py
# Generates platform-specific files for ansible roles

from __future__ import absolute_import
import os

# Docs for hooks
# https://cookiecutter.readthedocs.io/en/latest/advanced/hooks.html

# Tickets related to what thei above
# https://github.com/cookiecutter/cookiecutter/issues/474
# https://github.com/cookiecutter/cookiecutter/issues/851

# other implementations
# https://github.com/ckan/ckan/blob/master/contrib/cookiecutter/ckan_extension/hooks/post_gen_project.py

# CWD is output dir
PROJECT_DIR = os.path.realpath(os.path.join("..", os.path.curdir))

# Hack, but 'cookiecutter._template' is a relative path
TEMPLATE_DIR = os.path.realpath(
    os.path.join(os.path.curdir, "../{{ cookiecutter._template }}")
)

# script is rendered as a template, so this will be filled in with the
# cookiecutter dict, which is why noqa is needed.
CONTEXT = {{cookiecutter | jsonify}}  # noqa: F821, E227  pylint: disable=E0602


def delete_file(filepath):
    """delete generated file from output directory"""
    os.remove(os.path.join(PROJECT_DIR, filepath))


def delete_inactive_licenses():

    # get list of licenses written to output
    license_dir = os.path.join(os.path.curdir, "LICENSES")
    license_files = os.listdir(license_dir)

    # delete any files that don't start with the license identifier
    for licfile in license_files:
        if not licfile.startswith(CONTEXT["license"]):  # pylint: disable=E1136
            os.remove(os.path.join(os.path.curdir, "LICENSES", licfile))


if __name__ == "__main__":

    delete_inactive_licenses()
