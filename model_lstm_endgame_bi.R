# keras model used in ENDGAME LSTM 2016 paper + BI directional
default_keras_model_lstm_endgame_bidirectional_parameters_tune=list(
  lstm_size = c(128,64,32),
  embedingdim = c(128,50,32),
  dropout = c(0.5)
)

#default_keras_model_cnn_argencon_parameters_tune=list(
#  nb_filter = c(256,128),
#  kernel_size = c(8),
#  embedingdim = c(100),
#  hidden_size = c(1024)
#)



default_keras_model_lstm_endgame_bidirectional_parameters=list(
  embedingdim = 128,
  lstm_size = 128,
  dropout = 0.5
)


keras_model_lstm_endgame_bidirectional<-function(x,parameters=default_keras_model_lstm_endgame_bidirectional_parameters){
  
  input_shape <- dim(x)[2]
  inputs<-layer_input(shape = input_shape) 
  
  embeding<- inputs %>% layer_embedding(length(valid_characters_vector), parameters$embedingdim , input_length = input_shape,mask_zero=T)
  
  lstm <- embeding %>%
    bidirectional(layer_lstm(units = parameters$lstm_size,recurrent_dropout = parameters$dropout)) %>%
  
    #layer_dropout(rate = parameters$dropout) %>%
    layer_dense(1, activation = 'sigmoid')
  
  #compile model
  model_endgame_bidirectional <- keras_model(inputs = inputs, outputs = lstm)
  model_endgame_bidirectional %>% compile(
    optimizer = 'rmsprop',
    loss = 'binary_crossentropy',
    metrics = c('accuracy')
  )
  summary(model_endgame_bidirectional)
  return(model_endgame_bidirectional)
}

funcs[["lstm_endgame_bidirectional"]]=keras_model_lstm_endgame_bidirectional
