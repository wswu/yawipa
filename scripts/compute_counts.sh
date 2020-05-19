outfile=$1

cut -f3 $outfile | sort | uniq -c | sort -n -r > extr.counts

grep -P "\tetym\t" $outfile > etym.out
sort -u etym.out > etym.sorted
cut -f5 etym.sorted | sort | uniq -c | sort -n -r > etym.counts

grep -P "\tformof\t" $outfile > formof.out
sort -u formof.out > formof.sorted
cut -f4 formof.sorted | sort | uniq -c | sort -n -r > formof.counts