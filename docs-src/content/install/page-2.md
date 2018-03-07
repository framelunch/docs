+++
date = "2018-03-06T02:24:46Z"
title = "Docsを配置する準備"
menuTitle = "Docsを配置する準備"
weight = 20
+++

早速、サンプルプロジェクトのドキュメントを作成する流れを説明します。  
まずは「どこにドキュメントを配置するのか」を設定しましょう。

--- 

## 1. プロジェクトのIDを決めましょう
今回のプロジェクトIDは「 **sample** 」とします  
(どこかに sample というプロジェクトディレクトリを作っておいてください)

## 2. MarkDownファイル等を配置する場所を指定しましょう
記述するファイルは、[先ほど]({{% ref "/install/page-1.md#3-docker-compose-override-yml-を作りましょう" %}})コピーした
**docker-compose.override.yml** ファイルです。  

このファイルの最下部に例に倣って追記します。  
こんな感じです。

```yaml
      - ../your/sample/project/docs-src:/usr/local/docs/sample
```

{{% notice note %}}
「**:**」で区切って、  
左辺は **Host(Mac)のMarkDownファイル等を配置するパス**  
右辺は 「**/usr/local/docs/プロジェクトID**」
{{% /notice %}}



## 3. 静的サイトのビルド先を指定しましょう
公開されるドキュメントのWebRootをビルド先を指定します。   

```yaml
      - type: bind
        source: ../your/sample/project/docs
        target: /usr/local/docs/sample/public
```

{{% notice note %}}
**source**: **静的サイトのWeb Rootパス**  
**target**: **/usr/local/docs/プロジェクトID/public**
{{% /notice %}}

## 編集したソースの全体図
```yaml
version: "3.5"

services:

  docs:
    volumes:
      # --- ビルド先と作業ディレクトリを指定していく(自分の環境に合わせる) ---
      # docs
      - ./docs-src:/usr/local/docs/docs
      - type: bind
        source: ./docs
        target: /usr/local/docs/docs/public
      
      # ======= 以降 追記した部分です =======
      # sample
      - ../your/sample/project/docs-src:/usr/local/docs/sample
      - type: bind
        source: ../your/sample/project/docs
        target: /usr/local/docs/sample/public
```
