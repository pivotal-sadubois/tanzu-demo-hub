#!/bin/sh
[ "${DEBUG:-0}" = "1" ] && set -x

SCRIPT="$0"
command -v readlink 2>/dev/null 1>/dev/null && SCRIPT="$(readlink -f "$0")"

if [ "$1" = "--install" ] ; then
    git config --local credential.helper "/bin/sh $SCRIPT"
    exit $?
fi

printf "username=%s\n" "$GIT_USERNAME"
printf "password=%s\n" "$GIT_PASSWORD"

