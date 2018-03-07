+++
date = "2018-03-06T02:24:46Z"
title = "Getting Started"
+++

# 目次
## [インストール]({{% ref "/install/page-1.md" %}})

```bash
# your path to docs project.
export DOCS_PATH=/path/to/docs
function docs(){
  cd $DOCS_PATH;
  source ./.env
  
  docker-compose up -d
  case $1 in
    build ) make id=$2;;
    preview ) make preview id=$2;;
    new ) make project id=$2;;
    upd ) make update id=$2;;
  esac
}
```





