#!/bin/bash
set -e

ab -n1000 http://127.0.0.1:20100/proxypass

ab -n1000 -C CSRF=pow http://127.0.0.1:20100/proxypass

ab -n1000 -C CSRF=pow http://127.0.0.1:20100/proxypass_direct