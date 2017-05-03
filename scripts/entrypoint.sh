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
  echo -e "Host $GIT_HOST\n\tStrictHostKeyChecking no\n\tServerAliveInterval 20" >> ~/.ssh/config;
  rm -R /var/www/html;
  git clone -q "$MISC""$GIT_REPO" /var/www || exit 1;
  mkdir -p sites/default/files;
  chown -R www-data:www-data /var/www;
  /usr/local/bin/drush eval "define('DRUPAL_ROOT', '/var/www'); require_once DRUPAL_ROOT . '/includes/bootstrap.inc'; drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);";
  /usr/local/bin/drush eval "watchdog('docker', 'container is running', null);";
  /usr/local/sbin/php-fpm -c /usr/local/etc/php-fpm.conf;
fi
exec "$@"