#!/usr/bin/env bash
docker exec $1 /bin/bash -c "\
    kill \$(pidof "hugo")
    cd /usr/local/docs/$2 && \
    /usr/local/bin/hugo server -wv --bind="0.0.0.0"
"
