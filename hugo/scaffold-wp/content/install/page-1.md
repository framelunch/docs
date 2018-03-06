+++
date = "2018-03-06T02:24:46Z"
title = "Install"
menuTitle = "Install"
weight = 10
+++

## 1. Gitプロジェクトの作成
GitHub や GitLab でプロジェクトを作成してください  
*※そのリポジトリURLをコピーしておくこと*

## 2. ソースファイルの取得
```bash
WORKSPACE_DIR=あなたのプロジェクトを作成するディレクトリ
PROJECT_NAME=sample
cd $WORKSPACE_DIR

git clone https://github.com/framelunch/scaffold-wordpress.git ./$PROJECT_NAME
```

## 3. リモートリポジトリの切り替え
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
