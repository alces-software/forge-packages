location = / {
  if ($is_prv_addr = 0) {
    return 307 _REDIRECT_URL_;
  }
}
