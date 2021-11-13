# Dockerfileには「コンテナをどのイメージから生成するか」を必ず記入しなければならず、このイメージをベースイメージと呼び、FROM命令で指定します。
# ベースイメージの書き方 => ＜イメージ名＞:＜タグ名＞
# イメージ名はRailsの基となるRubyを、タグにはRubyのバージョンを指定しています。
# タグ名の読み方 … ＜イメージのバージョン＞ - ＜OS＞＜OSのバージョン(任意)＞
FROM ruby:2.7.2-alpine

# ARGはDockerfile内で使用する変数名を指定します *ここでは「WORKDIR」「RUNTIME_PACKAGES」「DEV_PACKAGES」と言う変数名を宣言をしています。
# 現状は「WORKDIR」という変数しか宣言しておらず何も代入されていないが、docker-compose.yml内で指定する「app」と言う文字列が入ります。
ARG WORKDIR
ARG RUNTIME_PACKAGES="nodejs tzdata postgresql-dev postgresql git"
ARG DEV_PACKAGES="build-base curl-dev"

# ENVを使って設定した環境変数は、Dockerfile内・コンテナ内から参照が可能
# コンテナ上のRailsから呼び出す例）Rails ENV['TZ'] => Asia/Tokyo と出力される
# 変数WORKDIRの値 => app
ENV HOME=/${WORKDIR} \
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

# RUNはベースイメージに対して(このファイルでいうとruby:2.7.2-alpine, 要はRubyに対して)何らかのコマンドを実行する場合に使用します。
# Dockerfile内で変数を展開する場合は、${変数名}、もしくは$変数名と書きます。
# 以下の記述で ${HOME} => /${WORKDIR} => /app という値が出力されます *今回このRUNコマンドは使用しないためコメントアウト
# RUN echo ${HOME}

# Dockerfileで定義した命令( RUN, COPY, ADD, ENTRYPOINT, CMD )を実行する、「コンテナ内の作業ディレクトリのパス」を指定します。
# 以下の記述で ${HOME} => /${WORKDIR} => /app という意味になり、ここで指定したディレクトリパス( /app )配下にRailsアプリが作成されます。
WORKDIR ${HOME}

# ローカルファイル(自分のPC上にあるファイル)をコンテナにコピーする命令です。
# 書き方：COPY コピー元 コピー先
# コピー元…ローカルファイルを指定 ※Dockerfileがあるディレクトリ以下を指定する
# コピー先…コンテナ ※絶対パス or 相対パス(今回は ./ としているため、相対パスで指定していて、「カレントディレクトリと同じ階層に」という意味になる)
# Gemfile*　… Gemfileから始まるファイルを全指定(Gemfile, Gemfile.lookが該当)
COPY Gemfile* ./

# apk とは Alpine Linuxのコマンドです ※Linuxコマンドのapt-getが使用されている場合は、ベースイメージがAlpineでは無いと言う事です。
RUN apk update && \
    apk upgrade && \
    apk add --no-cache ${RUNTIME_PACKAGES} && \
    apk add --virtual build-dependencies --no-cache ${DEV_PACKAGES} && \
    bundle install -j4 && \
    apk del build-dependencies

# ドットの意味は、現在のファイル(Dockerfile)があるディレクトリ(app)直下のディレクトリ全てのファイルのこと
# 以下の記述で /app配下の全てのファイルを選択して、コンテナのカレントディレクトリにコピーする ということになる
COPY . ./

# CMDは、生成されたコンテナ内で実行したいコマンドを指定する時に使う命令。*複数のコマンドを指定する場合は配列形式で指定する
# コンテナ内で実行したいコマンド…このファイルの場合は、Railsサーバーを指します。
# 下記の記述で、Railsを起動するためのrails serverコマンドを実行する
# -b 0.0.0.0 はrails serverのコマンドオプションとなります。railsのプロセスをどのipアドレスにバインドするかを指定します ※-bはバインドの意味 
# 下記の記述では localhostのipアドレス「127.0.0.1」を「0.0.0.0」にバインドしています。
# 仮想環境で起動したRailsは、localhostのipアドレス「127.0.0.1」でアクセスできないため、仮想外部からアクセスできるように、ip「0.0.0.0」に紐付けをする必要があるのです。
CMD ["rails", "server", "-b", "0.0.0.0"]
