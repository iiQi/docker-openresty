#!/usr/bin/env bash

set -euo pipefail

registry=${registry:-''}
registry=${registry#docker.io}
registry=${registry:+$registry/}

sync=${sync:-""}
targetImage=${registry}${image:-''}

syncImage() {
  yq '.[]' <<< "$1"  | while IFS= read -r tag; do
    source=${registry:-''}/${image:-''}:${tag}
    target=${targetImage}:${tag}

    echo "Sync $source ---> $target"

    docker buildx imagetools create --tag "$target" "$source"
  done
}

text=$(yq '.[] | @json' <<< "$sync")
while IFS= read -r line; do
  eval "$(yq -oshell '.' <<< "$line")"

  syncImage "${tags:-''}"
  syncImage "${dev_tags:-''}"

done <<< "$text"