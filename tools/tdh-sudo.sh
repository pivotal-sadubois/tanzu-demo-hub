#!/bin/bash

pw=$1
cmd=$2

expect -f - <<-EOF
  set timeout 10

  spawn sudo $cmd
  expect "*?assword*"
  send -- "$pw\r"
  expect eof
EOF
