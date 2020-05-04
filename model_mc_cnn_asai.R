# keras model MC - CNN (ASAI 2019)

default_keras_model_mc_cnn_asai_parameters_tune=list(
  nb_filter = c(256,128,64,32),
  kernel_size = c(16,8,4,2),
  embedingdim = c(128,50,32),
  hidden1_size= c(1024,512,256,128,64),
  hidden2_size= c(1024,512,256,128,64),
  hidden3_size= c(1024,512,256,128,64),
  dropout = c(0.5)
)



default_keras_model_mc_cnn_asai_parameters=list(
  embedingdim = 100,
  nb_filter = 512,
  kernel_size = 4,
  hidden1_size= 256,
  hidden2_size= 1024,
  hidden3_size= 256,
  dropout = 0.5
)


keras_model_mc_cnn_asai<-function(x,parameters=default_keras_model_mc_cnn_parameters){
  
  input_shape <- dim(x)[2]
  inputs<-layer_input(shape = input_shape) 
  
  embeding<- inputs %>% layer_embedding(length(valid_characters_vector), parameters$embedingdim , input_length = input_shape)
  
  mc_cnn <- embeding %>%

    layer_conv_1d(filters = parameters$nb_filter, kernel_size = parameters$kernel_size, activation = 'relu', padding='valid',strides=1) %>%
    layer_dropout(rate = parameters$dropout) %>%
    layer_flatten() %>%

    layer_dense(parameters$hidden1_size,activation='relu') %>%
    layer_dense(parameters$hidden2_size,activation='relu') %>%
    layer_dropout(rate = parameters$dropout) %>%
    layer_dense(parameters$hidden3_size,activation='relu') %>%
    layer_dense(3, activation = 'softmax')
  
  #compile model
  model_mc_cnn <- keras_model(inputs = inputs, outputs = mc_cnn)
  model_mc_cnn %>% compile(
    optimizer = 'adam',
    loss = 'sparse_categorical_crossentropy',
    metrics = c('accuracy')
  )
  return(model_mc_cnn)
}

funcs[["mc_cnn_asai"]]=keras_model_mc_cnn_asai
