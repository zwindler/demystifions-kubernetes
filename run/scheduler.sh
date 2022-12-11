#!/bin/bash
PATH=$PATH:${pwd}
kube-scheduler --kubeconfig admin.conf
