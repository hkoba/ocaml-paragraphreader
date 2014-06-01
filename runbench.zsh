#!/bin/zsh

set -eu
setopt extendedglob
unsetopt multios

function die { echo 1>&2 $*; exit 1 }

(($+commands[corebuild])) || die "Can't find corebuild, stopped."

zparseopts -D -K o:=o_outdir

progname=$0
bindir=$(cd $0:h && print $PWD)

cd $bindir

testname=paracount

ref_prog=${testname}0.pl
gen_prog=$bindir/para-gen.pl

ml_src=(
    ${testname}<1->.ml
)

ml_exe=(
    $^ml_src(:s/.ml/.native/)
)

for exe in $ml_exe; do
    [[ -x $exe ]] && continue
    echo Building $exe...
    corebuild $exe
    echo
done

#
# Since testdata is large, I want to reuse it if available.
#

if (($#o_outdir)); then
    testdata=$o_outdir[2]
else
    testdata=$bindir/_testdata
fi

mkdir -p $testdata

inputs=()
function ensure_input {
    local fn=$testdata/${(j/-/)argv}.in
    [[ -r $fn ]] || {
	echo Generating testdata $fn with params: $line
	$gen_prog $argv > $fn || { rm -f $fn; exit 1 }
    }
    inputs+=($fn)
}

input_param_file=""
function load_input_params {
    [[ -r $1 ]] || die "input param $1 is not readable!"
    input_param_file=$1
    local line
    while IFS=$'\t' read -A line; do
	[[ $line[1] = [0-9]* ]] || continue
	ensure_input $line
    done < $1
}

if ! ((ARGC)); then
    load_input_params testparams.txt
elif [[ -r $1 ]]; then
    load_input_params $1
else
    ensure_input $argv
fi

function time_avg {
     perl -nle 'm{ ([\d\.]+) total$} or die "?? $_";
     $sum += $1;
     printf "AVG(total)\t%.3g\n", $sum/$. and do {$sum = 0; close ARGV} if eof
     ' $argv
}

#
# Now run benchmarks and collect data.
#
all_exe=($ref_prog $ml_exe)

echo inputs=$inputs

outputs=()
for fn in $inputs; do
    echo For input $fn
    for exe in $all_exe; do
	tnum=${${exe:r}##${~testname}} || true
	print prog number: $tnum
	outfn=$testdata/$fn:t..prog$tnum.out
	print outfn=$outfn
	outputs+=($outfn)
	rm -f $outfn
	for ((i=0; i < 3; i++)); do
	    (time ({ $bindir/$exe $fn 2>&3 })) 3>&2 2>>$outfn
	done
	cat $outfn
	time_avg $outfn | read line
	print $line |tee -a $outfn
	echo
    done
done

function tsv {
    print -- ${(j/\t/)argv}
}

if [[ -n $input_param_file ]]; then
    outfn=$input_param_file:r.result
    {
	for fn in $outputs; do
	    grep '^AVG' $fn | IFS=$'\t' read -A line
	    tsv $fn:t $line[2]
	done
    } > $outfn
fi
