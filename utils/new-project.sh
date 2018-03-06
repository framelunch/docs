#!/usr/bin/env bash
docker exec $1 /bin/bash "/usr/bin/hugo new site $2 && ln -s $2/common-themes/docs $2/themes/docs"
