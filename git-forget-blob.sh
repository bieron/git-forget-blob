#!/usr/bin/env bash
# Completely remove a file from a Git repository history
#
# Copyleft 2017-2019 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# Usage:
#   git-forget-blob file_to_forget
#
# Notes:
#   It rewrites history, therefore will change commit references and delete tags.
function git-forget-blob()
{
  test -d .git || { echo "Need to be at the base of a Git repository." && return 1; }
  git repack -Aq
  ls .git/objects/pack/*.idx &>/dev/null || {
    echo "There is nothing to be forgotten in this repository." && return 1;
  }

  first_occurrence=`git log --reverse -1 -- $@`
  [ -z "$first_occurrence" ] && { echo "$@ not found in the repository history." && return 1; }

  echo "Wipe out remotes..."
  git remote | xargs -n1 git remote rm
  echo "Modify history..."
  git filter-branch --index-filter "git rm --cached --ignore-unmatch $@" --force -- --branches --tags $first_occurrence^..
  echo "Wipe out refs..."
  rm -rf .git/refs/original/ .git/refs/remotes/ .git/*_HEAD .git/logs/
  (git for-each-ref --format="%(refname)" refs/original/ || echo :) | xargs --no-run-if-empty -n1 git update-ref -d
  echo "Wipe out reflog..."
  git reflog expire --expire-unreachable=now --all
  git repack -q -A -d
  echo "GC prune..."
  git gc --aggressive --prune=now
}
# License
#
# This script is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this script; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA  02111-1307  USA
git-forget-blob "$@"

