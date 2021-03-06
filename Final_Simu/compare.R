library(rpart)
library(randomForest)
library(BMA)
library(leaps)
library(BoomSpikeSlab)
library(SIS)
 
n=100
m_X<-5
m_W<-1
m_G<-50
m_I<-m_G
SNR<-10
tau1<-1

#### Iteration
treerst<-list()
bicrst<-list()
steprst<-list()
glassorst<-list()
lassorst<-list()
sisrst<-list()
 
for(i in 1:100){
  print(i)
  #Set Seed
  set.seed(i+1000)
 
  # Generate X and Y
  sigma<-cov_block(m_G,.3,5)
  #sigma<-GenerateCliquesCovariance(10,10,0.8)
  #binprob<-runif(m_G)
  x<-sim_X(m_X,m_W,m_G,sigma,n)
  #beta<-sim_beta(m_X=0,m_W=1,m_G,main_nonzero=0.05,inter_nonzero=0.05,both_nonzero=0.1,bit=T,heir=T)
  beta<-sim_beta_const(m_X,m_W=1,m_G,main_nonzero=0.1,inter_nonzero=0.1,both_nonzero=0.01,const=c(3,5),heir=TRUE)
  y0<-x%*%beta
 
  
  noise<-rnorm(n,sd=1)
  SNRmtl <- as.numeric(sqrt(var(y0)/(SNR*var(noise))))
  y<-y0+SNRmtl*noise 
  colnames(x)<-c(1:dim(x)[2])
  truth<-which(beta!=0)
 
#   simu<-data.frame(X=x,Y=y)
#   L<-lm(y~x[,c(1:(m_X+m_W))])
#   y.res<-L$residuals
#   simu$Y<-y.res
#   simu<-simu[,-c(1:(m_X+m_W))]
#  
#   ### Trees
#   model <- randomForest(Y~.,   data=simu)
#   #print(model) # view results
#   #importance(model)
#   treerst[[i]]<-order(importance(model),decreasing = T)[1:(length(truth)-m_X-m_W)]
#  
#   ### BMA
#   bicfit<-bicreg(x[,-c(1:(m_X+m_W))],y.res,strict = T)
#   bicrst[[i]]<-bicfit$namesx[order(bicfit$probne0,decreasing = T)][1:length(truth)]
#   bicrst[[i]]<-sapply(bicrst[[i]],function(x) strsplit(x,"X")[[1]][2])
#   bicrst[[i]]<-as.integer(bicrst[[i]])
#  
  ### Stepwise
  a<-regsubsets(x=x,y=y,method="forward",nvmax = 3*length(truth),force.in = c(1:(m_X+m_W)))
  steprst[[i]]<-a$vorder[-1][1:(length(truth))]-1
  #steprst[[i]]<-steprst[order(steprst[[i]])][[1]]
 
  
  x0<-rep(0,dim(x)[2])
  ### Group Lasso
  lamb_opt_glasso<-15
  lamb_opt2_glasso<-1
  solg<-FASTA(x,y,f, gradf, g, proxg, x0, tau1, max_iters = 300, w = 10,
              backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5,
              eps_n = 1e-15,m_X,m_W,m_G,m_G,lamb_opt_glasso,lamb_opt2_glasso,restart=TRUE)
  glassorst[[i]]<-order(abs(solg$x[-c(1:(m_W+m_X))]),decreasing = T)[1:(length(truth)-m_X-m_W)]+m_X+m_W
  
  ### Regular Lasso
  lamb_opt_lasso<-150
  lamb_opt2_lasso<-5
  sol<-FASTA(x,y,f, gradf, glasso, proxglasso, x0, tau1, max_iters = 300, w = 10,
             backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5,
             eps_n = 1e-15,m_X,m_W,m_G,m_G,lamb_opt_lasso,lamb_opt2_lasso,restart=TRUE)
  lassorst[[i]]<-order(abs(sol$x[-c(1:(m_W+m_X))]),decreasing = T)[1:(length(truth)-m_X-m_W)]+m_X+m_W
  
#   ### SIS
#   #model1<-SIS(x,y,family = "gaussian", penalty = "lasso", tune="bic")
#   model2<-SIS(x,y,family = "gaussian", penalty = "lasso", tune="bic",varISIS = "aggr")
#   sisrst[[i]]<-model2$ix
}
 
 
#save(truth,"C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//30//truth.RData")
# save(bicrst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//bicrst.RData")
save(steprst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//steprst.RData")
save(treerst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//treerst.RData")
save(glassorst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//glassorst.RData")
save(lassorst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//lassorst.RData")
# save(sisrst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//sisrst.RData")
 
 
#
# #### Trees
# model <- rpart(Y~ ., data = simu)
# par(xpd = NA) # otherwise on some devices the text is clipped
# plot(model)
# text(model, digits = 3)
# print(model, digits = 2)
# rsq.rpart(model)
#
#
# model <- randomForest(Y~.,   data=simu)
# #print(model) # view results
# #importance(model)
# treerst<-order(importance(model),decreasing = T)[1:length(truth)]
#
# ### BMA
# bicfit<-bicreg(x[,-1],y.res,strict = T)
# bicrst<-bicfit$namesx[order(bicfit$probne0,decreasing = T)][1:length(truth)]
#
# ### Stepwise
# a<-regsubsets(x=x,y=y,method="forward",nvmax = 3*length(truth),force.in = 1)
# steprst<-a$vorder[1:(length(truth)+1)]-1
#
# ### Spike-and-Slab
# m <- lm.spike(Y~.,niter = 1000,data=simu,bma.method = "SSVS",error.distribution = "gaussian")
# summary(m)
# plot(m)
#
# ### Group Lasso
# lamb_opt<-4
# lamb_opt2<-1
# x0<-rep(0,dim(x)[2])
# solg<-FASTA(x,y,f, gradf, g, proxg, x0, tau1, max_iters = 300, w = 10,
#            backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5,
#            eps_n = 1e-15,0,1,m_G,m_G,lamb_opt,lamb_opt2,restart=TRUE)
# glassorst<-which(solg$x!=0)
#
# ### Regular Lasso
# lamb_opt<-40
# lamb_opt2<-10
# sol<-FASTA(x,y,f, gradf, glasso, proxglasso, x0, tau1, max_iters = 300, w = 10,
#            backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5,
#            eps_n = 1e-15,0,1,m_G,m_G,lamb_opt,lamb_opt2,restart=TRUE)
# lassorst<-which(sol$x!=0)
#
# ### SIRI
# dir<-"C:\\Users\\auz5836\\Documents\\GitHub\\GroupLasso\\V4"
#
# #need to import library(dr) and library(MASS)
# source(sprintf("%s\\siri.R",dir))
# source(sprintf("%s\\simu.R",dir))
# source(sprintf("%s\\siri.fit.R",dir))
#
# ############
# #SIRI setup#
# ############
# #number of slices
# H<-5
#
# #effective dimension for simple model [1..Q]
# Q<-2
#
# #CV fold
# K.fold<-10
#
# #sample size
# n<-dim(x)[1]
#
# #number of predictors
# d<-dim(x)[2]
#
# #grid of thresholds on chi-square quantiles
# #alpha.list<-c(1-1/d,1-.5/d,1-.25/d,1-.05/d,1-.01/d)
# alpha.list<-c(0.9,0.95,0.97,0.99,0.995,0.999)
#
# #sis selection bound
# range.sis<-min(d,floor(n/log(n)))
#
# #simple model selection bound
# range.linear<-min(d,floor(0.5*n/H))
#
# #augmented model selection bound
# range.interact<-min(d,floor(0.25*n/H))
#
# #iteration for ISIS
# niter<-2
#
# ##########
# #Run SIRI#
# ##########
# #Run SIRI and save the result into "results"
# results<-siri(x,y,H,Q,K.fold,alpha.list,niter,range.linear,range.interact,range.sis)
 
 
n=100
m_X<-5
m_W<-1
m_G<-100
m_I<-m_G
SNR<-10
tau1<-1
 
 

#### Iteration
treerst<-list()
bicrst<-list()
steprst<-list()
glassorst<-list()
lassorst<-list()
sisrst<-list()
 
for(portion in c(0.05,0.1,0.15,0.2)){
  for(i in 1:100){
    print(i)
    #Set Seed
    set.seed(i+1000)
   
    # Generate X and Y
    sigma<-cov_block(m_G,.3,20)
    #sigma<-GenerateCliquesCovariance(10,10,0.8)
    #binprob<-runif(m_G)
    x<-sim_X(m_X,m_W,m_G,sigma,n)
    #beta<-sim_beta(m_X=0,m_W=1,m_G,main_nonzero=0.05,inter_nonzero=0.05,both_nonzero=0.1,bit=T,heir=T)
    beta<-sim_beta_const(m_X,m_W=1,m_G,main_nonzero=portion,inter_nonzero=portion,both_nonzero=0.01,const=c(3,5),heir=TRUE)
    y0<-x%*%beta
   
    
    noise<-rnorm(n,sd=1)
    SNRmtl <- as.numeric(sqrt(var(y0)/(SNR*var(noise))))
    y<-y0+SNRmtl*noise 
    colnames(x)<-c(1:dim(x)[2])
    truth<-which(beta!=0)
   
    simu<-data.frame(X=x,Y=y)
    L<-lm(y~x[,c(1:(m_X+m_W))])
    y.res<-L$residuals
    simu$Y<-y.res
    simu<-simu[,-c(1:(m_X+m_W))]
   
#     ### Trees
#     model <- randomForest(Y~.,   data=simu)
#     #print(model) # view results
#     #importance(model)
#     treerst[[i]]<-order(importance(model),decreasing = T)[1:length(truth)]
#    
    ### BMA
    bicfit<-bicreg(x[,-c(1:(m_X+m_W))],y.res,strict = T)
    bicrst[[i]]<-bicfit$namesx[order(bicfit$probne0,decreasing = T)][1:length(truth)]
    bicrst[[i]]<-sapply(bicrst[[i]],function(x) strsplit(x,"X")[[1]][2])
    bicrst[[i]]<-as.integer(bicrst[[i]])
    bicrst[[i]]<-bicrst[[i]][which(is.na(bicrst[[i]])==F)]
#    
#     ### Stepwise
#     a<-regsubsets(x=x,y=y,method="forward",nvmax = 3*length(truth),force.in = c(1:(m_X+m_W)))
#     steprst[[i]]<-a$vorder[-1][1:(length(truth))]-1
#     #steprst[[i]]<-steprst[order(steprst[[i]])][[1]]
# 
#     
#     x0<-rep(0,dim(x)[2])
#     ### Group Lasso
#     lamb_opt_glasso<-15
#     lamb_opt2_glasso<-1
#     solg<-FASTA(x,y,f, gradf, g, proxg, x0, tau1, max_iters = 300, w = 10,
#                 backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5,
#                 eps_n = 1e-15,m_X,m_W,m_G,m_G,lamb_opt_glasso,lamb_opt2_glasso,restart=TRUE)
#     glassorst[[i]]<-order(abs(solg$x[-c(1:(m_W+m_X))]),decreasing = T)[1:(length(truth)-m_X-m_W)]+m_X+m_W
#    
#     ### Regular Lasso
#     L<-glmnet(x,y,family="gaussian",penalty.factor=rep(0:1,c(m_X+m_W,2*m_G)))
#     
#     lamb_opt_lasso<-180
#     lamb_opt2_lasso<-5
#     sol<-FASTA(x,y,f, gradf, glasso, proxglasso, x0, tau1, max_iters = 300, w = 10,
#                backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5,
#                eps_n = 1e-15,m_X,m_W,m_G,m_G,lamb_opt_lasso,lamb_opt2_lasso,restart=TRUE)
#     lassorst[[i]]<-order(abs(sol$x[-c(1:(m_W+m_X))]),decreasing = T)[1:(length(truth)-m_X-m_W)]+m_X+m_W
#    
#     ### SIS
#     #model1<-SIS(x,y,family = "gaussian", penalty = "lasso", tune="bic")
#     model2<-SIS(x,y,family = "gaussian", penalty = "lasso", tune="bic",varISIS = "aggr")
#     sisrst[[i]]<-model2$ix
  }
 
  
  #save(truth,"C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//30//truth.RData")
   save(bicrst,file=paste0("C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//100//bicrst",portion,".RData"))
#   save(steprst,file=paste0("C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//100//steprst",portion,".RData"))
#   save(treerst,file=paste0("C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//100//treerst",portion,".RData"))
   #  save(glassorst,file=paste0("C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//100//glassorst",portion,".RData"))
#  save(lassorst,file=paste0("C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//100//lassorst",portion,".RData"))
#   save(sisrst,file=paste0("C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//100//sisrst",portion,".RData"))
# save(glassorst,file=paste0("/Users/wenxuandeng/GoogleDrive/sucksalt/group_lasso/code/GroupLasso/Final_Simu/100/glassorst",portion,".RData"))
# save(lassorst,file=paste0("/Users/wenxuandeng/GoogleDrive/sucksalt/group_lasso/code/GroupLasso/Final_Simu/100/lassorst",portion,".RData"))
}
 
########################################################
 
n=100
m_X<-5
m_W<-1
m_G<-200
m_I<-m_G
SNR<-10
tau1<-1
 
 

#### Iteration
treerst<-list()
bicrst<-list()
steprst<-list()
glassorst<-list()
lassorst<-list()
sisrst<-list()
 
for(i in 1:100){
  print(i)
  #Set Seed
  set.seed(i+1000)
 
  # Generate X and Y
  sigma<-cov_block(m_G,.3,40)
  #sigma<-GenerateCliquesCovariance(10,10,0.8)
  #binprob<-runif(m_G)
  x<-sim_X(m_X,m_W,m_G,sigma,n)
  #beta<-sim_beta(m_X=0,m_W=1,m_G,main_nonzero=0.05,inter_nonzero=0.05,both_nonzero=0.1,bit=T,heir=T)
 beta<-sim_beta_const(m_X,m_W=1,m_G,main_nonzero=0.1,inter_nonzero=0.1,both_nonzero=0.01,const=c(3,5),heir=TRUE)
  y0<-x%*%beta
 
  
  noise<-rnorm(n,sd=1)
  SNRmtl <- as.numeric(sqrt(var(y0)/(SNR*var(noise))))
  y<-y0+SNRmtl*noise 
  colnames(x)<-c(1:dim(x)[2])
  truth<-which(beta!=0)
 
  simu<-data.frame(X=x,Y=y)
  L<-lm(y~x[,c(1:(m_X+m_W))])
  y.res<-L$residuals
  simu$Y<-y.res
  simu<-simu[,-c(1:(m_X+m_W))]
  
#   ### Trees
#   model <- randomForest(Y~.,   data=simu)
#   #print(model) # view results
#   #importance(model)
#   treerst[[i]]<-order(importance(model),decreasing = T)[1:(length(truth)-m_X-m_W)]
  # 
  ### BMA
  bicfit<-bicreg(x[,-c(1:(m_X+m_W))],y.res,strict = T)
  bicrst[[i]]<-bicfit$namesx[order(bicfit$probne0,decreasing = T)][1:length(truth)]
  bicrst[[i]]<-sapply(bicrst[[i]],function(x) strsplit(x,"X")[[1]][2])
  bicrst[[i]]<-as.integer(bicrst[[i]])
  bicrst[[i]]<-bicrst[[i]][which(is.na(bicrst[[i]])==F)]
  
#   ### Stepwise
#   a<-regsubsets(x=x,y=y,method="forward",nvmax = 3*length(truth),force.in = c(1:(m_X+m_W)))
#   steprst[[i]]<-a$vorder[-1][1:(length(truth))]-1
#   #steprst[[i]]<-steprst[order(steprst[[i]])][[1]]
  # 
#   x0<-rep(0,dim(x)[2])
#   ### Group Lasso
#   lamb_opt_glasso<-21
#   lamb_opt2_glasso<-2
#   solg<-FASTA(x,y,f, gradf, g, proxg, x0, tau1, max_iters = 300, w = 10,
#               backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5,
#               eps_n = 1e-15,m_X,m_W,m_G,m_G,lamb_opt_glasso,lamb_opt2_glasso,restart=TRUE)
#    glassorst[[i]]<-order(abs(solg$x[-c(1:(m_W+m_X))]),decreasing = T)[1:(length(truth)-m_X-m_W)]+m_X+m_W
#    
#   ### Regular Lasso
#   lamb_opt_lasso<-180
#   lamb_opt2_lasso<-5
#   sol<-FASTA(x,y,f, gradf, glasso, proxglasso, x0, tau1, max_iters = 300, w = 10,
#              backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5,
#              eps_n = 1e-15,m_X,m_W,m_G,m_G,lamb_opt_lasso,lamb_opt2_lasso,restart=TRUE)
#   lassorst[[i]]<-order(abs(sol$x[-c(1:(m_W+m_X))]),decreasing = T)[1:(length(truth)-m_X-m_W)]+m_X+m_W
   
#   ### SIS
#   #model1<-SIS(x,y,family = "gaussian", penalty = "lasso", tune="bic")
#   model2<-SIS(x,y,family = "gaussian", penalty = "lasso", tune="bic",varISIS = "aggr")
#   sisrst[[i]]<-model2$ix
}
 
 
#save(truth,"C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//30//truth.RData")
save(bicrst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//200//bicrst.RData")
# save(steprst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//200//steprst.RData")
# save(glassorst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//200//glassorst.RData")
# save(lassorst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//200//lassorst.RData")
# save(sisrst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//200//sisrst.RData")
save(treerst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//200//treerst.RData")

save(glassorst,file=paste0("/Users/wenxuandeng/GoogleDrive/sucksalt/group_lasso/code/GroupLasso/Final_Simu/200/glassorst",".RData"))
save(lassorst,file=paste0("/Users/wenxuandeng/GoogleDrive/sucksalt/group_lasso/code/GroupLasso/Final_Simu/200/lassorst",".RData"))

