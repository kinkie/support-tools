#!/bin/bash
set -eu -o pipefail

# will be deleted at end of workflow

checkoutDir=$HOME/src/squid-pr-check
repo=git@github.com:squid-cache/squid

git clone $repo $checkoutDir
cd $checkoutDir

pullRequests=`gh pr list -L 200 | awk '{print $1}' | sed 's/[^0-9]//g'`
problematicPullRequests=""

for pr in $pullRequests
do
    gh pr checkout $pr
    if git rebase origin/master ; then
        git switch master
    else
        problematicPullRequests="$problematicPullRequests${problematicPullRequests:+ }$pr"
        git rebase --abort
    fi
done

rm -rf $checkoutDir
echo "Problematic pull requests: $problematicPullRequests"
