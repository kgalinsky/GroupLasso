library(partitions)
library(MASS)
library(copula)

cov_block<-function(p,rho,block_num){
  block<-rmultinom(n = 1, size = p, prob = rep(1/block_num, block_num))
  blockstart<-cumsum(c(1,block))[-(block_num+1)]
  blockend<-cumsum(block)

  fun<-function(i,j){ (max(which(i>=blockstart))==max(which(j>=blockstart)))*rho/max(abs(i-j),0) } 
  corrmat<-outer(1:p, 1:p , Vectorize(fun) )
  #corrmat[upper.tri(corrmat)] <- t(corrmat)[upper.tri(corrmat)]
  diag(corrmat)<-1
  
  return(corrmat)
}

sim_X<-function(m_X,m_W,m_G,sigma,n){
  if(m_X!=0){
    X0<-matrix(rnorm(n*m_X),n,m_X)
  }
  X<-mvrnorm(n,rep(0,m_G),sigma)
  W<-(sample(c(0,1),n,replace = T)*2-1)
  X<-cbind(X0,W,X,W*X)
  return(X)
}

sim_X_cate<-function(m_X,m_W,m_G,sigma,n,binprob){
  if(m_X!=0){
    X0<-matrix(rnorm(n*m_X),n,m_X)
  } else{ X0<-NULL }
  W<-(sample(c(0,1),n,replace = T)*2-1)
  para<-P2p(sigma)
  tmp<-normalCopula(para,dim=m_G,dispstr = "un")
  X<-rCopula(n,tmp)
  for(i in 1:m_G){
    if(length(unique(X[,i]))==1){
      X[1,i]=X[1,i]+1
    }
  }
# X0<-mapply(function(x,y) qbinom(x, 2, y),X,binprob)
# X0<-matrix(X0,ncol=m_G)
  Y<-X
  for(i in 1:dim(X)[2]){
    Y[,i]<-qbinom(X[,i],2,binprob[i])
  }
  X<-cbind(X0,W,Y,W*Y)
  return(X)
}


sim_beta<-function(m_X,m_W,m_G,main_nonzero,inter_nonzero,both_nonzero,bit=TRUE,heir=TRUE){
  main_nonzero<-floor(main_nonzero*m_G)
  inter_nonzero<-floor(inter_nonzero*m_G)
  both_nonzero<-floor(both_nonzero*m_G)
  
  
  if(m_X!=0){
    beta_X<-matrix(rnorm(m_X),m_X,1)
  } else{ beta_X<-NULL}
  if(m_W!=0){
    beta_W<-matrix(rnorm(m_W),m_W,1)
  } else{ beta_W<-NULL }
  beta_G<-matrix(rnorm(m_G),m_G,1)
  beta_I<-matrix(rnorm(m_G),m_G,1)
  
  if(bit){
    if(m_X!=0){
      beta_X<-beta_X+sign(beta_X)*0.4
    }
    if(m_W!=0){
      beta_W<-beta_W+sign(beta_W)*0.4
    }
    beta_G<-beta_G+sign(beta_G)*0.4
    beta_I<-beta_I+sign(beta_I)*0.4
  }
  
  if(heir){
    beta_G[-c(1:(main_nonzero+inter_nonzero))]<-0   # Only two are nonzero
    beta_I[-c(1:inter_nonzero)]<-0   # Onl three are nonzero
  } else{
    beta_G[-c(1:(both_nonzero+main_nonzero)),]<-0
    beta_I[-c(1:both_nonzero,(both_nonzero+main_nonzero+1):(both_nonzero+main_nonzero+inter_nonzero)),]<-0
  }
  
  beta<-rbind(beta_X,beta_W,beta_G,beta_I)
  return(beta)
}

sim_beta_const<-function(m_X,m_W,m_G,main_nonzero,inter_nonzero,both_nonzero,const=c(3),heir=TRUE){
  main_nonzero<-floor(main_nonzero*m_G)
  inter_nonzero<-floor(inter_nonzero*m_G)
  both_nonzero<-floor(both_nonzero*m_G)
  
  const<-c(const,-const)
  
  beta_X<-matrix(rnorm(m_X),m_X,1)+as.matrix(sample(const,m_X,replace = T))
  beta_W<-matrix(rnorm(m_W),m_W,1)+as.matrix(sample(const,m_W,replace = T))
  
  
  beta_G<-as.matrix(sample(const,m_G,replace = T))
  beta_I<-as.matrix(sample(const,m_G,replace = T))
  
  
  if(heir){
    beta_G[-c(1:(main_nonzero+inter_nonzero))]<-0   # Only two are nonzero
    beta_I[-c(1:inter_nonzero)]<-0   # Onl three are nonzero
  } else{
    beta_G[-c(1:(both_nonzero+main_nonzero)),]<-0
    beta_I[-c(1:both_nonzero,(both_nonzero+main_nonzero+1):(both_nonzero+main_nonzero+inter_nonzero)),]<-0
  }
  
  beta<-rbind(beta_X,beta_W,beta_G,beta_I)
  return(beta)
}

