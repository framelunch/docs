#!/usr/bin/env bash
docker exec $1 /bin/bash -c "\
    cd /usr/local/docs/$2/content && \
    FOUND=\$(find . -type f -name *.md) && \
    for f in \$FOUND ; do echo "" >> \$f; sed -i '\$d' \$f; done
"
