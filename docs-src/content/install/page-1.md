+++
date = "2018-03-06T02:24:46Z"
title = "Install"
menuTitle = "Install"
weight = 10
+++

## 1. ソースファイルの取得
```bash
WORKSPACE_DIR=インストールするディレクトリ
PROJECT_NAME=docs
cd $WORKSPACE_DIR

git clone git@github.com:framelunch/docs.git ./$PROJECT_NAME
```

## 2. 便利メソッドを登録
下記の関数をあなたの「**~/.bash_profile**」に追記してください。  
Makefileに登録されている便利関数を、どこにいても利用できるようになります。  
(以降の説明は下記を追記している前提で進みます)

```bash
# TODO your path to docs project.
export DOCS_PATH=/path/to/docs/project
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

設定後は `source ~/.bash_profile` をお忘れなく！

## 3. 「docker-compose.override.yml」を作りましょう
```bash
cd $DOCS_PATH
cp -f .docker-compose.override.sample.yml .docker-compose.override.yml
```
