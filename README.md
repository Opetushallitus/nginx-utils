Nginx Lua helpers for OPH

lua/oph_block.lua - Blocks access if method type is "POST", "PUT", "DELETE", "PATCH" and "CSRF" cookie does not exist or does not have the same value as "X-CSRF" header. Adds CSRF cookie to response.

lua/oph_log.lua - Logs CSRF errors and missing Caller-ID and Transaction-ID headers. Adds CSRF cookie to response.  

# Getting started

install openresty or nginx with lua support

# Development

start dev server

    openresty -p . -c dev-server.conf 

reload configs

    openresty -s reload

run automated tests

    ./test.sh

stopping dev server

    openresty -s stop