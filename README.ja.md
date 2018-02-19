# lockman - 自己復号ファイル暗号化ユーティリティ

lockmanはオープンソースのファイル暗号化ユーティリティです。SSH公開鍵でファイルを
暗号化し、自己復号形式のファイルを生成します。暗号化されたファイルは対応するSSH
秘密鍵で復号することができます。

* 公開鍵暗号
* SSHの鍵ペアを使用
* 最小限のソフトウェア依存性
* ありふれたオープンソースツールの組み合わせ

## システム要件

以下のシステムで動作することを確認しています。

* Amazon Linux 2016.03
* CentOS 7.2
* FreeBSD 10.3-RELEASE
* OS X Yosemite, El Capitan

これ以外のシステムでも、以下の要件を満たすシステムで動作するはずです。

### 暗号化
* GNU bash
* GNU coreutils または同等の BSD コマンド (basename, cat, cp, dirname, mkdir, mktemp, rm, tr)
* GNU findutils / BSD find
* GNU sed / BSD sed
* GNU sharutils / BSD shar
* OpenSSH 5.6 以上
* OpenSSL 0.9.8e 以上 (より新しいバージョンが好まれます)

### 復号
* GNU bash
* GNU coreutils または同等 のBSD コマンド (cat, cp, rm)
* OpenSSL 0.9.8e 以上 (より新しいバージョンが好まれます)

### テスト


テストを実行するには、上記の全てに加えて以下のツールが必要です。

* GNU make (optional)
* GNU diffutils / BSD diff
* GNU wget

## Install

```
$ git clone https://github.com/metalefty/lockman.git && cd lockman
# make install
```

`make install` できない場合は、lockman.sh を適当なパスの通った場所に置いてください。
## 使い方

### 暗号化

ファイルを送りたい相手のSSH公開鍵を `-k` オプションで指定、暗号化したいファイルを `-f` オプションで指定します。

```
$ lockman -k RECIPIENTS_SSH_PUBLIC_KEY -f FILE_TO_ENCRYPT
```

`FILE_TO_ENCRYPT.bash` という暗号化ファイルがカレントディレクトリに生成されます。


たとえば、誰かのGitHub上のSSH公開鍵で暗号化したい場合は以下のようにします。

```
$ wget -q https://github.com/metalefty.keys
$ lockman -k metalefty.keys -f FILE_TO_ENCRYPT
```
GitHubに複数の公開鍵が登録されている場合、先頭の物が暗号化に使用されます。

使用する鍵を指定したい場合、`sed` コマンド等を使ってn番目の鍵を取り出してください。
例えば3番目の鍵を使用する場合は以下のようにします。

```
$ wget -q -O - https://github.com/somebody.keys | sed -n 3p > somebody.3rd-key
```

### 復号

`.bash` 拡張子のファイルを受け取った受信者は、bash でそのファイルを実行することで
復号できます。`-k` オプションで自分のSSH秘密鍵を与えてください。

```
$ bash original_file_name.bash -k ~/.ssh/id_rsa
```

複合されたファイルはカレントディレクトリに書き出されます。

## 制限事項

暗号化に使用するSSH公開鍵はRSA2暗号鍵のみ使用できます。DSA, ECDSA, Ed25519, RSA1鍵は
使用できません。

RSA鍵の長さは2048bit以上でなければなりません。
