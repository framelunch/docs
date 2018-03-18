#!/usr/bin/env bash
cd $(dirname $0);
cd $(dirname $(pwd));

if [ ! -f /usr/local/bin/docs ]; then
    # 実行権限付与
    chmod a+x `pwd`/command/docs.sh
    # シンボリックリンクを PATHの通っている場所に作る
    ln -s `pwd`/command/docs.sh /usr/local/bin/docs
    echo "Done."
else
    echo "ERR: インストール済みです"
fi
