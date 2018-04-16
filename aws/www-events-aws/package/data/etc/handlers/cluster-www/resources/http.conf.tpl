server {
  listen _HTTP_PORT_ default;
  include _ROOT_/etc/clusterware-www/server-http.d/*.conf;
}
