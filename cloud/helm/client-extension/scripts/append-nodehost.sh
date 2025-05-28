#!/bin/sh

NODEHOST_TO_APPEND="$1"
K3D_INTERNAL_HOST_IP="172.18.0.3"

coredns_configmap_file=$(mktemp /tmp/coredns-configmap.XXXXXX)
new_coredns_configmap_file="${coredns_configmap_file}.new"

kubectl get configmap coredns -n kube-system -o yaml >"$coredns_configmap_file"

sanitize () {
	tr '\n' '\f'
}

desanitize () {
	tr '\f' '\n'
}

NODEHOSTS_KEY="NodeHosts: |"
NEW_NODEHOST_LINE="    ${K3D_INTERNAL_HOST_IP} ${NODEHOST_TO_APPEND}"
NEW_NODEHOSTS_SECTION=$(printf '%s\n%s' "$NODEHOSTS_KEY" "$NEW_NODEHOST_LINE")
NEW_NODEHOSTS_SECTION_SANITIZED=$(echo -n "$NEW_NODEHOSTS_SECTION" | sanitize)

cat "$coredns_configmap_file" | sed -e "s/${NODEHOSTS_KEY}/${NEW_NODEHOSTS_SECTION_SANITIZED}/g" | desanitize >"$new_coredns_configmap_file"

kubectl apply -f "$new_coredns_configmap_file"

kubectl rollout restart deployments/coredns -n kube-system
