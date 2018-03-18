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
docs new -i ${DOCUMENT_ID} -w ${WORK_DIR} -b ${BUILD_DIR}
```

成功すると **${WORK_DIR}** に下記のようなひな形が作成されます

{{<mermaid align="left">}}
graph LR;
    A[WORK_DIR] --> |MarkDown置き場| B
    A[WORK_DIR] --> |ビルド結果| C
    A[WORK_DIR] --> |その他省略| D
    B[content]
    C[public]
    D[other]
{{< /mermaid >}}

{{% notice info %}}
Docs Managerの `command/config` 以下に設定ファイルが作成されます。  
同時に .env ファイル の内容が、今作成した設定ファイルと同じものになっています。  
この .env ファイルの内容が、**カレントドキュメント(今指定されているDocument)** です。  
コマンドでドキュメントを指定しない場合は、この **カレントドキュメント** を自動で対象にします。  
複数の設定ファイルがある場合は **switchコマンド** によって **カレントドキュメント** を切り替えます。 
{{% /notice %}}

## 2. 早速コンテンツを配置してみましょう
下記の3ファイルを配置してみましょう  

- _index.md (Topページ)
- news/_index.md (/news/ ページ)
- news/page-1.md (/news/ コンテンツ1)

下記を1行ずつ実行します。  
**`docs post -p _index.md`**  
**`docs post -p news/_index.md`**  
**`docs post -p news/page-1.md`**  

{{% notice info %}}
**${WORK_DIR}** の **contentディレクトリ** に作成されます。
{{% /notice %}}

### 作成されたページに目印を追記してみてください
```bash
{{%/* notice note */%}}
Topページ
{{%/* /notice */%}}
```
```bash
{{%/* notice tip */%}}
NewsのTopページ
{{%/* /notice */%}}
```
```bash
{{%/* notice wraning */%}}
Newsコンテンツ1
{{%/* /notice */%}}
```

## 3. サーバー上でコンテンツを確認してみましょう

下記のコマンドで簡易的なWebサーバーを立ち上げて
```bash
docs preview
```
[http://localhost:1313](http://localhost:1313) にアクセスしましょう

```bash
PROJECT_ID=sample
docs preview $PROJECT_ID
```
表示できたでしょうか？  

{{% notice tip %}}
**_index.md** をさらに編集して、ファイルを保存してみてください。  
親切にも Auto Reload 機能が付いているので  
快適に編集できますね。
{{% /notice %}}

## 4. 静的サイトをビルドしましょう

```bash
docs build
```

成功すると **${BUILD_DIR}** にビルドされています。  
GitHubなら、これをpushして(ちょっと設定して)あげればドキュメントが公開できます。  
Dockerを利用すれば、ドキュメント用のWebサーバーを立ち上げることも  
簡単にできますが、、、その説明はまたいずれ。


## もっと知りたい人は
[HUGO]({{% ref "/tools/page-1.md" %}}) や [利用しているテーマ]({{% ref "/tools/page-2.md" %}}) についての情報をここにまとめていきます。  
みなさんも是非追記してくださいね！
