TF_CPP_MIN_LOG_LEVEL="3"
TF_FORCE_GPU_ALLOW_GROWTH="true"
CUDA_VISIBLE_DEVICES="0"

#for i in `seq 1 10` ; do Rscript deepseq_eval_models.R --trainfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-train-augmentedx2-$i.csv"  --testfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-test-$i.csv" --modelid=3 --experimenttag="lstm-endgame-augmented-ctu19-mccv-epochs=15-endgame-maxlen=1000-$i" --maxlen=1000 ; done

for i in `seq 1 10` ; do Rscript deepseq_eval_models.R --trainfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-train-augmentedx2-$i.csv"  --testfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-test-$i.csv" --modelid=1 --experimenttag="cnn1d-cacic-augmented-ctu19-mccv-epochs=15-endgame-batch=512-maxlen=1000-$i" --maxlen=1000 ; done

#for i in `seq 1 10` ; do Rscript deepseq_eval_models.R --trainfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-train-augmentedx2-$i.csv"  --testfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-test-$i.csv" --modelid=1 --experimenttag="cnn1d-cacic-augmented-ctu19-mccv-epochs=15-endgame-maxlen=1000-$i" --maxlen=1000 ; done

#for i in `seq 1 10` ; do Rscript deepseq_jaiio2021.R --trainfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-train-augmentedx2-$i.csv"  --testfile="../dga-wb-r/datasets/samples/sample20-CTU19A-mc-test-$i.csv" --modelid=3 --experimenttag="lstm-endgame-augmented-ctu19-mccv-epochs=60-endgame-maxlen=1000-$i" --maxlen=1000 ; done
#