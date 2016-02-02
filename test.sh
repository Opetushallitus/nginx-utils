#!/bin/bash
set -e

function assert() {
  CMD=$1
  shift
  OUTPUT=$($CMD 2>&1)
  ARGS=$*
  for ((i = 1; i < ($#+1); i++))
  do
    txt=${!i}
    if [[ $OUTPUT == *"$txt"* ]]
    then
      true;
    else
      echo "Output of '$CMD' does not contain '$txt': '$OUTPUT'"
      exit 1  
    fi
  done
  echo "$CMD => OK"
}

# regular GET
assert 'curl -s -v http://localhost:20100/proxypass' "Set-Cookie: CSRF" "id:" "Request handled by LUA at app server"

# valid POST
assert 'curl -s -v --data "param=1" --cookie CSRF=123 --header X-CSRF:123 http://localhost:20100/proxypass' "Request handled by LUA at app server"

# invalid CSRF POST
assert 'curl -s -v --data "param=1" --cookie CSRF=123 --header X-CSRF:124 http://localhost:20100/proxypass' Invalid

# invalid CSRF POST
assert 'curl -s -v --data "param=1" --cookie CSRF=123 --header X-CSRF:1234 http://localhost:20100/proxypass' Invalid

# invalid CSRF POST
assert 'curl -s -v --data "param=1" --cookie CSRF=1234 --header X-CSRF:123 http://localhost:20100/proxypass' Invalid

# valid GET with ID
assert 'curl -s -v  --header id:pow http://localhost:20100/proxypass' "id: pow;"

# regular GET
assert 'curl -s -v http://localhost:20100/proxypass_log' "Set-Cookie: CSRF" "id:" "Request handled by LUA at app server"

# valid POST
assert 'curl -s -v --data "param=1" --cookie CSRF=123 --header X-CSRF:123 http://localhost:20100/proxypass_log' "Request handled by LUA at app server"

# invalid CSRF POST
assert 'curl -s -v --data "param=1" --cookie CSRF=123 --header X-CSRF:124 http://localhost:20100/proxypass_log' "Request handled by LUA at"

echo "Tests OK"
