library(keras)
funcs<-list()
#source(list.files(pattern = "model_.*.R"))
source("model_cnn_argencon.R")#1
source("model_cnn_pablo.R") 
source("model_lstm_endgame.R")
source("model_lstm_custom.R")
source("model_mc_cnn_asai.R") #5
source("model_dense.R")
source("model_lstm_endgame_norm.R")
source("model_lstm_endgame_bi.R")
source("model_lstm_endgame_recurrent_dropout.R")

# list for selecting between different models
#funcs<-list( cnn_argencon=keras_model_cnn_argencon,
#              cnn_pablo=keras_model_cnn_pablo,
#              lstm_endgame=keras_model_lstm_endgame
#             )


# Train model
train_model <- function(x,y, model,ep=10,modelname="model"){
  history<-model %>% fit(x,y,epochs = ep, batch_size = 256, validation_split = 0.2,verbose = 2)
 # model %>% save_model_hdf5(paste(modelname,".h5",sep=""))
  return(list(model=model,history=history))
}

