# Nginx Lua helpers for OPH

lua/oph_block.lua
* Checks CSRF: Blocks access if method type is "POST", "PUT", "DELETE", "PATCH" and "CSRF" cookie does not exist or does not have the same value as "X-CSRF" header
* Adds CSRF cookie to response if missing
* Sets ID header to request: All requests are uniquely identified 

lua/oph_log.lua
* Samee as oph_block.lua but only logs errors. Does not block  

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

# Deployment

* Copy all three files so that they're available 
* Add lua_package_path '/path/to/lua/directory;;'; directive to nginx's config at server level 
* Add access_by_lua_file directives to all relevant location blocks
