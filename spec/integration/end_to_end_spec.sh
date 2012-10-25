#!/bin/bash

HERE=$(dirname $0)
TOP=$(dirname $(dirname $HERE))
EXIT_STATUS=1
export SPEC_TMPDIR=$(mktemp -d "${TMPDIR:-"/var/tmp"}/git-duet-specs-XXXXX")
mkdir -p "${SPEC_TMPDIR}/.desc"
mkdir -p "${SPEC_TMPDIR}/.funcs"

export STARTDIR=$PWD
export GIT_AUTHORS_PATH="${SPEC_TMPDIR}/.git-authors"
export EMAIL_LOOKUP_PATH="${SPEC_TMPDIR}/email-lookup"
export REPO_DIR="${SPEC_TMPDIR}/foo"

cat > "${EMAIL_LOOKUP_PATH}" <<EOF
#!/usr/bin/env ruby
addr = {
  'jd' => 'jane_doe@lookie.me',
  'fb' => 'fb9000@dalek.info'
}[ARGV.first]
puts addr
EOF
chmod 0755 "${EMAIL_LOOKUP_PATH}"
cat > "${GIT_AUTHORS_PATH}" <<EOF
pairs:
  jd: Jane Doe
  fb: Frances Bar
email:
  domain: hamster.info
email_addresses:
  jd: jane@hamsters.biz
EOF

export GIT_DUET_AUTHORS_FILE="${GIT_AUTHORS_PATH}"
export PATH="${TOP}/bin:${PATH}"

pushd "${SPEC_TMPDIR}" >/dev/null
git init "${REPO_DIR}" >/dev/null


trap "
pushd '${STARTDIR}' >/dev/null
if [ -n '${SPEC_NO_CLEANUP}' ] ; then
  echo '${SPEC_TMPDIR}' > '${TOP}/integration-end-to-end-test-dir.txt'
else
  rm -rvf '${SPEC_TMPDIR}'
fi
" SIGINT SIGTERM


N_CONTEXT=0

context() {
    CONTEXTS[${N_CONTEXT}]="${2}"
    CONTEXT_DESCRIPTIONS[${N_CONTEXT}]="${1}"
    let N_CONTEXT+=1
    N_TEST=0
}

it() {
    echo "${1}" > "${SPEC_TMPDIR}/.desc/${N_CONTEXT}_${N_TEST}"
    echo "${2}" >> "${SPEC_TMPDIR}/.funcs/${N_CONTEXT}"
    let N_TEST+=1
}

main() {
    local ci=1
    local ti=0
    local failed=0
    local passed=0
    local total=0

    pushd "${SPEC_TMPDIR}" >/dev/null

    for ctx in ${CONTEXTS[@]}
    do
        ti=0
        echo "${CONTEXT_DESCRIPTIONS[$(expr $ci - 1)]}"
        for test_func in $(cat "${SPEC_TMPDIR}/.funcs/${ci}")
        do
            echo -n "  $(cat "${SPEC_TMPDIR}/.desc/${ci}_${ti}") ... "
            _${ctx}_before
            $test_func
            if [[ $? -eq 1 ]]; then
                echo "PASS"
                let passed+=1
            else
                echo "FAIL"
                let failed+=1
            fi
            let total+=1
            _${ctx}_after
            let ti+=1
        done
        let ci+=1
    done

    echo '--------------------------------------------------------------'
    echo "PASS=$passed FAIL=$failed TOTAL=$total"
    if [[ $failed -gt 0 ]]; then
        echo "Look in ${SPEC_TMPDIR}"
        EXIT_STATUS=1
    else
        EXIT_STATUS=0
    fi
}

# ------------------------------------------------------------------------------
# BEGIN SUITE BUILDUP
# ------------------------------------------------------------------------------


context 'when installing the pre commit hook' '00'
_00_before() {
    pushd "${REPO_DIR}" >/dev/null
    git duet-install-hook -q
}
_00_after() {
    rm -rf .git/hooks/pre-commit
}
it 'should write the hook to the pre commit hook file' '_00_01'
_00_01() {
    test -f .git/hooks/pre-commit && return 1
    return 0
}
it 'should make the pre commit hook file executable' '_00_02'
_00_02() {
    test -x .git/hooks/pre-commit && return 1
    return 0
}


