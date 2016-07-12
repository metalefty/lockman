#!/usr/bin/env bash
# vim: sw=2 sts=2 expandtab :

export LANG=C
umask 077

TEST_FILE_URL=http://w.vmeta.jp/temp/Eastern_Grey_Squirrel.jpg
TEST_FILE_BASENAME=$(basename "${TEST_FILE_URL}")
TMPDIR=$(mktemp -d)

ssh-keygen -N '' -f ${TMPDIR}/id_rsa || exit 1
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
