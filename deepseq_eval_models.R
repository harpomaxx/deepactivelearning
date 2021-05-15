#
#
#
setwd("/home/gab/deepseq/")
source("create_csv.R")
source("preprocess.R")
source("build_model.R")
source("tune.R")


suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("caret"))
suppressPackageStartupMessages(library("e1071"))
suppressPackageStartupMessages(library("purrr"))
option_list <- list(
  make_option("--experimenttag", action="store", type="character", default="default-experiment", help = "Set experiment tag id "),
  make_option("--modelid", action="store", type="numeric", default=1, help = "Select between different models"),
  make_option("--list-available-models", action="store_true", help = "List different models", dest="list_models",default=FALSE),
  make_option("--maxlen", action="store", type="numeric", default=45, help = "Set the maximun length of the domain name considered"),
  make_option("--testfile", action="store", type="character", help = "A file to load test data from"),
  make_option("--trainfile", action="store", type="character", help = "A file to load train data from")
  
)
opt <- parse_args(OptionParser(option_list=option_list))
source("config.R")
source("evaluate.R")

## MAIN Section   #####

# tensorflow session setup


maxlen=opt$maxlen         # the maximum length of the domain name considerd for input of the NN
print(opt$experimenttag)
if (opt$list_models) {
  print (names(funcs))
  quit()
}

testset<-readr::read_csv(opt$testfile,col_types = cols()) %>% select(State, LabelName, source) %>%
  mutate(class = ifelse(LabelName == "Botnet", 1, 0)) %>% mutate(label =
                                                                   source) %>% select(State, class, label)

trainset<-readr::read_csv(opt$trainfile,col_types = cols()) %>% select(State, LabelName, source) %>%
  mutate(class = ifelse(LabelName == "Botnet", 1, 0)) %>% mutate(label =
                                                                   source) %>% select(State, class, label)

if(!is.null(testset) & !is.null(trainset) ){
  message("[] Tokenizing datasets")
  train_dataset_keras<-build_dataset(as.matrix(trainset),opt$maxlen)
  test_dataset_keras<-build_dataset(as.matrix(testset),opt$maxlen)
  
  message("[]",train_dataset_keras$encode %>% nrow())
  #print(train_dataset_keras$label %>% table())
  #print(train_dataset_keras$class %>% table())
  
  ### Train and test a model ####
  message("[] Creating model and evaluating model on test.")
  
  models_results<-c()
  parameters_combinations <- expand.grid(eval(parse(
    text = paste(
      "default_keras_model_",
      names(funcs)[opt$modelid],
      "_parameters_tune",
      sep = ""
    ) # TODO: verify existence
  )))
  #print(parameters_combinations)
  
   for (i in 1:nrow(parameters_combinations)) {
   #for (i in c(4,1)) {
      
    selected_parameters <- parameters_combinations[i, ]
    print(selected_parameters)
    
    results <-
      evaluate_model_train_test(
        train_dataset_keras,
        test_dataset_keras,
        modelfun = funcs[[opt$modelid]],
        selected_parameters,
        opt$experimentname
      )
    
    message("[] Saving results ")
    selected_parameters_collapsed <-
      purrr::map2(selected_parameters, names(selected_parameters), function(x, y)
        paste0(y, "=", x)) %>% unlist() %>% paste(collapse = "-")
    write_csv(
      results$result,
      col_names = T,
      path = paste(
        results_dir,
        "results_test_",
        opt$experimenttag,"-",
        selected_parameters_collapsed,
        ".csv",
        sep = ""
      )
    )
    write_csv(
      results$resultperclass,
      col_names = T,
      path = paste(
        results_dir,
        "results_per_subclass_test_",
        opt$experimenttag,"-",
        selected_parameters_collapsed,
        ".csv",
        sep = ""
      )
    )
    write_csv(
      results$history %>% as.data.frame(),
      col_names = T,
      path = paste(
        results_dir,
        "results_history_test_",
        opt$experimenttag,"-",
        selected_parameters_collapsed,
        ".csv",
        sep = ""
      )
    )
  gc()
  }
}