context 'when setting the author via solo' '01'
_01_before() {
    pushd "${REPO_DIR}" >/dev/null
    git solo jd -q
}
_01_after() {
    :
}
it 'should set the git user name' '_01_01'
_01_01() {
    [[ "$(git config user.name)" =~ 'Jane Doe' ]] && return 1
    return 0
}
it 'should set the git user email' '_01_02'
_01_02() {
    [[ "$(git config user.email)" =~ 'jane@hamsters.biz' ]] && return 1
    return 0
}
it 'should cache the git user name as author name' '_01_03'
_01_03() {
    [[ "$(git config duet.env.git-author-name)" =~ 'Jane Doe' ]] && return 1
    return 0
}
it 'should cache the git user email as author email' '_01_04'
_01_04() {
    [[ "$(git config duet.env.git-author-email)" =~ 'jane@hamsters.biz' ]] && return 1
    return 0
}


context 'when an external email lookup is provided and setting the author via solo' '02'
_02_before() {
    OLD_EMAIL_LOOKUP="${GIT_DUET_EMAIL_LOOKUP_COMMAND}"
    export GIT_DUET_EMAIL_LOOKUP_COMMAND="${EMAIL_LOOKUP_PATH}"
    pushd "${REPO_DIR}" >/dev/null
    git solo jd -q
}
_02_after() {
    export GIT_DUET_EMAIL_LOOKUP_COMMAND="${OLD_EMAIL_LOOKUP}"
}
it 'should set the author email address given by the external email lookup' '_02_01'
_02_01() {
    [[ "$(git config duet.env.git-author-email)" =~ 'jane_doe@lookie.me' ]] && return 1
    return 0
}


context 'when an external email lookup is provided and setting author and committer via duet' '03'
_03_before() {
    pushd "${REPO_DIR}" >/dev/null
    git duet jd fb -q
}
_03_after() {
    :
}
it 'should set the author email address given by the external email lookup' '_03_01'
_03_01() {
    [[ "$(git config duet.env.git-author-email)" =~ 'jane_doe@lookie.me' ]] && return 1
    return 0
}
it 'should set the committer email address given by the external email lookup' '_03_02'
_03_02() {
    [[ "$(git config duet.env.git-committer-email)" =~ 'fb9000@dalek.info' ]] && return 1
    return 0
}


context 'when setting author and committer via duet' '04'
_04_before() {
    pushd "${REPO_DIR}" >/dev/null
    git duet jd fb -q
}
_04_after() {
    :
}
it 'should set the git user name' '_04_01'
_04_01() {
    [[ "$(git config user.name)" =~ 'Jane Doe' ]] && return 1
    return 0
}
it 'should set the git user email' '_04_02'
_04_02() {
    [[ "$(git config user.email)" =~ 'jane@hamsters.biz' ]] && return 1
    return 0
}
it 'should cache the git committer name' '_04_03'
_04_03() {
    [[ "$(git config duet.env.git-committer-name)" =~ 'Frances Bar' ]] && return 1
    return 0
}
it 'should cache the git committer email' '_04_04'
_04_04() {
    [[ "$(git config duet.env.git-committer-email)" =~ 'f.bar@hamster.info' ]] && return 1
    return 0
}


context 'when committing via git-duet-commit after running git-duet' '05'
_05_before() {
    pushd "${REPO_DIR}" >/dev/null
    git duet jd fb -q
    echo "foo-${RANDOM}" > file.txt
    git add file.txt
}
_05_after() {
    :
}
it 'should list the alpha of the duet as author in the log' '_05_01'
_05_01() {
    git duet-commit -q -m 'Testing set of alpha as author'
    [[ "$(git log -1 --format='%an <%ae>')" =~ 'Jane Doe <jane@hamsters.biz>' ]] && return 1
    return 0
}
it 'should list the omega of the duet as committer in the log' '_05_02'
_05_02() {
    git duet-commit -q -m 'Testing set of omega as committer'
    [[ "$(git log -1 --format='%cn <%ce>')" =~ 'Frances Bar <f.bar@hamster.info>' ]] && return 1
    return 0
}


context 'after running git-solo' '06'
_06_before() {
    pushd "${REPO_DIR}" >/dev/null
    git solo jd -q
    echo "foo-${RANDOM}" > file.txt
    git add file.txt
}
_06_after() {
    :
}
it 'should list the soloist as author in the log' '_06_01'
_06_01() {
    git duet-commit -m 'Testing set of soloist as author' 2>/dev/null
    [[ "$(git log -1 --format='%an <%ae>')" =~ 'Jane Doe <jane@hamsters.biz>' ]] && return 1
    return 0
}
it 'should list the soloist as committer in the log' '_06_02'
_06_02() {
    git duet-commit -m 'Testing set of soloist as committer' 2>/dev/null
    [[ "$(git log -1 --format='%cn <%ce>')" =~ 'Jane Doe <jane@hamsters.biz>' ]] && return 1
    return 0
}


# ------------------------------------------------------------------------------
# RUN SUITE!
# ------------------------------------------------------------------------------
main
exit $EXIT_STATUS
