#!/usr/bin/env bash

#################
# Global Define #
#################
# シンボリックリンク元ファイル
LINK_INSTANCE=$(readlink $0)
# command ディレクトリ
CURRENT_DIR=$(dirname ${LINK_INSTANCE})
# command/config ディレクトリ
CONFIG_DIR=${CURRENT_DIR}/config
# docs ディレクトリ
DOCS_PROJECT_DIR=$(dirname ${CURRENT_DIR})
# Env ファイル
CURRENT_CONFIG=${DOCS_PROJECT_DIR}/.env
# コマンド名
CMD_NAME=$(basename $0)
# compose.override.sampleパス
COMPOSE_OVERRIDE_SAMPLE=${CURRENT_DIR}/docker-compose.override.sample.yml
# compose.overrideパス

# コンテナ名
CONTAINER_NAME=docs
# コンテナ内ワークディレクトリ
CONTAINER_WORK_DIR=/usr/local/docs
# コンテナ内 HUGO コマンドパス
CMD_HUGO=/usr/local/bin/hugo

# デバッグ
ERR_LOG=${CURRENT_DIR}/error.log

# 終了ステータス
EXIT_NORMAL=0
EXIT_NO_EXIST_ENV=1
EXIT_NO_EXIST_SUBCOMMAND=2
EXIT_INVALID_ARGUMENT=3
EXIT_NOT_ENOUGH_ARGUMENT=4
EXIT_LOGIC_EXCEPTION=5

###################
# Utils Functions #
###################
function usage()
{
    cat <<- EOF
    
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
        
EOF
}

# -------------
#  基本
# -------------
# 半角英数字 or アンダーバー
function isCorrectProjectId()
{
    if [[ ${1} =~ ^[a-zA-Z0-9_]*$ ]]; then
        echo "true"
    else
        echo "false"        
    fi
}

# 半角英数字 or アンダーバー or スラッシュ or .
function isCorrectAbsoluteFilePath()
{
    if [[ ${1} =~ ^[a-zA-Z0-9_/\.\-]*$ ]]; then
        echo "true"
    else
        echo "false"        
    fi
}

# 半角英数字 or アンダーバー or スラッシュ
function isCorrectAbsolutePath()
{
    if [[ ${1} =~ ^[a-zA-Z0-9_/-]*$ ]]; then
        echo "true"
    else
        echo "false"        
    fi
}

# ファイル存在チェック
function isFile()
{
    if [ -f ${1} ]; then
        echo "true"
    else
        echo "false"        
    fi
}

# ディレクトリ存在チェック
function isDir()
{
    if [ -d ${1} ]; then
        echo "true"
    else
        echo "false"        
    fi
}

# ログ
function logging()
{
    echo $1 1>>${ERR_LOG}
}

# -------------
#  コンテナ系
# -------------
# コンテナ内のディレクトリ存在チェック
function isDirOnContainer()
{
    bootDockerIfNotAlive
    docker exec -i ${CONTAINER_NAME} bash -c "[ -d ${1} ] && echo 'true' || echo 'false'"
}

# コンテナ内のディレクトリ存在チェック
function rmContainerDir()
{
    bootDockerIfNotAlive
    docker exec -i ${CONTAINER_NAME} bash -c "rm -fr ${1}"
}

# コンテナの死活チェック
function isAliveContainer()
{
    # docsコンテナが起動していなければ立ち上げる
    IS_ALIVE=$(docker inspect -f '{{.State.Running}}' ${CONTAINER_NAME})
    if [ ${IS_ALIVE} != "true" ]; then
        echo "true"
    else
        echo "false"        
    fi 
}

# コンテナの起動
function bootDockerIfNotAlive()
{
    if [ $(isAliveContainer) = "true" ]; then
        echo "Boot Docs Container..."
        docker-compose up -d    
    fi
}

# コンテナの再起動
function reboot()
{
    local FLG_FORCE="false"
    while getopts f OPT
    do
        case ${OPT} in
            "f" ) FLG_FORCE="true" ; ;;
              * ) usage
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    if [ ${FLG_FORCE} = "true" ]; then
        docker-compose stop; docker-compose rm -f; docker-compose up -d;
    else
        docker-compose up -d
    fi
}

# -------------
#  コンフィグ系
# -------------
# コンフィグファイルパスの取得
function getConfigPath()
{
    echo "${CONFIG_DIR}/${1}.env"
}

# コンフィグファイルの存在チェック
function isExistConfig()
{
    local CONFIG_PATH=$(getConfigPath "${1}")
    if [ $(isFile "${CONFIG_PATH}") = "true" ]; then
        echo "true"
    else
        echo "false"        
    fi    
}

# コンフィグファイルの作成
function createConfig()
{
    local CONFIG_PATH=$(getConfigPath "${1}")
    local _PROJECT_ID=${1}
    local _WORK_DIR=${2}
    local _BUILD_DIR=${3}
    
    cat << EOF > ${CONFIG_PATH}
CONTAINER_NAME=docs
PREVIEW_SERVER_PORT=1313
CONTAINER_WORK_DIR=${CONTAINER_WORK_DIR}
CURRENT_PROJECT_ID=${_PROJECT_ID}
CURRENT_WORK_DIR=${_WORK_DIR}
CURRENT_BUILD_DIR=${_BUILD_DIR}
EOF
}

