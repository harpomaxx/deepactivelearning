# keras model LSTM CUSTOM

default_keras_model_lstm_custom_parameters_tune=list(
  lstm_size = c(128,64,32),
  embedingdim = c(128,50,32),
  hidden_size= c(1024,512,256,128,64),
  dropout = c(0.5)
)

#default_keras_model_cnn_argencon_parameters_tune=list(
#  nb_filter = c(256,128),
#  kernel_size = c(8),
#  embedingdim = c(100),
#  hidden_size = c(1024)
#)



default_keras_model_lstm_custom_parameters=list(
  embedingdim = 128,
  lstm_size = 128,
  hidden_size= 1024,
  dropout = 0.5
)


keras_model_lstm_custom<-function(x,parameters=default_keras_model_lstm_custom_parameters){
  
  input_shape <- dim(x)[2]
  inputs<-layer_input(shape = input_shape) 
  
  embeding<- inputs %>% layer_embedding(length(valid_characters_vector), parameters$embedingdim , 
                                        input_length = input_shape, mask_zero = T)
  
  lstm <- embeding %>%
    layer_lstm(units = parameters$lstm_size) %>%
    layer_dropout(rate = parameters$dropout) %>%
    layer_dense(parameters$hidden_size,activation='relu') %>%
    layer_dense(1, activation = 'sigmoid')
  
  #compile model
  model_custom <- keras_model(inputs = inputs, outputs = lstm)
  model_custom %>% compile(
    optimizer = 'rmsprop',
    loss = 'binary_crossentropy',
    metrics = c('accuracy')
  )
  return(model_custom)
}

funcs[["lstm_custom"]]=keras_model_lstm_custom
