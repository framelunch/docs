+++
date = "2018-03-06T02:24:46Z"
title = "Docsを配置する準備"
menuTitle = "Docsを配置する準備"
weight = 20
+++

早速、サンプルプロジェクトのドキュメントを作成する流れを説明します。  
まずは「どこにドキュメントを配置するのか」を決めましょう。

--- 

## 1. DocumentのIDを決めましょう
今回は、Document IDを「 **sample** 」とします  
一緒に作成しましょう。
```bash
cd ${WORKSHOP_DIR}

DOCUMENT_ID=sample
SAMPLE_PROJECT_DIR=${WORKSHOP_DIR}/${DOCUMENT_ID}

mkdir -p ${SAMPLE_PROJECT_DIR}
```

## 2. MarkDownファイル等を配置する場所を決めましょう
今回は「 **${SAMPLE_PROJECT_DIR}/docs-src** 」とします  
```bash
WORK_DIR=${SAMPLE_PROJECT_DIR}/docs-src
```

## 3. Documentのビルド先を指定しましょう
今回は「 **${SAMPLE_PROJECT_DIR}/docs** 」とします  
```bash
BUILD_DIR=${SAMPLE_PROJECT_DIR}/docs
```

## 4. 意図した設定になっているか確認しましょう
```bash
cat <<- EOF
SAMPLE_PROJECT_DIR:    
    ${SAMPLE_PROJECT_DIR}
DOCUMENT_ID:    
    ${DOCUMENT_ID}
WORK_DIR:    
    ${WORK_DIR}
BUILD_DIR:    
    ${BUILD_DIR}
EOF
```