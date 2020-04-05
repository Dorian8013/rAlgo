#!/usr/bin/env bash

set -euxo pipefail

tar xf $HOME/lxc/cache.tar -C / || echo "Didn't extract cache."
cp -f tests/lxd-bridge /etc/default/lxd-bridge
cp -f tests/ralgo.conf /etc/default/ralgo.conf

cp config.cfg.example config.cfg

export REPOSITORY=${REPOSITORY:-${GITHUB_REPOSITORY}}
export _BRANCH=${BRANCH#refs/heads/}
export BRANCH=${_BRANCH:-${GITHUB_REF#refs/heads/}}

if [[ "$DEPLOY" == "cloud-init" ]]; then
  bash tests/cloud-init.sh | lxc profile set default user.user-data -
else
  echo -e "#cloud-config\nssh_authorized_keys:\n - $(cat ~/.ssh/id_rsa.pub)" | lxc profile set default user.user-data -
fi

systemctl restart lxd-bridge.service lxd-containers.service lxd.service

lxc profile set default raw.lxc lxc.aa_profile=unconfined
lxc profile set default security.privileged true
lxc profile show default
lxc launch ubuntu:${UBUNTU_VERSION} ralgo

ip addr

until dig A +short ralgo.lxd @10.0.8.1 | grep -vE '^$' > /dev/null; do
  sleep 3
done

lxc list
