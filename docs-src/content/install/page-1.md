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

## 2. コマンドをインストール
Documentを扱う便利コマンドのシンボリックリンクを  
`/usr/local/bin/docs` に登録します。

```bash
DOCS_PATH=/path/to/docs/project
cd ${DOCS_PATH}
sh utils/install.sh



# TODO your path to docs project.
export DOCS_PATH=/path/to/docs/project
function docs(){
  cd $DOCS_PATH;
  source ./.env
  
  docker-compose up -d
  case $1 in
    init ) bash utils/initialize.sh -c $2 -i $3 -w $4 -b $5;;
    config ) bash utils/config.sh -c $2 -i $3 -w $4 -b $5;;
    config ) make configure id="$2" work_dir="$3" build_dir="$4";;
    switch ) make switch id="$2";;
    build ) make;;
    preview ) make preview;;
    new ) make project;;
    post ) make post post_path="$2";;
    reboot ) make reboot;;
    * ) echo "unexpected command.";;
  esac
}
```

設定後は `source ~/.bash_profile` をお忘れなく！

## 3. 「docker-compose.override.yml」を作りましょう
```bash
cd $DOCS_PATH
cp -f .docker-compose.override.sample.yml .docker-compose.override.yml
```
