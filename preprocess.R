library(keras)
library(purrr)

#valid_characters <- "$abcdefghijklmnopqrstuvwxyz0123456789-_.ABCDEFGHIJKLMNOPQRSTUVWXYZ+*,\""
valid_characters <- "$abcdefghiABCDEFGHIrstuvwxyzRSTUVWXYZ0123456789.,+*"
valid_characters_vector <- strsplit(valid_characters,split="")[[1]]
tokens <- 0:length(valid_characters_vector)
names(tokens) <- valid_characters_vector


pad_sequences_fast <- function(x, maxlen, padding="pre", truncating ="pre", value=0){
  x %>%
    map(function(x){
      if(length(x) > maxlen){
        if(truncating == "pre"){
          x[(length(x)-(maxlen)+1):length(x)]
        } else if(truncating == "post") {
          x[1:maxlen]
        } else {
          stop("Invalid value for 'truncating'")
        }
      } else {
        if(padding == "pre"){
          c(rep(value, maxlen-length(x)),x)
        } else if(padding == "post"){
          c(x,rep(value, maxlen-length(x)))
        } else {
          stop("Invalid value for 'padding'")
        }
      }
    }) %>%
    do.call(c,.) %>%
    unlist() %>%
    matrix(ncol=maxlen,byrow=TRUE)
}

# convert dataset to matrix of tokens  
tokenize <- function(data,labels,maxlen){
  #string_char_vector <- strsplit(string,split="")[[1]]
  print("tokenize")
  #x_data <- sapply( lapply(data,function(x) strsplit(x,split="")), function(x) lapply(x[[1]], function(x) {tokens[[x]] }))
  
  sequencel<-sapply(data,function(x)  strsplit(x,split=""))
  x_data <- lapply(sequencel,function(x) sapply(x,function(x) tokens[[x]]))
  
  
  print("padding")
  padded_token<-pad_sequences_fast(unname(x_data),maxlen=maxlen,padding='post', truncating='post')

  return (list(encode=padded_token,domain=data, label=labels))
  
} 
# convert vector with char tokens to one-hot encodings
to_onehot <- function(data,shape){
  train <- array(0,dim=c(shape[1],shape[2],shape[3]))
  for (i in 1:shape[1]){
    for (j in 1:shape[2])
      train[i,j,data[i,j]] <- 1
  }
  return (train)
}

# Create a dataset using tokenizer 
build_dataset<- function(data,maxlen){
  dataset<-tokenize(data[,1],data[,2],maxlen)
  shape=c(nrow(dataset$encode),maxlen,length(valid_characters_vector))
  #dataset$encode<-to_onehot(dataset$encode,shape)
  return(dataset)
}

train_test_sample<-function(x,percent=0.7){
  smp_size <- floor(percent * nrow(x))
  train_ind <- sample(seq_len(nrow(x)), size = smp_size)
  return (train_ind)
}

build_train_test<-function(datasetfile,maxlen, upsample = FALSE){
  dataset<-read_delim(datasetfile,delim = ",")
  #dataset$domain1<-str_split(dataset$domain,"\\.",simplify = T)[,1]
  dindex<-train_test_sample(dataset,0.7)
  train_dataset<-dataset[dindex,]
  test_dataset<-dataset[-dindex,]
  if (upsample){
    train_dataset<-train_dataset %>% mutate(label=ifelse(grepl("Normal",train_dataset$class) ,"Normal","Botnet"))
    train_dataset<- caret::upSample(x=train_dataset[,1], y=as.factor(train_dataset$label),list = F,yname = "class")
  }
  # Dataset transformation usually requires a lot of time. Some sort of caching needed
  train_dataset_keras<-build_dataset(as.matrix(train_dataset),maxlen)
  save(train_dataset_keras,file = "datasets/.train_dataset_keras.rd")
  test_dataset_keras<-build_dataset(as.matrix(test_dataset),maxlen)
  save(test_dataset_keras,file = "datasets/.test_dataset_keras.rd")
  return(list(train=train_dataset_keras,test=test_dataset_keras))
}
