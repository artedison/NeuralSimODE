rm(list=ls())
options(warn=1)
options(stringsAsFactors=FALSE)
options(digits=15)
require(stringr)
require(magrittr)
require(R.matlab)
require(ggplot2)
require(xml2)
# require(cowplot)
require(scales)
# require(lhs)
require(foreach)
require(doMC)
require(readr)
require(abind)
dir=""
shelltempt=c(paste0(dir,"resnet_full.sh"),paste0(dir,"resnet_eigenval.sh"))
# nrow=9
infortab=read.table(file="submitlist.tab",sep="\t",header=TRUE)
infortab[which(is.na(infortab[,"addon"])),"addon"]=""
# write.table(training.para.dataframe,sep="\t",file="/Users/mikeaalv/Dropbox (Edison_Lab@UGA)/Projects/Bioinformatics_modeling/nc_model/nnt/model_training/trainsele.tab")
# seqdir=1:nrow(infortab)
seqdir=1:21
colnam=colnames(infortab)
for(irow in seqdir){
  infor=infortab[irow,]
  system(paste0("mkdir ",irow))
  setwd(paste0("./",irow))
  system(paste0("cp ../*.R ."))
  system(paste0("cp ../*.sh ."))
  system(paste0("cp ../*.py ."))
  # if(infor[,"input_vector"]=="H, Yini, t"){
  #   shellscript=shelltempt[1]
  #   addstri="_full"
  # }else if(infor[,"input_vector"]=="D, Yini, t"){
  #   shellscript=shelltempt[2]
  #   addstri="_eigenval"
  # }
  shellscript=shelltempt[1]
  addstri="_full"
  normalize_flag_str=""
  batchnorm_flag_str=""
  if("addon"%in%colnam && str_detect(string=infor[,"addon"],pattern="No_input_normalization")){
    normalize_flag_str=paste0("--normalize-flag N")
  }
  if("addon"%in%colnam && str_detect(string=infor[,"addon"],pattern="No_batch_normliaztion")){
    batchnorm_flag_str=paste0("--batchnorm-flag N")
  }
  dropout_rate=0.0
  if("addon"%in%colnam && str_detect(string=infor[,"addon"],pattern="^dp")){
    infor[,"addon"] %>% str_replace_all(string=.,pattern="^dp",replacement="") %>%
                        str_replace_all(string=.,pattern="\\s+.+$",replacement="") -> dropout_rate
  }
  if("addon"%in%colnam && str_detect(string=infor[,"addon"],pattern="^scheduler")){
    infor[,"addon"] %>% str_replace_all(string=.,pattern="^scheduler\\_",replacement="") %>%
                        str_replace_all(string=.,pattern="\\s+.+$",replacement="") -> scheduler
  }
  sampler="block"
  if("addon"%in%colnam && str_detect(string=infor[,"addon"],pattern="randomsamp")){
    sampler="individual"
  }
  rnnadd=""
  if(str_detect(string=infor[,"net_struct"],pattern="\\_rnn")){
    rnnadd="--rnn-struct 1"
  }
  lines=readLines(shellscript)
  chline_ind=str_which(string=lines,pattern="^time")
  lineend=str_extract_all(string=lines[chline_ind],pattern="\\w+>>.*$")[[1]]
  lines[chline_ind]=paste(paste0("time python3 train_mlp",addstri,"_modified.py "),
              "--batch-size",format(infor[,"batch_size"],scientific=FALSE),
              "--test-batch-size",format(infor[,"test_batch_size"],scientific=FALSE),
              "--epochs",infor[,"epochs"],
              "--learning-rate",infor[,"learning_rate"],
              "--seed",infor[,"random_seed"],
              "--net-struct",infor[,"net_struct"],
              "--layersize-ratio",infor[,"layersize_ratio"],
              "--optimizer",infor[,"optimizer"],
              normalize_flag_str,batchnorm_flag_str,
              "--num-layer",infor[,"nlayer"],
              "--inputfile",infor[,"inputfile"],
              "--p",dropout_rate,
              "--scheduler",scheduler,
              "--lr-print 1",
              "--sampler ",sampler,
              "--timeshift-transformp ",infor[,"timeshift_p"],
              "--linearcomb-transformp",infor[,"lincomb_p"],
              rnnadd,
              lineend,
              sep=" "
            )
  newfile=paste0(str_replace(string=shellscript,pattern="\\.sh",replacement=""),infor[1],".sh")
  cat(lines,file=newfile,sep="\n")
  submitcommand=paste0("qsub ",newfile)
  print(submitcommand)
  system(submitcommand)
  setwd("../")
}
