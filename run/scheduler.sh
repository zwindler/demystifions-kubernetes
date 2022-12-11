#!/bin/bash
PATH=$PATH:${pwd}
kube-scheduler --kubeconfig kube-scheduler.conf