# カレントコンフィグファイルの切り替え
function switchCurrentConfig()
{
    local CONFIG_PATH=$(getConfigPath "${1}")
    cp -f ${CONFIG_PATH} ${CURRENT_CONFIG}
}

##################
# subcommand add #
##################
function add()
{
    echo "Command [ add ] "

    # --- パラメータチェック ---
    local FLG_ID="false"
    local FLG_WORK_DIR="false"
    local FLG_BUILD_DIR="false"
    while getopts fi:w:b: OPT
    do
        case ${OPT} in
            "i" ) FLG_ID="true" ; PROJECT_ID="$OPTARG" ;;
            "w" ) FLG_WORK_DIR="true" ; WORK_DIR="$OPTARG" ;;
            "b" ) FLG_BUILD_DIR="true" ; BUILD_DIR="$OPTARG" ;;
              * ) usage
                  echo "ERR: ${OPT} は受け付けられません"
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    # --- 必須パラメータの存在チェック ---
    if [ ${FLG_ID} = "false" ]; then
        usage
        echo "ERR: 引数 -i は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi

    if [ ${FLG_WORK_DIR} = "false" ]; then
        usage
        echo "ERR: 引数 -w は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi

    if [ ${FLG_BUILD_DIR} = "false" ]; then
        usage
        echo "ERR: 引数 -b は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi

    # --- 設定ファイル読み込み ---
    # 今回はなし

    # --- 任意パラメータの初期値入力 ---
    # 今回はなし
    
    # --- パラメータの表示 ---
    cat <<- EOF
Params:    
    PROJECT_ID: ${PROJECT_ID}
    WORK_DIR: ${WORK_DIR}
    BUILD_DIR: ${BUILD_DIR}
EOF
    # --- パラメータの正当性チェック ---
    # PROJECT_ID: 名称チェック(0-9a-z A-Z _)
    if [ $(isCorrectProjectId "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i  半角英数字とアンダーバーのみ"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # WORK_DIR: 名称チェック(0-9a-zA-Z _ / -)
    if [ $(isCorrectAbsolutePath "${WORK_DIR}") = "false" ]; then
        echo "ERR: -w 半角英数字とアンダーバー,スラッシュ,ハイフンのみ。絶対パスで指定。"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # BUILD_DIR: 名称チェック(0-9a-zA-Z _ / -)
    if [ $(isCorrectAbsolutePath "${BUILD_DIR}") = "false" ]; then
        echo "ERR: -b 半角英数字とアンダーバー,スラッシュ,ハイフンのみ。絶対パスで指定。"
        exit ${EXIT_INVALID_ARGUMENT}
    fi

    # --- Logic ---
    # WORK_DIR: 存在しないのなら作成する
    if [ $(isDir "${WORK_DIR}") = "false" ]; then
        mkdir -p ${WORK_DIR}
        cat <<- EOF
Message:    
    Make work directory => ${WORK_DIR}
EOF
    fi
    
    # BUILD_DIR: 存在しないのなら作成する
    if [ $(isDir "${BUILD_DIR}") = "false" ]; then
        mkdir -p ${BUILD_DIR}
        cat <<- EOF
Message:    
    Make build directory => ${BUILD_DIR}
EOF
    fi

    # 設定ファイルを作成する
    createConfig ${PROJECT_ID} ${WORK_DIR} ${BUILD_DIR}
    
    # カレントコンフィグのバックアップ
    BKUP_CURRENT_CONFIG="${CURRENT_CONFIG}.old"
    if [ $(isFile ${CURRENT_CONFIG}) = "true" ]; then
        cp -f ${CURRENT_CONFIG} ${BKUP_CURRENT_CONFIG};
    fi

    # カレントコンフィグファイルを置き換える
    switchCurrentConfig ${PROJECT_ID}
    source ${CURRENT_CONFIG}

    # Dockerコンテナの再起動
    reboot
    local REBOOT_RESULT=$?
    # PROJECT_ID: プロジェクトがDockerコンテナに既に作られていたらエラー
    if [ ${REBOOT_RESULT} -ne ${EXIT_NORMAL} ]; then
        echo "ERR: reboot失敗"
        
        # バックアップを取っていたコンフィグを元に戻す
        cp -f ${BKUP_CURRENT_CONFIG} ${CURRENT_CONFIG};
        rm ${BKUP_CURRENT_CONFIG}
        source ${CURRENT_CONFIG}
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # バックアップファイルを削除
    if [ $(isFile ${BKUP_CURRENT_CONFIG}) = "true" ]; then
        rm ${BKUP_CURRENT_CONFIG}
    fi
}

##################
# subcommand new #
##################
function new()
{
    echo "Command [ new ] "

    # --- パラメータチェック ---
    local FLG_ID="false"
    local FLG_WORK_DIR="false"
    local FLG_BUILD_DIR="false"
    local FLG_FORCE="false"
    while getopts fi:w:b: OPT
    do
        case ${OPT} in
            "i" ) FLG_ID="true" ; PROJECT_ID="$OPTARG" ;;
            "w" ) FLG_WORK_DIR="true" ; WORK_DIR="$OPTARG" ;;
            "b" ) FLG_BUILD_DIR="true" ; BUILD_DIR="$OPTARG" ;;
            "f" ) FLG_FORCE="true" ;;
              * ) usage
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    # --- 必須パラメータの存在チェック ---
    if [ ${FLG_ID} = "false" ]; then
        usage
        echo "ERR: 引数 -i は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi

    if [ ${FLG_WORK_DIR} = "false" ]; then
        usage
        echo "ERR: 引数 -w は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi

    if [ ${FLG_BUILD_DIR} = "false" ]; then
        usage
        echo "ERR: 引数 -b は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi

    # --- 設定ファイル読み込み ---
    # 今回はなし

    # --- 任意パラメータの初期値入力 ---
    # 今回はなし
    
    # --- パラメータの表示 ---
    cat <<- EOF
