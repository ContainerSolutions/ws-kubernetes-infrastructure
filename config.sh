#!/bin/bash
# Default configuration

#
# Script specific configuration
#

# USER_GROUPS define which group the user belongs to. By default
# the user is part of the workshop-users group, which can be used
# by RBAC to bind roles.
# If you want the user to have full API access and doesn't
# want to use RBAC, use USER_GROUPS="system:masters"
export USER_GROUPS=${USER_GROUPS:-"workshop-users"}

export USER_COUNT=${USER_COUNT:-20}
export CERT_LOCATION=${CERT_LOCATION:-"/etc/srv/kubernetes/pki/ca.crt"}
#
# Kube-up related configuration
#
export KUBERNETES_PROVIDER=gce
export KUBERNETES_RELEASE=${KUBERNETES_RELEASE:-"v1.9.7"}
export NODE_SIZE=${NODE_SIZE:-"n1-standard-2"}
export NUM_NODES=${NUM_NODES:-5}

# GCE specific
export KUBE_GCE_INSTANCE_PREFIX=${KUBE_GCE_INSTANCE_PREFIX:-"kubernetes"}
export KUBE_GCE_ZONE=${KUBE_GCE_ZONE:-"europe-west1-c"}

# Autoscaling
export KUBE_ENABLE_CLUSTER_AUTOSCALER=${KUBE_ENABLE_CLUSTER_AUTOSCALER:-true}
export KUBE_AUTOSCALER_MIN_NODES=${KUBE_AUTOSCALER_MIN_NODES:-1}
export KUBE_AUTOSCALER_MAX_NODES=${KUBE_AUTOSCALER_MAX_NODES:-10}

# Addons
# https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/registry
# export KUBE_ENABLE_CLUSTER_REGISTRY=${KUBE_ENABLE_CLUSTER_REGISTRY:-true}

