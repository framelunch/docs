+++
date = "2018-03-06T02:24:46Z"
title = "Install"
menuTitle = "Install"
weight = 10
+++

## 1. Docker for Macをインストールしましょう
最新のDockerが利用できる**Edge版** の  
[Docker for Mac](https://download.docker.com/mac/edge/Docker.dmg) をインストールしましょう  
*※ [Stable版](https://download.docker.com/mac/stable/Docker.dmg)が入っている人はそのままでいいです*

## 2. ソースファイルの取得
```bash
WORKSHOP_DIR=インストールするディレクトリパス
PROJECT_NAME=docs

cd ${WORKSHOP_DIR}
git clone git@github.com:framelunch/docs.git ./${PROJECT_NAME}
cd ${PROJECT_NAME}
```

{{% notice warning %}}
**WORKSHOP_DIR** は**絶対パス**で指定してください  
&nbsp;  
カレントディレクトリの絶対パスは `pwd` で取得できます  
だから、取得したいところに `cd` で移動して  
`WORKSHOP_DIR=$(pwd)` ってやるのが良さそう  
&nbsp;  
`echo ${WORKSHOP_DIR}`  で変数の中身が確認できます
{{% /notice %}}

## 3. コマンドをインストール
docsコマンドを利用できるようにします
```bash
make
```
{{% notice tip %}}
アンインストールは `make uninstall` です  
インストール時に `/usr/local/bin/docs` にコマンドのシンボリックリンクを作成しているので  
それを削除しているだけです。
{{% /notice %}} 

## 4. 試しにコマンドのUsageを表示してみましょう
```bash
docs
```

下記のような説明が表示されるはずです。

```bash
HOW TO USE ...

    Usage:
        docs [Command] [Command Arguments]
        ※ [Command Arguments]の先頭に ! が付いているものは必須パラメータです

    Command:
        ##### 設定を行う #####
        # Current Documentの切り替え
        switch -i [! Document ID]

        # Document設定の削除
        remove -i [! Document ID]

        ##### ドキュメントを作る #####
        # 新しいドキュメントを作る
        new -i [! Document ID] -w [! Document work directory(Mark Downを置くディレクトリ)] -b [! Document build directory(Web Rootディレクトリ)]

        # 既存のローカルにあるドキュメントを追加する
        add -i [! Document ID] -w [! Document work directory(Mark Downを置くディレクトリ)] -b [! Document build directory(Web Rootディレクトリ)]

        # new, add コマンドで指定した設定の更新
        configure -i [! Document ID] -w [Document work directory(Mark Downを置くディレクトリ)] -b [Document build directory(Web Rootディレクトリ)]

        # ドキュメントに新しいページを追加する
        post -p [! ページのファイルパス (例: _index.md, /news/_index.md, /news/page-1.md)]

        ##### ドキュメントを見る #####
        preview -i [Document ID]

        ##### ドキュメントを出力する #####
        build -i [Document ID]

        ##### その他 #####
        # Docs の Dockerを再起動します
        reboot -f [付けると強制的にダウンしてから再起動]
```
