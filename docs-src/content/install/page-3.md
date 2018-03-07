+++
date = "2018-03-06T02:24:46Z"
title = "Docsの作成"
menuTitle = "Docsの作成"
weight = 30
+++

実際にソースファイルを作成していきます。

--- 

## 1. ソースファイルのひな形を生成します

```bash
PROJECT_ID=sample
docs new $PROJECT_ID
```

成功すると[先ほど]({{% ref "/install/page-2.md#2-markdownファイル等を配置する場所を指定しましょう" %}})指定したソースファイル置き場にファイルが作成されています。

{{<mermaid align="left">}}
graph LR;
    A[sample project] --> |MarkDown置き場| B
    A[sample project] --> |静的サイトWebRoot| C
    A[sample project] --> |その他省略| D
    B[content]
    C[public]
    D[other]
{{< /mermaid >}}

## 2. 早速コンテンツを配置してみましょう
指定したソースファイル置き場の「**content**」ディレクトリに  
ファイル「**_index.md**」を作成し、下記をコピペしてください。

```markdown
+++
date = "2018-03-06T02:24:46Z"
title = "Top"
+++

{{%/* notice tip */%}}
**HELLO WORLD !!!**
{{%/* /notice */%}}

```

{{% notice note %}}
静的サイトのコンテンツ(Mark Downファイル)は  
全てこの「**content**」ディレクトリに配置します
{{% /notice %}}

## 3. サーバー上で確認しながらコンテンツを充実させましょう

下記のコマンドで簡易的なWebサーバーを立ち上げて  
[http://localhost:1313](http://localhost:1313) にアクセスしましょう

```bash
PROJECT_ID=sample
docs preview $PROJECT_ID
```
HELLO WORLD できたでしょうか？  

{{% notice info %}}
**_index.md** をさらに編集して、ファイルを保存してみてください。  
親切にも Auto Reload 機能が付いているので  
快適に編集できますね。
{{% /notice %}}

## 4. 静的サイトをビルドしましょう

```bash
PROJECT_ID=sample
docs build $PROJECT_ID
```

成功すると[先ほど]({{% ref "/install/page-2.md#3-静的サイトのビルド先を指定しましょう" %}})指定したWebRootにビルドされているはずです。


## もっと知りたい人は
[HUGO]({{% ref "/tools/page-1.md" %}}) や [利用しているテーマ]({{% ref "/tools/page-2.md" %}}) についての情報をここにまとめていきます。  
みなさんも是非追記してくださいね！
