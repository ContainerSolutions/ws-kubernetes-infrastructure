#!/bin/bash
# Script used to destroy the GCE K8S cluster
# Make sure to use the same config as this is important to delete dependencies

. ./config.sh
rm users.csv
rm ca.crt

pushd kubernetes
cluster/kube-down.sh
popd
