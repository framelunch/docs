+++
date = "2018-03-06T02:24:46Z"
title = "ENV Configure"
menuTitle = "ENV Configure"
weight = 20
+++

## 環境設定ファイル「.env」の作成
## 1. 「.env.sample」をコピーしましょう
```bash
PROJECT_DIR=あなたのプロジェクトディレクトリ
cd $PROJECT_DIR

cp -f .env.sample .env
```

> 環境設定ファイルでは、Webサーバーの利用する **PORTの変更** や  
> **DBの設定** 等を変更できますが、特に理由がなければ変更しなくて良いでしょう。  
> 次のページに進んでOKです。

**[環境設定ファイルの詳細な設定はこちら](/reference/page-1/)**
