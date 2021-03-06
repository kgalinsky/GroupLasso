# Cross Validation
divide<-function(K,n){
  i.mix = sample(1:n)
  folds = vector(mode="list",length=K)
  temp<-split(c(1:n),1:K)
  for(i in 1:K){
    folds[[i]]<-i.mix[temp[[i]]]
  }
  return(folds)
}


cv.FASTA<-function(X,y,f, gradf, g, proxg, x0, tau1, max_iters = 100, w = 10, 
                   backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
                   eps_n = 1e-15,m_X,m_W,m_G,m_I,lambda,lambda2,K=10,n=100,restart,truth){
  
  folds<-divide(K,n)
  
  sol_cv<-list()
  TestErr<-rep(0,K)
  
  for(k in 1:K){
    print(c(k,k,k,k,k,k,k))
    
    # Generating training and test datasets for cross validation
    test_X<-X[folds[[k]],]
    train_X<-X[setdiff(c(1:n),folds[[k]]),]
    test_y<-y[folds[[k]]]
    train_y<-y[setdiff(c(1:n),folds[[k]])]
    
    # Training model on training dataset
    
    sol_cv[[k]]<-FASTA(train_X,train_y,f, gradf, g, proxg, x0, tau1, max_iters = 100, w = 10, 
                        backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
                        eps_n = 1e-15,m_X,m_W,m_G,m_I,lambda,lambda2,restart)
    x0<-sol_cv[[k]]$x
    print("a")
    
    # Test on the validation group
    #TestErr[k]<-f0(sol_cv[[k]]$x,test_X,test_y)/length(test_y)
    TestErr[k]<-norm(sol_cv[[k]]$x-truth,"2")
    
    
  }
  return(list(Err=TestErr,start=x0))
}


opt_lambda<-function(X,y,f, gradf, g, proxg, x0, tau1, max_iters = 100, w = 10, 
                      backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
                      eps_n = 1e-15,m_X,m_W,m_G,m_I,K=10,n=100,lamb_candidate,lamb_candidate2,restart,truth){

  lamb_candidate<-lamb_candidate[order(lamb_candidate,decreasing = T)]
  lamb_candidate2<-lamb_candidate2[order(lamb_candidate2,decreasing = T)]
  
  
  TestErr<-matrix(0,nrow=length(lamb_candidate),ncol=length(lamb_candidate2))
  VarErr<-matrix(0,nrow=length(lamb_candidate),ncol=length(lamb_candidate2))
  
  for(i in seq_along(lamb_candidate)){
    for(j in seq_along(lamb_candidate2)){
      print(c(i,j))
    rst<-cv.FASTA(X,y,f, gradf, g, proxg, x0, tau1, max_iters = max_iters, w = 10, 
                   backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
                   eps_n = 1e-15,m_X,m_W,m_G,m_I,lamb_candidate[i],lamb_candidate2[j],K,n,restart=TRUE,truth)
    cv.Err<-rst$Err
    x0<-rst$start
    TestErr[i,j]<-mean(cv.Err)
    VarErr[i,j]<-var(cv.Err)
    print(c(paste("lambda 1=",lamb_candidate[i]),paste("lambda 2=",lamb_candidate2[j])))
    print(cv.Err)
    }
    TestErr[i,]<-rev(TestErr[i,])
    VarErr[i,]<-rev(VarErr[i,])
  }
  
  TestErr<-apply(TestErr,2,rev)
  VarErr<-apply(VarErr,2,rev)
  
  return(list(mean=TestErr,var=VarErr))
}



