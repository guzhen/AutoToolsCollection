#!/bin/bash

function run()
{
  set -x
  whoami # root
  pwd    # /home
}

run >& /home/latecmd.log
