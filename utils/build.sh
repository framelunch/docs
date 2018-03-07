#!/usr/bin/env bash
docker exec $1 /bin/bash -c "\
    cd /usr/local/docs/$2 && \
    /usr/local/bin/hugo
"
