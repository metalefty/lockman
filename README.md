# lockman - Self-decrypting file encryption utility

lockman is an open source file encryption utility that can encrypt with
SSH public key and generates self-extracting (self-decrypting) file.

* public key cryptosystem
* use SSH key pair
* least dependency to decrypt (almost nothing to install additional tools)
* combination of common open source tools

## System Requirements

Confirmed on these systems.

* Amazon Linux 2016.03
* CentOS 7.2
* FreeBSD 10.3-RELEASE
* OS X Yosemite, El Capitan

lockman should work if the system meets following requirements.

### Encryption
* GNU bash
* GNU Coreutils or equivalent BSD command (basename, cat, cp, dirname, mkdir, mktemp, rm, tr)
* GNU findutils / BSD find
* GNU sed / BSD sed
* GNU sharutils / BSD shar
* OpenSSH 5.6 or higher
* OpenSSL 0.9.8e or higher (newer version preferred)

### Decryption
* GNU bash
* GNU Coreutils or equivalent BSD command (cat, cp, rm)
* OpenSSL 0.9.8e or higher (newer version preferred)

### Test

To run test, these tools are needed in addition to above all.

* GNU make (optional)
* GNU diffutils / BSD diff
* GNU wget

## Install

```
$ git clone https://github.com/metalefty/lockman.git && cd lockman
# make install
```
 About
## Usage

### Encryption

```
$ lockman -k RECIPIENTS_SSH_PUBLIC_KEY -f FILE_TO_ENCRYPT
```

`FILE_TO_ENCRYPT.bash` will be written in current directory.

When you want to use someone's public key on GitHub, mine for example,
like this.

```
$ wget -q https://github.com/metalefty.keys
$ lockman -k metalefty.keys -f FILE_TO_ENCRYPT
```

When multiple public keys are in keys file, the first one is used.

To specify which key to use, pick it up manually.

```
$ wget -q -O - https://github.com/somebody.keys | sed -n 3p > somebody.3rd-key
```

### Decryption

Recipient will receive a file with `.bash` suffix.  Execute the file
via bash and specify your ssh private key with `-k` option.

```
$ bash original_file_name.bash -k ~/.ssh/id_rsa
```

Decrypted file will be written in current directory.

## Limitations

Given SSH public key must be RSA (RSA2, begins ssh-rsa). DSA, ECDSA,
Ed25519 and RSA1 are not supported.

RSA key length must be 2048 bit or longer.
