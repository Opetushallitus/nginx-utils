Nginx Lua helpers for OPH

lua/oph_block - Blocks access if method type is "POST", "PUT", "DELETE", "PATCH" and "CSRF" cookie does not exist or does not have the same value as "X-CSRF" header
  

# Getting started

install openresty or nginx with lua support

# Development

start dev server

    openresty -p . -c dev-server.conf 

reload configs

    openresty -s reload

test that csrf blocking works

    curl --data "param=1" --cookie "CSRF=123" --header "X-CSRF: 123" http://localhost:20100/lua
    curl --data "param=1" --cookie "CSRF=123" --header "X-CSRF: 123" --header "Accept: application/json" http://localhost:20100/lua

stopping dev server

    openresty -s stop