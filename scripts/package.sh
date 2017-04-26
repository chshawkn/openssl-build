#!/usr/bin/env bash

function package() {
    local target_dir="${1}"
    local lib_name="${2}"
    local artifact_dirs=($(find ${target_dir} -mindepth 1 -maxdepth 1 -type d | awk -F "${target_dir}/" '{print $2}' | grep "${lib_name}"))
    for artifact_dir in "${artifact_dirs[@]}"; do
        echo "package: ${artifact_dir} into ${artifact_dir}.tar.gz"
        tar czf "${artifact_dir}.tar.gz" "${artifact_dir}"
    done
}
