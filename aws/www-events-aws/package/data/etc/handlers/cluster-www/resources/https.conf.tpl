server {
  listen _HTTPS_PORT_ ssl default;
  include _ROOT_/etc/clusterware-www/server-https.d/*.conf;
}
