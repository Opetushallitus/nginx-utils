#!/bin/bash
set -e

function assert() {
  CMD=$1
  shift
  echo "$CMD"
  OUTPUT=$($CMD 2>&1)
  ARGS=$*
  for ((i = 1; i < ($#+1); i++))
  do
    txt=${!i}
    echo " * assert: '$txt'"
    if [[ $OUTPUT == *"$txt"* ]]; then
      true;
    else
      echo "Output of '$CMD' does not contain '$txt': '$OUTPUT'"
      exit 1  
    fi
  done
  echo " => OK"
  echo
}

function reset() {
  rm -f logs/error.log
  openresty -s reload
  sleep 0.1
}

reset

# regular GET
assert 'curl -s -v http://localhost:20100/proxypass' "Set-Cookie: CSRF" "id:" "Request handled by LUA at app server"

# valid GET with external ID
assert 'curl -s -v  --header id:pow http://localhost:20100/proxypass' "id: pow;" "Set-Cookie: CSRF" "Request handled by LUA at app server"

# regular GET should log error about Caller-Id
reset
assert 'curl -s -v --cookie CSRF=123 --header Caller-Id:Sure http://localhost:20100/proxypass' "id: 123;" "Request handled by LUA at app server"
assert 'cat logs/error.log' 'ERROR: "CALLER-ID" caller-id: "Sure" id: "123;'

# valid POST without CLIENTSUBSYSTEMCODE
reset
assert 'curl -s -v --data param=1 --cookie CSRF=123 --header CSRF:123 http://localhost:20100/proxypass' "id: 123;" "Request handled by LUA at app server"
assert 'cat logs/error.log' 'ERROR: "NO-CLIENTSUBSYSTEMCODE" id: "'

# invalid CSRF POST
reset
assert 'curl -s -v --data param=1 --cookie CSRF=123 --header CSRF:124 http://localhost:20100/proxypass' Invalid
assert 'cat logs/error.log' 'ERROR: "CSRF-MISMATCH|NO-CLIENTSUBSYSTEMCODE" id: "'

# invalid CSRF POST
reset
assert 'curl -s -v --data param=1 --cookie CSRF=123 --header CSRF:1234 --header clientSubSystemCode:Sure http://localhost:20100/proxypass' Invalid
assert 'cat logs/error.log' 'ERROR: "CSRF-MISMATCH" clientSubSystemCode: "Sure" id: "'

# invalid CSRF POST, missing cookie
reset
assert 'curl -s -v --data param=1 --header CSRF:123 --header clientSubSystemCode:Sure http://localhost:20100/proxypass' Invalid "Set-Cookie: CSRF"
assert 'cat logs/error.log' 'ERROR: "NO-CSRF-COOKIE" clientSubSystemCode: "Sure" id: "'

# invalid CSRF POST, missing header
reset
assert 'curl -s -v --data param=1 --cookie CSRF=1234 --header clientSubSystemCode:Sure http://localhost:20100/proxypass' Invalid
assert 'cat logs/error.log' 'ERROR: "NO-CSRF-HEADER" clientSubSystemCode: "Sure" id: "'

# invalid CSRF POST gets JSON response
reset
assert 'curl -s -v --data param=1 --cookie CSRF=123 --header CSRF:124 --header clientSubSystemCode:Sure --header Accept:application/json http://localhost:20100/proxypass' "{'error': 'Invalid request"
assert 'cat logs/error.log' 'ERROR: "CSRF-MISMATCH" clientSubSystemCode: "Sure" id: "'

### oph_log

# regular GET
assert 'curl -s -v http://localhost:20100/proxypass_log' "Set-Cookie: CSRF=" "id:" "Request handled by LUA at app server"

# valid POST
assert 'curl -s -v --data param=1 --cookie CSRF=123 --header CSRF:123 http://localhost:20100/proxypass_log' "Request handled by LUA at app server"

# invalid CSRF POST passes through but is logged
reset
assert 'curl -s -v --data param=1 --cookie CSRF=123 --header CSRF:124 --header Caller-Id:Sure --header clientSubSystemCode:Sure http://localhost:20100/proxypass_log' "Request handled by LUA at"
assert 'cat logs/error.log' 'ERROR: "CSRF-MISMATCH|CALLER-ID" caller-id: "Sure" clientSubSystemCode: "Sure" id: "123;'

echo "*** Tests OK"
