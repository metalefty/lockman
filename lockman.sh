#!/usr/bin/env bash
# vim: sw=2 sts=2 expandtab :
#
# The MIT License (MIT)
#
# Copyright (c) 2016 Koichiro IWAO aka metalefty <meta@vmeta.jp>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

export LANG=C
umask 077

error_exit()
{
  echo_stderr $@
  exit 1
}

echo_stderr()
{
  echo -e $@ 1>&1
}

usage()
{
  echo_stderr "Usage: $0 -k ssh_public_key -f file"
  exit
}

file_does_not_exist()
{
  echo_stderr "$1 does not exist or not a regular file"
  exit 1
}

absolute_path()
{
  echo $(cd $(dirname $1) && pwd)/$(basename $1)
}

maketemp()
{
  # try BSD mktemp first
  local _t=$(mktemp -q -d -t lockman)
  if [ -z "${_t}" ]
  then
    # GNU mktemp
    _t=$(mktemp -d)
  fi

  echo ${_t}
}

# parse arguments
if [ $# -lt 4 ]
then
  usage
fi

while getopts f:k:h OPTION
do
  case ${OPTION} in
    f)
      if [ -f "${OPTARG}" ]
      then
        INPUT_FILE=$(absolute_path "${OPTARG}")
      else
        file_does_not_exist "${OPTARG}"
      fi
      ;;
    k)
      if [ -f "${OPTARG}" ]
      then
        SSH_PUBKEY=$(absolute_path "${OPTARG}")
      else
        file_does_not_exist "${OPTARG}"
      fi
      ;;
    h)
      usage
      ;;
    '?')
      usage
      ;;
  esac
done

MAGICNUMBER=46f5c833d3f02bfa476dc62215484d275bc848f71c164236e35db9766a9f2a8d

# create working directory
TMPDIR=$(maketemp)

AES_KEY=${TMPDIR}/key.bin
SSH_PUBKEY_PKCS8=${TMPDIR}/ssh_pubkey.pkcs8

INPUT_FILE_BASENAME=$(basename "${INPUT_FILE}")
ARCHIVE_DIR=${TMPDIR}/${MAGICNUMBER}
ENCRYPTED_FILE=${ARCHIVE_DIR}/encrypted_data.bin
ENCRYPTED_AES_KEY=${ARCHIVE_DIR}/encrypted_key.bin

echo ${TMPDIR} # debug

{
cd ${TMPDIR}

# create archive directory
mkdir -p ${ARCHIVE_DIR}

echo ${INPUT_FILE_BASENAME} > ${ARCHIVE_DIR}/originalfilename

# convert ssh public key to PKCS8
ssh-keygen -e -m PKCS8 -f ${SSH_PUBKEY} 2>/dev/null > ${SSH_PUBKEY_PKCS8} || \
  error_exit "ssh-keygen(1) does not have \"-m\" option. OpenSSH >=5.6 required." \
  "\nOr wrong passphrase entered."

# generate random common key
# encrypt generated key with recipient's SSH public key
# base64 encode encrypted common key
  </dev/urandom tr -dc '[:graph:]' | head -c 245 | tee ${AES_KEY} | \
  openssl rsautl -encrypt -pubin -inkey ${SSH_PUBKEY_PKCS8} | \
  openssl base64 -e > ${ENCRYPTED_AES_KEY}.base64

# encrypt file with generated key
openssl enc -aes-128-cbc -e -a -kfile ${AES_KEY} -in ${INPUT_FILE} -out ${ENCRYPTED_FILE}

# archive
shar $(find $(basename ${ARCHIVE_DIR})) \
  | sed -e 's|^exit$||' -e 's|^exit 0||'> ${INPUT_FILE_BASENAME%.*}.shar

cd "${OLDPWD}"
}

### decrypter script begin
DECRYPT_SCRIPT_PART1='#!/usr/bin/env bash
#
# The MIT License (MIT)
#
# Copyright (c) 2016 Koichiro IWAO aka metalefty <meta@vmeta.jp>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# DISCLAIMER : This license is never applied for user data.
#

export LANG=C
umask 077

error_exit()
{
  echo_stderr $@
  exit 1
}

echo_stderr()
{
  echo $@ 1>&1
}

usage()
{
  echo_stderr "Usage: $0 -k ssh_private_key"
  exit
}

file_does_not_exist()
{
  echo_stderr "$1 does not exist or not a regular file"
  exit
}

absolute_path()
{
  echo $(cd $(dirname $1) && pwd)/$(basename $1)
}

# parse arguments
if [ $# -lt 2 ]
then
  usage
fi

while getopts k:h OPTION
do
  case ${OPTION} in
    k)
      if [ -f "${OPTARG}" ]
      then
        SSH_PRIVKEY=$(absolute_path "${OPTARG}")
      else
        file_does_not_exist "${OPTARG}"
      fi
      ;;
    h)
      usage
      ;;
    \?)
      usage
      ;;
  esac
done

MAGICNUMBER=46f5c833d3f02bfa476dc62215484d275bc848f71c164236e35db9766a9f2a8d
##### begin user data
'

DECRYPT_SCRIPT_PART2='
##### end user data

ORIGINAL_FILENAME="$(cat ${MAGICNUMBER}/originalfilename)"
{
cd ${MAGICNUMBER}

# base64 decode encrypted common key
openssl base64 -d \
  -in encrypted_key.bin.base64 \
  -out encrypted_key.bin 2>/dev/null || \
  error_exit "failed to base64 decode common key."

# decrypt encrypted commonkey SSH private key
openssl rsautl -decrypt \
  -inkey ${SSH_PRIVKEY} \
  -in encrypted_key.bin \
  -out decrypted_key.bin 2>/dev/null || \
  error_exit "failed to decrypt common key. wrong private key specified?"

# decrypt file with decrypted common key
openssl enc -aes-128-cbc -d -a -kfile decrypted_key.bin \
  -in encrypted_data.bin \
  -out "$(cat originalfilename)" 2>/dev/null || \
  error_exit "failed to decrypt encrypted data. something going wrong."

cd "${OLDPWD}"
}

cp -i -a \
  "${MAGICNUMBER}/${ORIGINAL_FILENAME}" \
  "${ORIGINAL_FILENAME}"

if [ -d "${MAGICNUMBER}" ]
then
  rm -rf "${MAGICNUMBER}"
fi
'
### decrypter script end

echo "${DECRYPT_SCRIPT_PART1}" \
  > ${TMPDIR}/__${INPUT_FILE_BASENAME}__.shar
cat ${TMPDIR}/${INPUT_FILE_BASENAME%.*}.shar \
  >> ${TMPDIR}/__${INPUT_FILE_BASENAME}__.shar
echo "${DECRYPT_SCRIPT_PART2}" \
  >> ${TMPDIR}/__${INPUT_FILE_BASENAME}__.shar

cp -i -a ${TMPDIR}/__${INPUT_FILE_BASENAME}__.shar ./${INPUT_FILE_BASENAME}.bash

# I know this does not necessarily shred a file completely.
# It depends on operating system or file system.
openssl rand -out "${AES_KEY}" 4096
openssl rand -out "${AES_KEY}" 4096
openssl rand -out "${AES_KEY}" 4096

if [ -d "${TMPDIR}" ]
then
  rm -rf "${TMPDIR}"
fi
