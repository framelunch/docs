+++
date = "2018-03-06T02:24:46Z"
title = "Install"
menuTitle = "Install"
weight = 10
+++

## 1. ソースファイルの取得 page-1
```bash
WORKSPACE_DIR=インストールするディレクトリ
PROJECT_NAME=docs
cd $WORKSPACE_DIR

git clone git@github.com:framelunch/docs.git ./$PROJECT_NAME
```

## 2. 設定ファイル
このままソースファイルを編集すると  
あなたの修正を Scaffold-WPにcommitすることになってしまうので  
あなたのプロジェクトとソースファイルを関連づけましょう。

```bash
PROJECT_NAME=sample
REPOSITORY_URL=https://github.com/XXXX/XXXXXXX.git
cd ./$PROJECT_NAME

git remote remove origin
git remote add origin $REPOSITORY_URL
```
