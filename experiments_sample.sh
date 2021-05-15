for i in `seq 1 30` ; do Rscript deepseq_jaiio2021.R --trainfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-train-augmentedx2-$i.csv"  --testfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-test-$i.csv" --modelid=3 --experimenttag="imbalance-sample20-augment-dataset-2x-epochs=60-endgame-maxlen=200-$i" --maxlen=200 ; done

#for i in `seq 1 30` ; do Rscript deepseq_jaiio2021.R --trainfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-train-$i.csv"  --testfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-test-$i.csv" --modelid=3 --experimenttag="imbalance-sample20-upsample-botnet-epochs=60-endgame-maxlen=200-$i" --maxlen=200 --upsample; done

#for i in `seq 1 30` ; do Rscript deepseq_jaiio2021.R --trainfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-train-$i.csv"  --testfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-test-$i.csv" --modelid=3 --experimenttag="imbalance-sample20-downsample-botnet-epochs=60-endgame-maxlen=200-$i" --maxlen=200 --downsample; done
