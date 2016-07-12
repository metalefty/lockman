#!/usr/bin/env bash
# vim: sw=2 sts=2 expandtab :

error_exit()
{
  echo_stderr $@
  exit 1
}

echo_stderr()
{
  echo $@ 1>&1
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

export LANG=C
umask 077

TEST_FILE_URL=http://w.vmeta.jp/temp/Eastern_Grey_Squirrel.jpg
TEST_FILE_BASENAME=$(basename "${TEST_FILE_URL}")
TMPDIR=$(maketemp)

# test requirements
type openssl || error_exit "openssl is not available."
type shar    || error_exit "shar is not available."
type sed     || error_exit "sed is not available."
type dirname || error_exit "GNU Coreutils is not available."

ssh-keygen -b ${1:-2048} -N '' -f ${TMPDIR}/id_rsa 2>/dev/null || \
  error_exit "failed to generate SSH key pair."
ssh-keygen -e -m pkcs8 -f ${TMPDIR}/id_rsa 2>/dev/null || \
  error_exit "ssh-keygen(1) does not have \"-m\" option. OpenSSH >=5.6 required."
wget --quiet --directory-prefix ${TMPDIR} "${TEST_FILE_URL}"

./lockman.sh -k ${TMPDIR}/id_rsa.pub -f "${TMPDIR}/${TEST_FILE_BASENAME}"
bash "${TEST_FILE_BASENAME}.bash" -k ${TMPDIR}/id_rsa

if [ -f "${TEST_FILE_BASENAME}" -a -f "${TMPDIR}/${TEST_FILE_BASENAME}" ]
then
  diff -q "${TEST_FILE_BASENAME}" "${TMPDIR}/${TEST_FILE_BASENAME}" || exit $?
  echo 'looks good.'
  rm -rf "${TEST_FILE_BASENAME}" "${TEST_FILE_BASENAME}.bash" ${TMPDIR}
  exit 0
else
  exit 1
fi
