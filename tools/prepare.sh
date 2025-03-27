#!/usr/bin/env bash

set -euxo pipefail

VERSION_URL=${VERSION_URL:-"https://api.github.com/repos/openresty/openresty/releases"}
registries=${registries:-""}
registries=$(printf "registry,image,username,password\n%s" "$registries" | yq -p csv '@json')

buildRegistry=$(yq '.[:1][] | @json' <<<"$registries")
syncRegistries=$(yq '.[1:] | @json' <<<"$registries")

version=${version:-$(curl -s "$VERSION_URL" | yq '.[0].tag_name')}
version=${version#v}
flavors=${flavors:-"alpine-apk as alpine,bookworm"}

export buildRegistry version

buildText=$(yq '
    split(",")
    | map(
      . | split(" as ") | {
        "flavor": .[0],
        "alias": .[1] // .[0]
      }
    )
    | .[] | . as $flavor
    | env(version) as $version
    | {"version": $version, "flavor": $flavor.flavor, "alias": $flavor.alias}
    | @json
    ' <<<"$flavors")

buildConfig='[]'
while IFS= read -r line; do
  eval "$(yq -oshell '. |= with_entries(.key = (.key | upcase))' <<<"$line")"

  MINOR_VERSION=${VERSION%.*}

  export VERSION FLAVOR ALIAS MINOR_VERSION

  line=$(yq '
      .minor_version = (env(MINOR_VERSION) | to_string)
      | .tags = ([ [env(MINOR_VERSION), env(VERSION)][] | . + "-" + env(ALIAS) ] | @json)
      | . * env(buildRegistry)
      ' <<<"$line")

  buildConfig=$(item=$line yq '. *+ [env(item)] | @json' <<<"$buildConfig")
done <<<"$buildText"

export buildConfig

syncConfig=$(yq 'map(. |= . * {"sync": ( env(buildConfig) | @json )}) | @json' <<<"$syncRegistries")
