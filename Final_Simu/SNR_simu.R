n=100
m_X<-5
m_W<-1
m_G<-50
m_I<-m_G
SNR<-10
tau1<-1


SNRlist<-c(1,5,10,100)
for(SNR in SNRlist){
  
  x0<-rep(0,dim(x)[2])
  #### Cross Validation finding best lambda for Group Lasso
  lamb_candidate<-c(1,1.5,2,2.5,3,4)
  lamb_candidate2<-c(0.5,1,1.5,2)
  sol_cv<-opt_lambda(x,y,f, gradf, g, proxg, x0, tau1, max_iters = 100, w = 10, 
                     backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
                     eps_n = 1e-15,m_X,m_W,m_G,m_I,K=10,n=100, lamb_candidate, lamb_candidate2,restart=TRUE)
  lamb_loc<-which(sol_cv$mean+sol_cv$var == min(sol_cv$mean+sol_cv$var), arr.ind = TRUE)
  lamb_opt_glasso<-lamb_candidate[lamb_loc[1]]
  lamb_opt2_glasso<-lamb_candidate2[lamb_loc[2]]
  save(sol_cv,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//100//sol_cv_glasso_",SNR,".RData")
  
  #### Cross Validation finding best lambda for General Lasso
  lamb_candidate<-c(15,25,30,35,40,45,50)
  lamb_candidate2<-c(1,3,5,7)
  sol_cv<-opt_lambda(x,y,f, gradf, glasso, proxglasso, x0, tau1, max_iters = 100, w = 10, 
                     backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
                     eps_n = 1e-15,m_X,m_W,m_G,m_I,K=10,n=100, lamb_candidate, lamb_candidate2,restart=TRUE)
  lamb_loc<-which(sol_cv$mean+sol_cv$var == min(sol_cv$mean+sol_cv$var), arr.ind = TRUE)
  lamb_opt_lasso<-lamb_candidate[lamb_loc[1]]
  lamb_opt2_lasso<-lamb_candidate2[lamb_loc[2]]
  save(sol_cv,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//100//sol_cv_lasso_",SNR,".RData")
  
  
  
  
  
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
    
    simu<-data.frame(X=x,Y=y)
    L<-lm(y~x[,c(1:(m_X+m_W))])
    y.res<-L$residuals
    simu$Y<-y.res
    simu<-simu[,-c(1:(m_X+m_W))]
    
    ### Trees
    model <- randomForest(Y~.,   data=simu)
    #print(model) # view results 
    #importance(model)
    treerst[[i]]<-order(importance(model),decreasing = T)[1:length(truth)]
    
    ### BMA
    bicfit<-bicreg(x[,-c(1:(m_X+m_W))],y.res,strict = T)
    bicrst[[i]]<-bicfit$namesx[order(bicfit$probne0,decreasing = T)][1:length(truth)]
    bicrst[[i]]<-sapply(bicrst[[i]],function(x) strsplit(x,"X")[[1]][2])
    bicrst[[i]]<-as.integer(bicrst[[i]])
    
    ### Stepwise
    a<-regsubsets(x=x,y=y,method="forward",nvmax = 3*length(truth),force.in = c(1:(m_X+m_W)))
    steprst[[i]]<-a$vorder[1:(length(truth))]
    steprst[[i]]<-steprst[order(steprst[[i]])][[1]]
    
    ### Group Lasso
    
    solg<-FASTA(x,y,f, gradf, g, proxg, x0, tau1, max_iters = 300, w = 10, 
                backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
                eps_n = 1e-15,m_X,m_W,m_G,m_G,lamb_opt_glasso,lamb_opt2_glasso,restart=TRUE)
    glassorst[[i]]<-which(solg$x!=0)
    
    ### Regular Lasso
    sol<-FASTA(x,y,f, gradf, glasso, proxglasso, x0, tau1, max_iters = 300, w = 10, 
               backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
               eps_n = 1e-15,m_X,m_W,m_G,m_G,lamb_opt_lasso,lamb_opt2_lasso,restart=TRUE)
    lassorst[[i]]<-which(sol$x!=0)
    
    ### SIS
    #model1<-SIS(x,y,family = "gaussian", penalty = "lasso", tune="bic")
    model2<-SIS(x,y,family = "gaussian", penalty = "lasso", tune="bic",varISIS = "aggr")
    sisrst[[i]]<-model2$ix
  }
  
  
  #save(truth,"C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//30//truth.RData")
  save(bicrst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//bicrst_",SNR,".RData")
  save(steprst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//steprst_",SNR,".RData")
  save(glassorst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//glassorst_",SNR,".RData")
  save(lassorst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//lassorst_",SNR,".RData")
  save(sisrst,file="C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//sisrst_",SNR,".RData")
  
}