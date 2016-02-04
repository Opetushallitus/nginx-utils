#!/bin/bash

set -e

function reset() {
  openresty -s reload
  sleep 0.1
  curl http://127.0.0.1:20100/proxypass > /dev/null
}

rm -rf logs/*

echo "***************************************************************"
echo Direct access without LUA
reset
curl http://127.0.0.1:20100/proxypass_direct > /dev/null
ab -n1000 -c20 -C CSRF=pow http://127.0.0.1:20100/proxypass_direct

echo "***************************************************************"
echo Regular GET
reset
ab -n1000 -c20 http://127.0.0.1:20100/proxypass

echo "***************************************************************"
echo GET with CSRF COOKIE
reset
ab -n1000 -c20 -C CSRF=pow http://127.0.0.1:20100/proxypass

echo "***************************************************************"
echo POST with CSRF mismatch
reset
ab -n1000 -c20 -C CSRF=pow -p $0 -T application/x-www-form-urlencoded http://127.0.0.1:20100/proxypass

echo "***************************************************************"
echo POST with CSRF cookie and header
reset
ab -n1000 -c10 -C CSRF=pow -H CSRF:pow -p $0 -T application/x-www-form-urlencoded http://127.0.0.1:20100/proxypass

echo "***************************************************************"
echo POST with CSRF cookie and POST parameter
reset
ab -n1000 -c10 -C CSRF=pow -H CSRF:pow -p performance_post_data.txt -T application/x-www-form-urlencoded http://127.0.0.1:20100/proxypass