#!/bin/bash
for max in `echo 10 20 40 80 100 200 400 800 1000`
	do for a in `seq 1 10` 
		do 
			experiment="ctu19-lstm_endgame_bi_recurrent_drop-upsample"
			echo  "======= $experiment-$max-$a ======="
			Rscript evaluate_dga_classifier.R --experimenttag=$experiment-$max-$a --modelid=9 --generate --maxlen=$max --upsample
			echo  "======= $experiment-cswitch_ctu13-$max-$a ======="
			Rscript evaluate_dga_classifier.R --experimenttag=$experiment-cswitch_ctu13-$max-$a --maxlen=$max --modelfile=$experiment-$max-$a\_model.h5 --testonly --testfile=datasets/ctu13subs.csv
	done
done
