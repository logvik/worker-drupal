#!/bin/bash
#set -eo pipefail
#shopt -s nullglob
if [ ! -z "$GIT_DEPLOY_KEY" ]; then
  echo "Copy deploy key";
  mkdir -p /root/.ssh;
  echo "$GIT_DEPLOY_KEY" >> /root/.ssh/id_rsa;
  chmod 600 /root/.ssh/id_rsa;
fi
MISC=""
if [ ! -z "$GIT_REPO" ]; then
  if [ ! -z "$GIT_TAG" ]; then
    MISC+=" -b $GIT_TAG ";
  fi
  echo "Git clone repo";
  GIT_HOST=$(echo "$GIT_REPO" | grep -oE "@([^:\/])*" | cut -d'@' -f 2);
  echo -e "Host $GIT_HOST\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config;
  git clone -q "$MISC""$GIT_REPO" /var/www;
  mkdir -p sites/default/files;
  chown -R www-data:www-data /var/www;
fi
service php7.0-fpm reload;
exec "$@"