Params:    
    PROJECT_ID: ${PROJECT_ID}
    WORK_DIR: ${WORK_DIR}
    BUILD_DIR: ${BUILD_DIR}
    FLG_FORCE: ${FLG_FORCE}
EOF
    # --- パラメータの正当性チェック ---
    # PROJECT_ID: 名称チェック(0-9a-z A-Z _)
    if [ $(isCorrectProjectId "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i  半角英数字とアンダーバーのみ"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # PROJECT_ID: 設定ファイルが既に作られていたらエラー
    if [ ${FLG_FORCE} = "false" -a $(isExistConfig "${PROJECT_ID}") = "true" ]; then
        echo "ERR: -i  設定 ${PROJECT_ID} は既に存在します。"
        echo "次のコマンドで削除できます"
        echo "docs remove -i ${PROJECT_ID}"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # WORK_DIR: 名称チェック(0-9a-zA-Z _ / -)
    if [ $(isCorrectAbsolutePath "${WORK_DIR}") = "false" ]; then
        echo "ERR: -w 半角英数字とアンダーバー,スラッシュ,ハイフンのみ。絶対パスで指定。"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # BUILD_DIR: 名称チェック(0-9a-zA-Z _ / -)
    if [ $(isCorrectAbsolutePath "${BUILD_DIR}") = "false" ]; then
        echo "ERR: -b 半角英数字とアンダーバー,スラッシュ,ハイフンのみ。絶対パスで指定。"
        exit ${EXIT_INVALID_ARGUMENT}
    fi

    # --- Logic ---
    # WORK_DIR: 存在しないのなら作成する
    if [ $(isDir "${WORK_DIR}") = "false" ]; then
        mkdir -p ${WORK_DIR}
        cat <<- EOF
Message:    
    Make work directory => ${WORK_DIR}
EOF
    fi
    
    # BUILD_DIR: 存在しないのなら作成する
    if [ $(isDir "${BUILD_DIR}") = "false" ]; then
        mkdir -p ${BUILD_DIR}
        cat <<- EOF
Message:    
    Make build directory => ${BUILD_DIR}
EOF
    fi

    # 設定ファイルを作成する
    createConfig ${PROJECT_ID} ${WORK_DIR} ${BUILD_DIR}
    
    # カレントコンフィグのバックアップ
    BKUP_CURRENT_CONFIG="${CURRENT_CONFIG}.old"
    if [ $(isFile ${CURRENT_CONFIG}) = "true" ]; then
        cp -f ${CURRENT_CONFIG} ${BKUP_CURRENT_CONFIG};
    fi

    # カレントコンフィグファイルを置き換える
    switchCurrentConfig ${PROJECT_ID}
    source ${CURRENT_CONFIG}

    # Dockerコンテナの再起動
    reboot

    # PROJECT_ID: プロジェクトがDockerコンテナに既に作られていたらエラー
    if [ ${FLG_FORCE} = "false" -a $(isDirOnContainer "${CONTAINER_WORK_DIR}/${PROJECT_ID}") = "true" ]; then
        echo "ERR: -i  プロジェクト ${PROJECT_ID} は既に存在します。"
        echo "次のコマンドで既存のプロジェクトを上書きできます。"
        echo "docs new -f -i ${PROJECT_ID}"
        
        # バックアップを取っていたコンフィグを元に戻す
        cp -f ${BKUP_CURRENT_CONFIG} ${CURRENT_CONFIG};
        rm ${BKUP_CURRENT_CONFIG}
        source ${CURRENT_CONFIG}
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # HUGOプロジェクトを作成する
    local HUGO_COMMAND="${CMD_HUGO} new site ${PROJECT_ID}"
    if [ ${FLG_FORCE} = "true" ]; then
        HUGO_COMMAND="${HUGO_COMMAND} --force"
        rmContainerDir ${PROJECT_ID}
    fi
    local COMMAND="cd ${CONTAINER_WORK_DIR} && \
    ${HUGO_COMMAND} && \
    ln -s ${CONTAINER_WORK_DIR}/common-themes/default ${PROJECT_ID}/themes/default && \
    cp -f default-config.toml ${PROJECT_ID}/config.toml"
    cat <<- EOF
Main Command:
    ${COMMAND}
EOF
    docker exec -i ${CONTAINER_NAME} bash -c "${COMMAND}"
    
    # バックアップファイルを削除
    if [ $(isFile ${BKUP_CURRENT_CONFIG}) = "true" ]; then
        rm ${BKUP_CURRENT_CONFIG}
    fi
}

###################
# subcommand post #
###################
function post()
{
    echo "Command [ post ] "

    # --- パラメータチェック ---
    local FLG_ID="false"
    local FLG_POST="false"
    while getopts i:p: OPT
    do
        case ${OPT} in
            "i" ) FLG_ID="true" ; PROJECT_ID="$OPTARG" ;;
            "p" ) FLG_POST="true" ; POST="$OPTARG" ;;
              * ) usage
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    # --- 必須パラメータの存在チェック ---
    if [ ${FLG_POST} = "false" ]; then
        usage
        echo "ERR: 引数 -p は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi
    
    # --- 設定の読み込み ---
    if [ ${FLG_ID} = "true" -a $(isExistConfig "${PROJECT_ID}") = "true" ]; then
        # 指定の設定ファイルがあれば読み込む
        source $(getConfigPath ${PROJECT_ID})
    elif [ $(isFile ${CURRENT_CONFIG}) = "true" ]; then
        # .envがあれば読み込む        
        source ${CURRENT_CONFIG}
    else
        # 読み込む設定ファイルがなければエラー
        echo "ERR: -i カレントドキュメントが指定されていない場合は必須です"
        echo "先に switch コマンドでカレントドキュメントを指定してもOKです"
        echo "docs switch -i [Document ID]"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi
    
    # もしも .envが存在しなかったら作成しておく
    if [ $(isFile ${CURRENT_CONFIG}) = "false" ]; then
        switchCurrentConfig ${PROJECT_ID}
    fi
    
    # --- 任意パラメータの初期値入力 ---
    if [ ${FLG_ID} = "false" ]; then
        PROJECT_ID=${CURRENT_PROJECT_ID}
    fi
    
    if [ ${PROJECT_ID} != ${CURRENT_PROJECT_ID} ]; then
        echo "ERR: -i 設定ファイルの値が不正です。"
        echo "下記ファイルの設定値が正しいか確認してください。"
        echo $(getConfigPath ${PROJECT_ID})
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    # --- パラメータの表示 ---
    cat <<- EOF
