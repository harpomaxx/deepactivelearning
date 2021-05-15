# Script for analizing different stratagies for dealing with imbalaced data
# 05/12/2021


source("create_csv.R")
source("preprocess.R")
source("build_model.R")
source("tune.R")


suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("caret"))
suppressPackageStartupMessages(library("e1071"))
suppressPackageStartupMessages(library("smotefamily"))

option_list <- list(
  # make_option("--generate", action="store_true",  help = "Generate train and test files", default=FALSE),
  make_option("--experimenttag", action="store", type="character", default="default-experiment", help = "Set experiment tag id "),
  make_option("--modelid", action="store", type="numeric", default=1, help = "Select between different models"),
  make_option("--list-available-models", action="store_true", help = "List different models", dest="list_models",default=FALSE),
  #make_option("--tune", action="store_true", help = "Tune the selected model",default=FALSE),
  #make_option("--testonly", action="store_true", help = "Bypass training and test with previous weights",default=FALSE),
  make_option("--maxlen", action="store", type="numeric", default=45, help = "Set the maximun length of the domain name considered"),
  #make_option("--modelfile", action="store", type="character", help = "A file to load model from"),
  make_option("--testfile", action="store", type="character", help = "A file to load test data from"),
  make_option("--trainfile", action="store", type="character", help = "A file to load test data from"),
  
  #make_option("--datafile", action="store", type="character", help = "A file to load dataset from", default = "ctu19subs.csv"),
  make_option("--upsample", action="store_true", help = "Apply oversampling to  train dataset",default=FALSE),
  make_option("--downsample", action="store_true", help = "Apply oversampling to  train dataset",default=FALSE),
  make_option("--augment", action="store_true", help = "Apply oversampling to  train dataset",default=FALSE)
  
  
)
opt <- parse_args(OptionParser(option_list=option_list))
source("config.R")
source("evaluate.R")

shifter <- function(x, n = 1) {
  if (n == 0) x else c(tail(x, -n), head(x, n))
}

augment_dataset <- function(dataset,n){
  aug_dataset<-c()
  #print(n)
  for (i in 1:n){
    k<- sample(1:ncol(dataset),1)
    j<- sample(1:nrow(dataset),1)
    ##print(k)
    #print(j)
    #print("--")
    
    #print(dataset[j,])
    #print(dataset[j,] %>% shifter(k))
    #print("--")
    # aug_dataset<-rbind(aug_dataset,dataset[j,] %>% apply( 1, function (x) x %>% unname()%>% shifter(k)) %>% t())
    aug_dataset<-rbind(aug_dataset,dataset[j,] %>%  shifter(k) )
    
    
  }
  aug_dataset
}

## MAIN Section   #####

maxlen=opt$maxlen         # the maximum length of the domain name considerd for input of the NN

if (opt$list_models){
  print (names(funcs))
  quit()
}

testset<-readr::read_csv(opt$testfile) %>% select(State,LabelName,source) %>% 
  mutate(class=ifelse(LabelName=="Botnet",1,0)) %>% mutate(label=source) %>% select(State,class,label)

trainset<-readr::read_csv(opt$trainfile) %>% select(State,LabelName,source) %>% 
  mutate(class=ifelse(LabelName=="Botnet",1,0)) %>% mutate(label=source) %>% select(State,class,label) 

#testset %>% group_by(class) %>% summarize(n=n())

if(!is.null(testset) & !is.null(trainset) ){
  message("[] Tokenizing testset")
  test_dataset_keras<-build_dataset(as.matrix(testset),opt$maxlen)
  
  if (opt$upsample == TRUE || opt$downsample == TRUE){
    message("[] Fixing imbalance trainset")
    if(opt$upsample == TRUE){
      message("[] Upsampling") 
      trainset<- caret::upSample(x=trainset[,c(1,3)], y=as.factor(trainset$class),list = F,yname = "class") 
    }else{
      message("[] Downsampling")
      trainset<- caret::downSample(x=trainset[,c(1,3)], y=as.factor(trainset$class),list = F,yname = "class") 
    }
    # trainset<- SMOTE(X=trainset[,c(1,3)], target=as.factor(trainset$class)) 
    trainset<-trainset[,c(1,3,2)]
    table(trainset)
    #print(trainset %>% head(5))
  }
  
  message("[] Tokenizing trainset")
  train_dataset_keras<-build_dataset(as.matrix(trainset),opt$maxlen)
  
  ### AUGMENTATION ###
  if (opt$augment == TRUE){
    
    message("[] Augmenting trainset")
    # Augment Normal
    selected_normal_examples<-which(train_dataset_keras$class==0)
    #print(train_dataset_keras$encode[selected_normal_examples,])
    trainset_augmented_examples_normal<-augment_dataset(
      train_dataset_keras$encode[selected_normal_examples,],
      (train_dataset_keras$encode %>% nrow())*5 - ((selected_normal_examples %>% length() )*1)
      #100
    )
    
    train_dataset_keras$encode<-rbind(train_dataset_keras$encode,trainset_augmented_examples_normal)
    train_dataset_keras$label<-c(train_dataset_keras$label, rep("augmented_Normal",trainset_augmented_examples_normal %>% nrow()))
    train_dataset_keras$class<-c(train_dataset_keras$class, rep(0,trainset_augmented_examples_normal %>% nrow()))
   # Augment Botnet
    selected_botnet_examples<-which(train_dataset_keras$class==1)
    selected_normal_examples<-which(train_dataset_keras$class==0)
    
    trainset_augmented_examples_botnet<-augment_dataset(
      train_dataset_keras$encode[selected_botnet_examples,],
      (selected_normal_examples %>% length() - selected_botnet_examples %>% length() )
      #100
    )
    train_dataset_keras$encode<-rbind(train_dataset_keras$encode,trainset_augmented_examples_botnet)
    train_dataset_keras$label<-c(train_dataset_keras$label, rep("augmented_Botnet",trainset_augmented_examples_botnet %>% nrow()))
    train_dataset_keras$class<-c(train_dataset_keras$class, rep(1,trainset_augmented_examples_botnet %>% nrow()))
    
    
 }  
 
  #### END AUGMENTATION ###
  
  message("[]",train_dataset_keras$encode %>% nrow())
  print(train_dataset_keras$label %>% table())
  print(train_dataset_keras$class %>% table())
  
  ### Train and test a model ####
  message("[] Creating model and evaluating model on test ")
  selected_parameters<- 
    eval(
      parse(
        text=paste("default_keras_model_",names(funcs)[opt$modelid],"_parameters",sep="") # TODO: verify existence
      )
    )
  
  results<-evaluate_model_train_test(train_dataset_keras,test_dataset_keras,modelfun=funcs[[opt$modelid]], selected_parameters,opt$experimentname)
  message("[] Saving results ")
  write_csv(results$result,col_names = T,path=paste(results_dir,"results_test_",opt$experimenttag,".csv",sep=""))
  write_csv(results$resultperclass,col_names = T,path=paste(results_dir,"results_per_subclass_test_",opt$experimenttag,".csv",sep=""))
  quit()
}