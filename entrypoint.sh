#! /usr/bin/env sh 
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LS_SERVICE_NAME=$LIGHTSTEP_SERVICE
export LS_ACCESS_TOKEN=$LIGHTSTEP_TOKEN
export FLASK_APP=/zips/entry
export OTEL_LOG_LEVEL=debug 
exec opentelemetry-instrument python3 /zips/entry.py

