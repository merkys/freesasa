
# The tests here mainly check that errors are caught and that
# execution is successful in normal cases. For some cases the output
# is compared with reference output, but the correctness of
# calculations is generally handled by the unit tests.

cli=../src/freesasa
datadir=../tests/data
sharedir=../share/
dump=tmp/test-cli.dump # will only contain the latest output
nofile=nonexistent-file
nodir=nonexistent-dir/file
#global errors
errors=0

function assert_pass
{
    eval $1 
    if [[ $? -ne 0 ]]; then 
        echo Error: \"$1\" failed
        let errors=errors+1
    else 
        echo \"$1\" successful
    fi
}

function assert_fail
{
    eval $1 2>/dev/null
    if [[ $? -eq 0 ]]; then 
        echo Error: \"$1\" did not fail as expected
        let errors=errors+1
    else 
        echo \"$1\" failed as expected;
    fi
}

if [[ ! -d tmp ]]; then mkdir tmp; fi

rm -f tmp/*
echo
echo "== Basic file errors =="
assert_fail "$cli > $dump"
assert_fail "$cli $nofile > $dump"
assert_fail "$cli < $nofile > $dump"
assert_fail "$cli -c $nofile < $datadir/1ubq.pdb > $dump"
assert_fail "$cli < $datadir/1ubq.pdb > $nodir"
assert_fail "$cli -B$nodir < $datadir/1ubq.pdb > $dump"
assert_fail "$cli -r$nodir < $datadir/1ubq.pdb > $dump"
assert_fail "$cli -R$nodir < $datadir/1ubq.pdb > $dump"
echo
echo "== General options =="
assert_pass "$cli -h > $dump 2> /dev/null"
version=`$cli -v`
# check that it's a valid version number
assert_pass "echo $version | perl -ne 'if (m/^\d+\.(\d+\.)+\d$/) {exit 0} else  {exit 1}'"
echo
echo "== Testing S&R =="
assert_pass "$cli < $datadir/1ubq.pdb > $dump"
echo
#check that output message has required components
assert_pass "grep '## FreeSASA $version ##' $dump"
assert_pass "grep 'name: stdin' $dump"
$cli $datadir/1ubq.pdb > $dump
assert_pass "grep 'name: $datadir/1ubq.pdb' $dump"
assert_pass "grep 'probe-radius: \d' $dump"
assert_pass "grep 'n_thread: \d' $dump"
assert_pass "grep 'n_testpoint: \d' $dump"
assert_pass "grep 'algorithm: \w' $dump"
assert_pass "grep 'Total:\s\s*4759.86 A2' $dump"
assert_pass "grep 'Polar:\s\s*2232.23 A2' $dump"
assert_pass "grep 'Apolar:\s\s*2527.63 A2' $dump"
# The above formulation of log output gives freedom in ordering and
# whitespace, and also version. Allows non-essential details to change
# without breaking the test. Will not be performed for variant
# parameter values, those should be covered by tests.

echo
#check parameter errors
assert_pass "$cli -n 500 < $datadir/1ubq.pdb > $dump"
assert_fail "$cli -n 501 < $datadir/1ubq.pdb > $dump"
echo
echo "== Testing L&R =="
assert_pass "$cli -L < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -L -d 0.1 < $datadir/1ubq.pdb > $dump"
assert_fail "$cli -L -d 0 < $datadir/1ubq.pdb > $dump"
echo
echo "== Testing B-factors =="
assert_pass "$cli -l -B < $datadir/1ubq.pdb > tmp/bfactor.pdb"
assert_pass "diff tmp/bfactor.pdb $datadir/1ubq.B.pdb"
assert_pass "$cli -l -Btmp/bfactor.pdb < $datadir/1ubq.pdb"
assert_pass "diff tmp/bfactor.pdb $datadir/1ubq.B.pdb"
echo
echo "== Testing probe radius =="
assert_fail "$cli -p -1 < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -p 1 < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -p 1.4 -Btmp/bfactor.pdb < $datadir/1ubq.pdb > $dump"
assert_pass "diff tmp/bfactor.pdb $datadir/1ubq.B.pdb"
echo
echo "== Testing option -r =="
assert_pass "$cli -l -r < $datadir/1ubq.pdb > tmp/restype"
assert_pass "diff tmp/restype $datadir/restype.reference"
assert_pass "$cli -l -rtmp/restype < $datadir/1ubq.pdb"
assert_pass "diff tmp/restype $datadir/restype.reference"
echo
echo "== Testing option -R =="
assert_pass "$cli -l -R < $datadir/1ubq.pdb > tmp/seq"
assert_pass "diff tmp/seq $datadir/seq.reference"
assert_pass "$cli -l -Rtmp/seq < $datadir/1ubq.pdb"
assert_pass "diff tmp/seq $datadir/seq.reference"
echo
echo "== Testing user-configurations =="
assert_pass "$cli -c $sharedir/naccess.config < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -c $sharedir/oons.config < $datadir/1ubq.pdb > $dump"
assert_fail "$cli -c $datadir/err.config < $datadir/1ubq.pdb > $dump"
echo
echo "== Testing multithreading =="
assert_pass "$cli -t 1 < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -t 2 < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -t 10 < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -t 1 -L < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -t 2 -L < $datadir/1ubq.pdb > $dump"
assert_pass "$cli -t 10 -L < $datadir/1ubq.pdb > $dump"
assert_fail "$cli -t 0 < $datadir/1ubq.pdb > $dump"
echo
echo "There where $errors errors."
echo
if [ $errors -gt 0 ]; then 
    exit $errors
else
    exit 0
fi
