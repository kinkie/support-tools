#!/bin/bash

branch=$(git branch | awk '/^\*/ { print $2}')
if [ -z "$branch" ] ; then
    echo "can't identify branch"
    exit 1
fi
echo "branch: $branch"

fork_point=$(git merge-base --fork-point upstream/master $branch)
if [ -z "$fork_point" ]; then
    echo "can't identify fork point"
    exit 1
fi
echo "fork point: $fork_point"

git tag -a "$branch-presquash" -m "pre-squash branch marker"
git reset --soft $fork_point
git status

cat <<_EOF
Pease check that everything is okay then 
git commit
git tag -d $branch-presquash

or rollback with
git reset --hard $branch-presquash
_EOF
