# keras model used in ENDGAME LSTM 2016 paper

default_keras_model_dense_endgame_parameters_tune=list(
  dense_size = c(128,64,32),
  embedingdim = c(128,50,32),
  dropout = c(0.5)
)

#default_keras_model_cnn_argencon_parameters_tune=list(
#  nb_filter = c(256,128),
#  kernel_size = c(8),
#  embedingdim = c(100),
#  hidden_size = c(1024)
#)



default_keras_model_dense_endgame_parameters=list(
  embedingdim = 128,
  dense_size = 5100,
  dense_size2 = 512,
  dense_size3 = 1024,
  dropout = 0.5
)


keras_model_dense_endgame<-function(x,parameters=default_keras_model_dense_endgame_parameters){
  
  input_shape <- dim(x)[2]
  inputs<-layer_input(shape = input_shape) 
  
  embeding<- inputs %>% layer_embedding(length(valid_characters_vector), parameters$embedingdim , input_length = input_shape)
  
  dense <- embeding %>%
    layer_flatten() %>%
    layer_dense(units = parameters$dense_size) %>%
   # layer_dense(units = parameters$dense_size2) %>%
   # layer_dense(units = parameters$dense_size3) %>%
    layer_dropout(rate = parameters$dropout) %>%
    layer_dense(1, activation = 'sigmoid')
  
  #compile model
  model_endgame <- keras_model(inputs = inputs, outputs = dense)
  model_endgame %>% compile(
    optimizer = 'adam',
    loss = 'binary_crossentropy',
    metrics = c('accuracy')
  )
  summary(model_endgame)
  return(model_endgame)
}

funcs[["dense_endgame"]]=keras_model_dense_endgame
