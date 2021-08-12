# separate the Yawipa output file into separate files

out=$1
types=`cut $out -f 4 -d $'\t' | sort | uniq > types`
mkdir -p separate
for type in `cat types`
do
    grep -P "^[^\t]+\t[^\t]+\t[^\t]+\t$type\t" $out > separate/$type
done
find separate -size 0 -delete