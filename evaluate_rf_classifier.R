library(dplyr)
library(randomForest)
library(readr)
library(tibble)
library(stringr)
suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("caret"))
suppressPackageStartupMessages(library("e1071"))

vectorize_seq <-function(dataset,maxlen){
#dataset_vectorized <- as.data.frame(as.character(dataset),stringsAsFactors=FALSE)
#names(dataset_vectorized)<-c("State")
dataset_vectorized <-as.tibble(dataset)
dataset_vectorized<- dataset_vectorized %>% mutate(modelsize=str_count(State,"."))
dataset_vectorized$State <- dataset_vectorized$State %>% substr(1,maxlen)
dataset_vectorized<-dataset_vectorized %>% mutate(modelsize=nchar(State))
#Periodicity
dataset_vectorized = dataset_vectorized %>% mutate(strong_p = str_count(State,'[a-i]'))
dataset_vectorized = dataset_vectorized %>% mutate(weak_p = str_count(State,'[A-I]'))
dataset_vectorized = dataset_vectorized %>% mutate(weak_np = str_count(State,'[r-z]'))
dataset_vectorized = dataset_vectorized %>% mutate(strong_np = str_count(State,'[R-Z]'))
#Duration
dataset_vectorized = dataset_vectorized %>% mutate(duration_s = str_count(State,'(a|A|r|R|1|d|D|u|U|4|g|G|x|X|7)'))
dataset_vectorized = dataset_vectorized %>% mutate(duration_m = str_count(State,'(b|B|s|S|2|e|E|v|V|5|h|H|y|Y|8)'))
dataset_vectorized = dataset_vectorized %>% mutate(duration_l = str_count(State,'(c|C|t|T|3|f|F|w|W|6|i|I|z|Z|9)'))
#Size
dataset_vectorized = dataset_vectorized %>% mutate(size_s = str_count(State,'[a-c]') + str_count(State,'[A-C]') + str_count(State,'[r-t]') + str_count(State,'[R-T]') + str_count(State,'[1-3]'))
dataset_vectorized = dataset_vectorized %>% mutate(size_m = str_count(State,'[d-f]') + str_count(State,'[D-F]') + str_count(State,'[u-w]') + str_count(State,'[U-W]') + str_count(State,'[4-6]'))
dataset_vectorized = dataset_vectorized %>% mutate(size_l = str_count(State,'[g-i]') + str_count(State,'[G-I]') + str_count(State,'[x-z]') + str_count(State,'[X-Z]') + str_count(State,'[7-9]'))

#Periodicity %
dataset_vectorized <- dataset_vectorized %>% mutate(strong_p = (strong_p / modelsize))
dataset_vectorized <- dataset_vectorized %>% mutate(weak_p = (weak_p / modelsize))
dataset_vectorized <- dataset_vectorized %>% mutate(strong_np = (strong_np / modelsize))
dataset_vectorized <- dataset_vectorized %>% mutate(weak_np = (weak_np / modelsize))
#Duration %
dataset_vectorized <- dataset_vectorized %>% mutate(duration_s = (duration_s / modelsize))
dataset_vectorized <- dataset_vectorized %>% mutate(duration_m = (duration_m / modelsize))
dataset_vectorized <- dataset_vectorized %>% mutate(duration_l = (duration_l / modelsize))
#Size %
dataset_vectorized <- dataset_vectorized %>% mutate(size_s = (size_s / modelsize))
dataset_vectorized <- dataset_vectorized %>% mutate(size_m = (size_m / modelsize))
dataset_vectorized <- dataset_vectorized %>% mutate(size_l = (size_l / modelsize))

#Making feature vectors
dataset_vectorized <- dataset_vectorized %>% select('strong_p','weak_p','weak_np','strong_np','duration_s',
                                                    'duration_m','duration_l','size_s','size_m','size_l','modelsize','class')

names(dataset_vectorized) <- c("sp","wp","wnp","snp","ds","dm","dl","ss","sm","sl","modelsize",'label')


dataset_vectorized<-dataset_vectorized %>% mutate(class=ifelse(grepl(pattern = "Normal", x = label),0,1))
dataset_vectorized$class<-as.factor(dataset_vectorized$class)
dataset_vectorized %>% group_by(class) %>% summarize(tot=n())
dataset_vectorized
}

train_test_sample<-function(x,percent=0.7){
  smp_size <- floor(percent * nrow(x))
  train_ind <- sample(seq_len(nrow(x)), size = smp_size)
  return (train_ind)
}

### Function Definitions ####
get_predictions <- function(model, test_dataset_x,threshold=0.5) {
  predsprobs<- predict(model,test_dataset_x,type='prob')
  preds<-ifelse(predsprobs[,1]>0.5,0,1)
  return (preds)
}

calculate_recall <-function(dataset){
  recall<-dataset %>% group_by(label) %>% summarise(recall=sum(predicted_class==class)/n(),support=n()) 
  return(recall)
}

evaluate_model_test <- function(model, test_dataset_x, test_dataset_y, original_labels) {
  preds<-get_predictions(model,test_dataset_x)
  confmatrix<-confusionMatrix(data= as.factor(preds),reference = as.factor(test_dataset_y),positive = '1', mode="everything")
  print(confmatrix)
  result<-cbind(value=as.data.frame(confmatrix$byClass) %>% rownames_to_column())
  recall<-calculate_recall(data.frame(label=original_labels, class=test_dataset_y,predicted_class=preds))
  result_per_subclass<-cbind(recall)
  names(result)<-c("metric","value")
  return (list(result=result, resultperclass=result_per_subclass))
}

#### MAIN 

option_list <- list(
  make_option("--experimenttag", action="store", type="character", default="default-experiment", help = "Set experiment tag id "),
  make_option("--maxlen", action="store", type="numeric", default=45, help = "Set the maximun length of the seq  considered")
)
opt <- parse_args(OptionParser(option_list=option_list))



datasetfile="./datasets/ctu13subs75.csv"
results_dir='./results/'





dataset<-read_delim(datasetfile,delim = ",")
dindex<-train_test_sample(dataset,0.7)
train_dataset<-dataset[dindex,]
test_dataset<-dataset[-dindex,]

dataset_train_vectorized<-vectorize_seq(train_dataset,opt$maxlen)
dataset_test_vectorized<-vectorize_seq(test_dataset,opt$maxlen)
print("[] Creating model and evaluating model on test ")
rfModel<-randomForest(x= dataset_train_vectorized %>% select(-modelsize,-label,-class),y=dataset_train_vectorized$class,mtry = 2)

#rfpreds<-predict(rfModel,dataset_test_vectorized %>% select(-modelsize,-label,-class), type="prob")
#confusionMatrix(reference = as.factor(dataset_test_vectorized$class),data=as.factor(ifelse(rfpreds[,1]>0.5,0,1)),positive = "1", mode="everything" )
#print("****-----****")
results<-evaluate_model_test(rfModel,test_dataset_x = dataset_test_vectorized %>% select(-modelsize,-label,-class),
                             test_dataset_y = dataset_test_vectorized$class,original_labels = dataset_test_vectorized$label)

print("[] Saving results ")
write_csv(results$result,col_names = T,path=paste(results_dir,"results_test_",opt$experimenttag,".csv",sep=""))
write_csv(results$resultperclass,col_names = T,path=paste(results_dir,"results_per_subclass_test_",opt$experimenttag,".csv",sep=""))
