#! /usr/bin/env sh 
export FLASK_APP=/zips/entry
cd /zips
# sleep 100000
exec flask run --host=0.0.0.0

