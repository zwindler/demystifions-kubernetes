#!/bin/bash
# see https://github.com/rothgar/bashScheduler

kubectl proxy &

curl -sL https://raw.githubusercontent.com/rothgar/bashScheduler/main/scheduler.sh | bash