Params:    
    PROJECT_ID: ${PROJECT_ID}
    POST: ${POST}
EOF
    
    # --- パラメータの正当性チェック ---
    # PROJECT_ID: 名称チェック(0-9a-z A-Z _)
    if [ $(isCorrectProjectId "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i  半角英数字とアンダーバーのみ"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # PROJECT_ID: プロジェクトがDockerコンテナに存在しなかったらエラー
    if [ $(isDirOnContainer "${CONTAINER_WORK_DIR}/${PROJECT_ID}/content") = "false" ]; then
        echo "ERR: -i  プロジェクト ${PROJECT_ID} がDockerコンテナ内に存在しません。"
        echo "new コマンドでプロジェクトを作成してください"
        echo "docs new -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'"
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    # POST: 名称チェック(0-9a-zA-Z _ / - .)
    if [ $(isCorrectAbsoluteFilePath "${POST}") = "false" ]; then
        echo "ERR: -p 半角英数字とアンダーバー,スラッシュ,ハイフン,ドットのみ。"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # --- Logic ---
    # ページの追加
    local COMMAND="cd ${CONTAINER_WORK_DIR}/${PROJECT_ID} && \
    ${CMD_HUGO} new ${POST}"
    cat <<- EOF
Main Command:
    ${COMMAND}
EOF
    docker exec -i ${CONTAINER_NAME} bash -c "${COMMAND}"
}

########################
# subcommand configure #
########################
function configure()
{
    echo "Command [ configure ] "

    # --- パラメータチェック ---
    local FLG_ID="false"
    local FLG_WORK_DIR="false"
    local FLG_BUILD_DIR="false"
    while getopts i:w:b: OPT
    do
        case ${OPT} in
            "i" ) FLG_ID="true" ; PROJECT_ID="$OPTARG" ;;
            "w" ) FLG_WORK_DIR="true" ; WORK_DIR="$OPTARG" ;;
            "b" ) FLG_BUILD_DIR="true" ; BUILD_DIR="$OPTARG" ;;
              * ) usage
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    # --- 必須パラメータの存在チェック ---
    if [ ${FLG_ID} = "false" ]; then
        usage
        echo "ERR: 引数 -i は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi
    
    if [ $(isFile ${CURRENT_CONFIG}) = "false" ]; then
        echo "ERR: 先に new コマンドでプロジェクトを作成するか、 switch コマンドでプロジェクトを指定してください"
        echo "docs new -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'"
        echo "docs switch -i ${PROJECT_ID}"
    fi

    # --- 設定ファイル読み込み ---
    if [ $(isExistConfig "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i このProjectIDの設定ファイルは存在しません"
        echo "設定ファイルを作成するには下記のコマンドを利用してください"
        echo "docs new -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    source $(getConfigPath ${PROJECT_ID})
    
    # 既存の設定を保持
    OLD_WORK_DIR=${CURRENT_WORK_DIR}
    OLD_BUILD_DIR=${CURRENT_BUILD_DIR}

    # --- 任意パラメータの初期値入力 ---
    if [ ${PROJECT_ID} != ${CURRENT_PROJECT_ID} ]; then
        echo "ERR: -i 設定ファイルの値が不正です。"
        echo "下記ファイルの設定値が正しいか確認してください。"
        echo $(getConfigPath ${PROJECT_ID})
        echo "新しくプロジェクトを作成する場合は下記コマンドを利用してください。"
        echo "docs new -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'"
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    if [ ${FLG_WORK_DIR} = "false" ]; then
        WORK_DIR=${CURRENT_WORK_DIR}
    fi

    if [ ${FLG_BUILD_DIR} = "false" ]; then
        BUILD_DIR=${CURRENT_BUILD_DIR}
    fi
    
    # --- パラメータの表示 ---
    cat <<- EOF
Params:    
    PROJECT_ID: ${PROJECT_ID}
    WORK_DIR: ${WORK_DIR}
    BUILD_DIR: ${BUILD_DIR}
EOF
    
    # --- パラメータの正当性チェック ---
    # PROJECT_ID: 名称チェック(0-9a-z A-Z _)
    if [ $(isCorrectProjectId "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i  半角英数字とアンダーバーのみ"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # PROJECT_ID: プロジェクトがDockerコンテナに存在しなかったら追加を試みる
    if [ $(isDirOnContainer "${CONTAINER_WORK_DIR}/${PROJECT_ID}/content") = "false" ]; then
        echo "WARN: -i  プロジェクト ${PROJECT_ID} がDockerコンテナ内に存在しません。"
        cat <<- EOF
Message:    
    プロジェクトの追加を試みます...
EOF
        docs add -i ${PROJECT_ID} -w ${WORK_DIR} -b ${BUILD_DIR}
        NEW_EXIT=$?
        if [ ${NEW_EXIT} -eq ${EXIT_NORMAL} ]; then
            cat <<- EOF
Message:    
    追加に成功しました!!!
EOF
            exit ${EXIT_NORMAL}
        else
            cat <<- EOF
Message:    
    追加中にエラー発生
    下記のコマンドから改めてプロジェクトを生成 or 追加してください
    docs new -f -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'
    docs add -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'
EOF
            exit ${NEW_EXIT}
        fi
    fi
    
    # WORK_DIR: 名称チェック(0-9a-zA-Z _ / -)
    if [ $(isCorrectAbsolutePath "${WORK_DIR}") = "false" ]; then
        echo "ERR: -w 半角英数字とアンダーバー,スラッシュ,ハイフンのみ。絶対パスで指定。"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # BUILD_DIR: 名称チェック(0-9a-zA-Z _ / -)
    if [ $(isCorrectAbsolutePath "${BUILD_DIR}") = "false" ]; then
        echo "ERR: -b 半角英数字とアンダーバー,スラッシュ,ハイフンのみ。絶対パスで指定。"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
        
    # --- Logic ---
    # WORK_DIR: 存在しないのなら作成する
    if [ $(isDir "${WORK_DIR}") = "false" ]; then
        mkdir -p ${WORK_DIR}
        cat <<- EOF
Message:    
    Make work directory => ${WORK_DIR}
EOF
    fi
    
    # BUILD_DIR: 存在しないのなら作成する
    if [ $(isDir "${BUILD_DIR}") = "false" ]; then
        mkdir -p ${BUILD_DIR}
        cat <<- EOF
Message:    
    Make build directory => ${BUILD_DIR}
EOF
    fi
    
    # 設定ファイルを作成する
    createConfig ${PROJECT_ID} ${WORK_DIR} ${BUILD_DIR}
    
    # カレントコンフィグのバックアップ
    BKUP_CURRENT_CONFIG="${CURRENT_CONFIG}.old"
    if [ $(isFile ${CURRENT_CONFIG}) = "true" ]; then
        cp -f ${CURRENT_CONFIG} ${BKUP_CURRENT_CONFIG};
    fi
    
    # カレントコンフィグファイルを置き換える
    switchCurrentConfig ${PROJECT_ID}
    source ${CURRENT_CONFIG}

    # Dockerコンテナの再起動
    reboot
    REBOOT_RESULT=$?
    
    # バックアップファイルを削除
    if [ ${REBOOT_RESULT} -eq ${EXIT_NORMAL} -a $(isFile ${BKUP_CURRENT_CONFIG}) = "true" ]; then
        rm ${BKUP_CURRENT_CONFIG}
        
        # 以前の設定ディレクトリを今回のディレクトリに置き換える
        cp -a ${OLD_WORK_DIR}/. ${CURRENT_WORK_DIR}
        cp -a ${OLD_BUILD_DIR}/. ${CURRENT_BUILD_DIR}
        echo "Done."        
    fi
}

#####################
# subcommand switch #
#####################
function switch()
{
    echo "Command [ switch ] "

    # --- パラメータチェック ---
    local FLG_ID="false"
    while getopts i: OPT
    do
        case ${OPT} in
            "i" ) FLG_ID="true" ; PROJECT_ID="$OPTARG" ;;
              * ) usage
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    # --- 必須パラメータの存在チェック ---
    if [ ${FLG_ID} = "false" ]; then
        usage
        echo "ERR: 引数 -i は必須です"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi

    # --- 設定ファイル読み込み ---
    if [ $(isExistConfig "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i このProjectIDの設定ファイルは存在しません"
        echo "設定ファイルを作成するには下記のコマンドを利用してください"
        echo "docs new -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    source $(getConfigPath ${PROJECT_ID})
    
    # もしも .envが存在しなかったら作成しておく
    if [ $(isFile ${CURRENT_CONFIG}) = "false" ]; then
        switchCurrentConfig ${PROJECT_ID}
    fi
    
    # --- 任意パラメータの初期値入力 ---
    if [ ${PROJECT_ID} != ${CURRENT_PROJECT_ID} ]; then
        echo "ERR: -i 設定ファイルの値が不正です。"
        echo "下記ファイルの設定値が正しいか確認してください。"
        echo $(getConfigPath ${PROJECT_ID})
        echo "新しくプロジェクトを作成する場合は下記コマンドを利用してください。"
        echo "docs new -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'"
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    # --- パラメータの表示 ---
    cat <<- EOF
Params:    
    PROJECT_ID: ${PROJECT_ID}
EOF
    
    # --- パラメータの正当性チェック ---
    # PROJECT_ID: 名称チェック(0-9a-z A-Z _)
    if [ $(isCorrectProjectId "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i  半角英数字とアンダーバーのみ"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # PROJECT_ID: プロジェクトがDockerコンテナに存在しなかったら追加を試みる
    if [ $(isDirOnContainer "${CONTAINER_WORK_DIR}/${PROJECT_ID}/content") = "false" ]; then
        echo "WARN: -i  プロジェクト ${PROJECT_ID} がDockerコンテナ内に存在しません。"
        cat <<- EOF
Message:    
    プロジェクトの追加を試みます...
EOF
        docs add -i ${PROJECT_ID} -w ${CURRENT_WORK_DIR} -b ${CURRENT_BUILD_DIR}
        NEW_EXIT=$?
        if [ ${NEW_EXIT} -eq ${EXIT_NORMAL} ]; then
            cat <<- EOF
Message:    
    追加に成功しました!!!
EOF
            exit ${EXIT_NORMAL}
        else
            cat <<- EOF
Message:    
    追加中にエラー発生
    下記のコマンドから改めてプロジェクトを生成・追加してください
    docs new -f -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'
    docs add -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'
EOF
            exit ${NEW_EXIT}
        fi
    fi
    
    # --- Logic ---
    # カレントコンフィグのバックアップ
    BKUP_CURRENT_CONFIG="${CURRENT_CONFIG}.old"
    if [ $(isFile ${CURRENT_CONFIG}) = "true" ]; then
        cp -f ${CURRENT_CONFIG} ${BKUP_CURRENT_CONFIG};
    fi
    
    # カレントコンフィグファイルを置き換える
    switchCurrentConfig ${PROJECT_ID}
    source ${CURRENT_CONFIG}

    # Dockerコンテナの再起動
    reboot
    REBOOT_RESULT=$?
    
    # バックアップファイルを削除
    if [ ${REBOOT_RESULT} -eq ${EXIT_NORMAL} -a $(isFile ${BKUP_CURRENT_CONFIG}) = "true" ]; then
        rm ${BKUP_CURRENT_CONFIG}
        echo "Done."        
    fi
}

#####################
# subcommand remove #
#####################
function remove()
{
    echo "Command [ remove ] "

    # --- パラメータチェック ---
    local FLG_ID="false"
    local FLG_REMOVE_CURRENT_CONFIG="false"
    while getopts fi: OPT
    do
        case ${OPT} in
            "i" ) FLG_ID="true" ; PROJECT_ID="$OPTARG" ;;
              * ) usage
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    # --- 設定の読み込み ---
    if [ ${FLG_ID} = "true" -a $(isExistConfig "${PROJECT_ID}") = "true" ]; then
        # 指定の設定ファイルがあれば読み込む
        source $(getConfigPath ${PROJECT_ID})
    elif [ $(isFile ${CURRENT_CONFIG}) = "true" ]; then
        # .envがあれば読み込む        
        source ${CURRENT_CONFIG}
        FLG_REMOVE_CURRENT_CONFIG="true"
    else
        # 読み込む設定ファイルがなければエラー
        echo "ERR: -i カレントドキュメントが指定されていない場合は必須です"
        echo "先に switch コマンドでカレントドキュメントを指定してもOKです"
        echo "docs switch -i [Document ID]"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # もしも .envが存在しなかったら作成しておく
    if [ $(isFile ${CURRENT_CONFIG}) = "false" ]; then
        switchCurrentConfig ${PROJECT_ID}
        FLG_REMOVE_CURRENT_CONFIG="true"
    fi

    # --- 任意パラメータの初期値入力 ---
    if [ ${FLG_ID} = "false" ]; then
        PROJECT_ID=${CURRENT_PROJECT_ID}
    fi
    
    if [ ${PROJECT_ID} != ${CURRENT_PROJECT_ID} ]; then
        echo "ERR: -i 設定ファイルの値が不正です。"
        echo "下記ファイルの設定値が正しいか確認してください。"
        echo $(getConfigPath ${PROJECT_ID})
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    # --- パラメータの表示 ---
    cat <<- EOF
Params:    
    PROJECT_ID: ${PROJECT_ID}
EOF
    
    # --- パラメータの正当性チェック ---
    # PROJECT_ID: 名称チェック(0-9a-z A-Z _)
    if [ $(isCorrectProjectId "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i  半角英数字とアンダーバーのみ"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # --- Logic ---    
    # カレントコンフィグの削除
    if [ ${FLG_REMOVE_CURRENT_CONFIG} = "true" ]; then
        rm ${CURRENT_CONFIG}
    fi
    
    # コンフィグの削除
    PROJECT_CONFIG=$(getConfigPath ${PROJECT_ID})
    if [ $(isFile ${PROJECT_CONFIG}) = "true" ]; then
        rm ${PROJECT_CONFIG}
    fi
    
    # Work Dirの削除
    if [ $(isDir ${CURRENT_WORK_DIR}) = "true" ]; then
        rm -fr ${CURRENT_WORK_DIR}
    fi
    
    # Build Dirの削除
    if [ $(isDir ${CURRENT_BUILD_DIR}) = "true" ]; then
        rm -fr ${CURRENT_BUILD_DIR}
    fi
    
    cat <<- EOF
Message:    
    Documentの削除は完了しました。
    カレントドキュメントを削除した場合は、switch コマンドや new コマンドで
    別のカレントドキュメントに切り替えてください。
    Dockerの共有Volumeが不安定になっている可能性があります。
EOF
}

######################
# subcommand preview #
######################
function preview()
{
    echo "Command [ preview ] "

    # --- パラメータチェック ---
    local FLG_ID="false"
    while getopts i: OPT
    do
        case ${OPT} in
            "i" ) FLG_ID="true" ; PROJECT_ID="$OPTARG" ;;
              * ) usage
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    # --- 必須パラメータの存在チェック ---
    # なし
    
    # --- 設定の読み込み ---
    if [ ${FLG_ID} = "true" -a $(isExistConfig "${PROJECT_ID}") = "true" ]; then
        # 指定の設定ファイルがあれば読み込む
        source $(getConfigPath ${PROJECT_ID})
    elif [ $(isFile ${CURRENT_CONFIG}) = "true" ]; then
        # .envがあれば読み込む        
        source ${CURRENT_CONFIG}
    else
        # 読み込む設定ファイルがなければエラー
        echo "ERR: -i カレントドキュメントが指定されていない場合は必須です"
        echo "先に switch コマンドでカレントドキュメントを指定してもOKです"
        echo "docs switch -i [Document ID]"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi
    
    # もしも .envが存在しなかったら作成しておく
    if [ $(isFile ${CURRENT_CONFIG}) = "false" ]; then
        switchCurrentConfig ${PROJECT_ID}
    fi
    
    # --- 任意パラメータの初期値入力 ---
    if [ ${FLG_ID} = "false" ]; then
        PROJECT_ID=${CURRENT_PROJECT_ID}
    fi
    
    if [ ${PROJECT_ID} != ${CURRENT_PROJECT_ID} ]; then
        echo "ERR: -i 設定ファイルの値が不正です。"
        echo "下記ファイルの設定値が正しいか確認してください。"
        echo $(getConfigPath ${PROJECT_ID})
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    # --- パラメータの表示 ---
    cat <<- EOF
Params:    
    PROJECT_ID: ${PROJECT_ID}
EOF
    
    # --- パラメータの正当性チェック ---
    # PROJECT_ID: 名称チェック(0-9a-z A-Z _)
    if [ $(isCorrectProjectId "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i  半角英数字とアンダーバーのみ"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # PROJECT_ID: プロジェクトがDockerコンテナに存在しなかったらエラー
    if [ $(isDirOnContainer "${CONTAINER_WORK_DIR}/${PROJECT_ID}/content") = "false" ]; then
        echo "ERR: -i  プロジェクト ${PROJECT_ID} がDockerコンテナ内に存在しません。"
        echo "new コマンドでプロジェクトを作成してください"
        echo "docs new -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'"
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    # --- Logic ---
    # サーバー立ち上げ
    local COMMAND="cd ${CONTAINER_WORK_DIR}/${PROJECT_ID} && \
    kill \$(pidof 'hugo') ; \
    ${CMD_HUGO} server -wv --bind='0.0.0.0'"
    cat <<- EOF
Main Command:
    ${COMMAND}
EOF
    docker exec -i ${CONTAINER_NAME} bash -c "${COMMAND}"
}

####################
# subcommand build #
####################
function build()
{
    echo "Command [ build ] "

    # --- パラメータチェック ---
    local FLG_ID="false"
    while getopts i: OPT
    do
        case ${OPT} in
            "i" ) FLG_ID="true" ; PROJECT_ID="$OPTARG" ;;
              * ) usage
                  exit ${EXIT_INVALID_ARGUMENT} ;;
        esac
    done
    
    # --- 必須パラメータの存在チェック ---
    # なし
    
    # --- 設定の読み込み ---
    if [ ${FLG_ID} = "true" -a $(isExistConfig "${PROJECT_ID}") = "true" ]; then
        # 指定の設定ファイルがあれば読み込む
        source $(getConfigPath ${PROJECT_ID})
    elif [ $(isFile ${CURRENT_CONFIG}) = "true" ]; then
        # .envがあれば読み込む        
        source ${CURRENT_CONFIG}
    else
        # 読み込む設定ファイルがなければエラー
        echo "ERR: -i カレントドキュメントが指定されていない場合は必須です"
        echo "先に switch コマンドでカレントドキュメントを指定してもOKです"
        echo "docs switch -i [Document ID]"
        exit ${EXIT_NOT_ENOUGH_ARGUMENT}
    fi
    
    # もしも .envが存在しなかったら作成しておく
    if [ $(isFile ${CURRENT_CONFIG}) = "false" ]; then
        switchCurrentConfig ${PROJECT_ID}
    fi
    
    # --- 任意パラメータの初期値入力 ---
    if [ ${FLG_ID} = "false" ]; then
        PROJECT_ID=${CURRENT_PROJECT_ID}
    fi
    
    if [ ${PROJECT_ID} != ${CURRENT_PROJECT_ID} ]; then
        echo "ERR: -i 設定ファイルの値が不正です。"
        echo "下記ファイルの設定値が正しいか確認してください。"
        echo $(getConfigPath ${PROJECT_ID})
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    # --- パラメータの表示 ---
    cat <<- EOF
Params:    
    PROJECT_ID: ${PROJECT_ID}
EOF
    
    # --- パラメータの正当性チェック ---
    # PROJECT_ID: 名称チェック(0-9a-z A-Z _)
    if [ $(isCorrectProjectId "${PROJECT_ID}") = "false" ]; then
        echo "ERR: -i  半角英数字とアンダーバーのみ"
        exit ${EXIT_INVALID_ARGUMENT}
    fi
    
    # PROJECT_ID: プロジェクトがDockerコンテナに存在しなかったらエラー
    if [ $(isDirOnContainer "${CONTAINER_WORK_DIR}/${PROJECT_ID}/content") = "false" ]; then
        echo "ERR: -i  プロジェクト ${PROJECT_ID} がDockerコンテナ内に存在しません。"
        echo "new コマンドでプロジェクトを作成してください"
        echo "docs new -i ${PROJECT_ID} -w 'Mark Downファイルを置き場の絶対パス' -b '静的サイトビルド先'"
        exit ${EXIT_LOGIC_EXCEPTION}
    fi
    
    # --- Logic ---
    # ビルド
    local COMMAND="cd ${CONTAINER_WORK_DIR}/${PROJECT_ID} && ${CMD_HUGO}"
    cat <<- EOF
Main Command:
    ${COMMAND}
EOF
    docker exec -i ${CONTAINER_NAME} bash -c "${COMMAND}"
    # ビルド結果をコピー
    rm -fr ${CURRENT_BUILD_DIR}
    docker cp ${CONTAINER_NAME}:${CONTAINER_WORK_DIR}/${PROJECT_ID}/public/. ${CURRENT_BUILD_DIR}
}

#################
# Main Process  #
#################
# サブコマンドがない場合は使い方を表示して終了
if [ $# -lt 1 ]; then
    usage
    exit ${EXIT_NO_EXIST_SUBCOMMAND}
fi

# サブコマンドを取得し、パラメータを1つずらす
SUBCOMMAND=$1
shift

if type "${SUBCOMMAND}" >/dev/null 2>&1 ; then
    cd ${DOCS_PROJECT_DIR}
    # サブコマンド実行
    ${SUBCOMMAND} "$@"
else
    usage
    echo "ERR: 存在しないコマンドです [ ${SUBCOMMAND} ]"
    exit ${EXIT_NO_EXIST_SUBCOMMAND}
fi

exit ${EXIT_NORMAL}
