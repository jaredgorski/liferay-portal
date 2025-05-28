#!/bin/bash

NODEHOST_TO_REMOVE="$1"
K3D_INTERNAL_HOST_IP="172.18.0.3"

coredns_configmap_file=$(mktemp /tmp/coredns-configmap.XXXXXX)
new_coredns_configmap_file="${coredns_configmap_file}.new"

kubectl get configmap coredns -n kube-system -o yaml >"$coredns_configmap_file"

NODEHOST_TO_REMOVE_LINE="    ${K3D_INTERNAL_HOST_IP} ${NODEHOST_TO_REMOVE}"

cat "$coredns_configmap_file" | sed -e "/${NODEHOST_TO_REMOVE_LINE}/d" >"$new_coredns_configmap_file"

kubectl apply -f "$new_coredns_configmap_file"

kubectl rollout restart deployments/coredns -n kube-system
