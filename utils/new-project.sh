#!/usr/bin/env bash
docker exec $1 /bin/bash -c "\
    cd /usr/local/docs && \
    /usr/local/bin/hugo new site $2 && \
    ln -s /usr/local/docs/common-themes/default $2/themes/default && \
    cp -f default-config.toml $2/config.toml 
"
