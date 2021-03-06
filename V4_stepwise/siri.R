library(dr)
library(MASS)

addToLinear<-function(x,y,H,K,linear.set,slices,nslices)
{
  n=nrow(x)
  q<-length(linear.set)
  kk<-min(q,K)	
  if(q==1)
  {
    x1<-x[,linear.set]
    lambda<-0.0
    for(h in 1:nslices)
    {
      lambda<-lambda+sum(slices==h)*(mean(x1[slices==h])-mean(x1))^2
    }
    lambda<-lambda/n
    lambda<-lambda/var(x1)
  } else {
    x1=as.matrix(x[,linear.set])
    temp<-dr(y~x1,nslices=H)
    lambda<-as.numeric(temp$evalues[1:kk])
  }
  lik=n*sum(-log(1-lambda))
  return(lik)
}

addToInteract<-function(x,H,combined.set,id,slices,nslices)
{
  n=nrow(x)
  d=length(combined.set)	
  if(d==0)
  {
    x1=x[,id]
    liki=n*log(sum(x1^2)/n)
    for(h in 1: nslices){
      x.h<-x1[slices==h]-mean(x1[slices==h])
      n.h<-sum(slices==h)
      liki=liki-n.h*log(sum(x.h^2)/n.h)
    }
  }else{
    x1=x[,id]
    z1=as.matrix(x[,combined.set])
    temp1<-mean(lm(x1~z1)$residuals^2)
    liki=n*log(temp1)
    for(h in 1:nslices){
      x.h<-x1[slices==h]
      z.h<-z1[slices==h,]
      temp2<-mean(lm(x.h~z.h)$residuals^2)
      n.h<-sum(slices==h)
      liki=liki-n.h*log(temp2)
    }
  }
  return(liki)
}

siri.linear<-function(result,x,y,H,K,alpha,my.range)
{
  x=as.matrix(x)		
  p=NCOL(x)
  n=nrow(x)
  my.step=1			
  my.forward="conti"		
  while(my.forward=="conti"&my.step<my.range){		
    set.all<-result$sis
    set.redundant<-setdiff(set.all,result$linear.set)
    pp=length(set.redundant)    
    lik<-NULL	
    for(j in 1:pp){
      linear.set<-c(result$linear.set,set.redundant[j])
      lik[j]<-addToLinear(x,y,H,K,linear.set,result$slices,result$nslices)-result$linear.lik
    }
    lik.max=max(lik[!is.na(lik)])	
    id.max<-which(lik==lik.max)[1]	
    q<-length(result$linear.set)+1
    if(q<=K)
    {
      chi.in<-qchisq(alpha,H-1)
      #chi.in<-qchisq(alpha,H)
    } else {
      chi.in<-qchisq(alpha,K)
    }
    #print(lik.max)
    #print(chi.in)
    if(lik.max>=chi.in){
      my.forward="conti"
      result$linear.set<-c(result$linear.set,set.redundant[id.max])
      result$linear.lik<-result$linear.lik+lik.max
      my.backward="conti"
      #my.backward="stop"
      while(my.backward=="conti"&length(result$linear.set)>K){
        pp=length(result$linear.set)
        lik=NULL
        for(l in 1:pp){
          linear.set<-result$linear.set[-l]
          lik[l]<-result$linear.lik-addToLinear(x,y,H,K,linear.set,result$slices,result$nslices)
        }
        lik.min=min(lik[!is.na(lik)])	
        id.min<-which(lik==lik.min)[1]
        chi.out<-qchisq(alpha-0.05,K)
        if(lik.min<chi.out){
          my.backward="conti"
          result$linear.set<-result$linear.set[-id.min]
          result$linear.lik<-result$linear.lik-lik.min
        }else{
          my.backward="stop"
        }
      }
    }else{
      my.forward="stop"
    }
    my.step=length(result$linear.set)
  }	
  return(result)
}

siri.interact<-function(result,x,H,alpha,my.range)
{
  x=as.matrix(x)		
  p=NCOL(x)
  n=nrow(x)
  my.step=1			
  my.forward="conti"		
  while(my.forward=="conti"&my.step<my.range){		
    set.all<-result$sis
    combined.set<-c(result$linear.set,result$interact.set)
    set.redundant<-setdiff(set.all,combined.set)
    d=length(combined.set)
    pp=length(set.redundant)        
    lik=NULL	  	
    for(j in 1:pp){
      id<-set.redundant[j]
      lik[j]<-addToInteract(x,H,combined.set,id,result$slices,result$nslices)
    }
    lik.max=max(lik[!is.na(lik)])	
    id.max<-which(lik==lik.max)[1]	
    #chi.in<-qchisq(alpha,H*(d+2))
    chi.in<-qchisq(alpha,(H-1)*(d+2))*(n/(n-H*(d+2)))
    #print(lik.max)
    #print(chi.in)
    if(lik.max>=chi.in){
      my.forward="conti"
      result$interact.set<-c(result$interact.set,set.redundant[id.max])
      result$interact.lik<-result$interact.lik+lik.max
      my.backward="conti"
      while(my.backward=="conti"&length(result$interact.set)>1){
        pp=length(result$interact.set)
        lik=NULL
        for(l in 1:pp){
          combined.set<-c(result$linear.set,result$interact.set[-l])
          id<-result$interact.set[l]
          lik[l]<-addToInteract(x,H,combined.set,id,result$slices,result$nslices)
        }
        d=length(combined.set)
        lik.min=min(lik[!is.na(lik)])	
        id.min<-which(lik==lik.min)[1]
        #chi.out<-qchisq(alpha,H*(d+2))
        chi.out<-qchisq(alpha-0.05,(H-1)*(d+2)) *(n/(n-H*(d+2)))
        if(lik.min<chi.out){
          my.backward="conti"
          result$interact.set<-result$interact.set[-id.min]
          result$interact.lik<-result$interact.lik-lik.min
        }else{
          my.backward="stop"
        }
      }
    }else{
      my.forward="stop"
    }
    my.step=length(result$interact.set)
  }	
  return(result)
}

siri.sis<-function(result,x,H,alpha,my.range)
{
  x=as.matrix(x)		
  p=NCOL(x)
  n=nrow(x)
  set.all<-1:p
  combined.set<-c(result$linear.set,result$interact.set)
  set.redundant<-setdiff(set.all,combined.set)
  d<-my.range-length(combined.set)
  pp=length(set.redundant)        
  lik=NULL	  	
  for(j in 1:pp){
    id<-set.redundant[j]
    lik[j]<-addToInteract(x,H,combined.set,id,result$slices,result$nslices)
  }
  result$sis.set<-set.redundant[sort.int(lik,decreasing=T,index.return=T)$ix[1:d]]
  return(result)
}

siri.iter<-function(x,y,H,K,alpha,niter,range.linear,range.interact,range.sis){
  y<-scale(y)
  x<-scale(x)
  n<-nrow(x)
  p<-ncol(x)
  y.slices<-dr.slices(y,nslices=H)
  result<-list(slices=y.slices[[1]],nslices=y.slices[[2]],sizes=y.slices[[3]],H=H,K=K,alpha=alpha,linear.set=NULL,linear.lik=0.0,interact.set=NULL,interact.lik=0.0,sis.set=1:p)
  result<-siri.sis(result,x,H,alpha,range.sis)
  #print(result$sis.set)
  if(K>0) {
    result<-siri.linear(result,x,y,H,K,alpha,range.linear)
  }
  p1<-length(result$linear.set)
  #print(result$linear.set)
  if(p1<K&K>0)
  {
    return(NULL)
  }
  result<-siri.interact(result,x,H,alpha,range.interact)
  p2<-length(result$interact.set)
  #print(result$interact.set)
  if(p1+p2==0)
  {
    return(NULL)
  }
  if(niter>1) {
    combined.set<-c(result$linear.set,result$interact.set)
    combined.set.old<-combined.set
    for(t in 2:niter)
    {
      combined.set.old<-combined.set
      result<-siri.sis(result,x,H,alpha,range.sis)
      #print(result$sis.set)
      result<-siri.interact(result,x,H,alpha,range.interact)
      combined.set<-c(result$linear.set,result$interact.set)
      #print(combined.set)
      #print(combined.set.old)
      if(length(combined.set)>=range.sis|setequal(combined.set,combined.set.old)) { break }
    }
  }
  return(result)
}

siri.estimate<-function(x,y,result)
{
  H<-result$H
  K<-result$K
  x1<-as.matrix(x[,result$linear.set])
  x2<-as.matrix(x[,result$interact.set])
  p1<-length(result$linear.set)
  p2<-length(result$interact.set)
  slices<-result$slices
  nslices<-result$nslices
  n<-length(y)
  beta.hat<-NULL
  beta1<-NULL
  sigma1<-NULL
  size<-rep(0,nslices)
  if(p1>0){
    if(p1>1) {
      temp<-dr(y~x1,nslices=H)
      beta.hat<-temp$evectors[,1:K]
      x11<-x1%*%beta.hat
    } else {
      beta.hat<-1.0
      x11<-x1
    }
    sigma1<-matrix(0,K,K)
    for(h in 1:nslices)
    {
      beta1[[h]]<-as.matrix(apply(as.matrix(x11[slices==h,]),2,mean))
      size[h]<-sum(slices==h)
      xx11<-scale(x11[slices==h,],scale=FALSE)
      sigma1<-sigma1+t(xx11)%*%xx11
    }
    sigma1<-sigma1/n
  }	
  beta2<-NULL
  sigma2<-NULL
  if(p2>0){
    for(h in 1:nslices){
      x.h<-as.matrix(x2[slices==h,])
      n.h<-sum(slices==h)
      size[h]<-n.h
      z.h<-cbind(rep(1,n.h),x1[slices==h,])
      beta2[[h]]<-solve(t(z.h)%*%z.h)%*%t(z.h)%*%x.h
      sigma2[[h]]<-t(x.h)%*%(diag(n.h)-z.h%*%solve(t(z.h)%*%z.h)%*%t(z.h))%*%x.h/n.h
    }
  }
  model<-list(size=size,beta.hat=beta.hat,beta1=beta1,sigma1=sigma1,beta2=beta2,sigma2=sigma2)
  return(model)	
}

siri.predict<-function(x,y,result,model,test,train)
{
  H<-result$H
  nslices<-result$nslices
  n<-length(test)
  p1<-length(result$linear.set)
  p2<-length(result$interact.set)
  if(n>1) {
    x1<-as.matrix(x[test,result$linear.set])
    x2<-as.matrix(x[test,result$interact.set])
  } else {
    x1<-x[test,result$linear.set]
    x2<-x[test,result$interact.set]
  }
  y.train<-y[train]
  y.test<-y[test]
  slices.train<-result$slices
  slices.test<-rep(H,n)
  label<-rep(1,n)
  posterior<-rep(nslices/2.0,n)
  y.value<-rep(0,nslices)
  for(h in 1:nslices)
  {
    y.value[h]<-median(y.train[slices.train==h])
  }
  for(i in 1:n)
  {
    if(n>1) {
      xx1<-as.matrix(x1[i,])
      xx2<-as.matrix(x2[i,])
    } else {
      xx1<-as.matrix(x1)
      xx2<-as.matrix(x2)		
    }
    xx11<-rbind(1,xx1)
    if(p1>0)
    {
      xx1<-t(xx1)%*%model$beta.hat
      xx1<-t(xx1)
    }
    lik<-log(model$size)
    for(h in 1:nslices)
    {
      if(p1>0){
        lik[h]<-lik[h]-t(xx1-model$beta1[[h]])%*%solve(model$sigma1)%*%(xx1-model$beta1[[h]])
      }
      if(p2>0){
        lik[h]<-lik[h]-t(xx2-t(model$beta2[[h]])%*%xx11)%*%solve(as.matrix(model$sigma2[[h]]))%*%(xx2-t(model$beta2[[h]])%*%xx11)-log(det(as.matrix(model$sigma2[[h]])))
      }
    }
    label[i]<-which.max(lik)
    prob<-exp(lik-min(lik))/sum(exp(lik-min(lik)))
    #posterior[i]<-sum(seq(1:nslices)*prob)
    posterior[i]<-sum(y.value*prob)
    for(h in 1:nslices)
    {
      if(y.test[i] <= max(y.train[slices.train==h]))
      {
        slices.test[i]=h
        break
      }
    }
    
  }
  #ssr<-sum(abs(posterior-slices.test))
  ssr<-sum(abs(posterior-y.test))
  error<-sum(label!=slices.test)
  #print(label)
  #print(slices.test)
  return(list(label=label,ssr=ssr,error=error))
}

siri.cv<-function(x,y,div,H,K,alpha,niter,range.linear,range.interact,range.sis,result.full)
{
  ssr<-NULL
  error<-NULL
  label<-NULL
  n=nrow(x)
  id<-c(1:n)
  result<-result.full
  for(k in 1:length(unique(div))){
    train<-id[div!=k]
    test<-id[div==k]
    #result<-siri.iter(x[train,],y[train],H,K,alpha,niter,range.linear,range.interact,range.sis)
    #print(result)
    y.slices<-dr.slices(y[train],nslices=H)
    result$slices<-y.slices[[1]]
    result$nslices<-y.slices[[2]]
    result$sizes<-y.slices[[3]]
    if(length(result$linear.set)+length(result$interact.set)>0)
    {
      model<-siri.estimate(x[train,],y[train],result)
      cv<-siri.predict(x,y,result,model,id[div==k],id[div!=k])
      label<-c(label,cv$label)
      ssr<-c(ssr,cv$ssr)
      error<-c(error,cv$error)
    } else {
      print("Empty Set!")
      nn<-length(test)
      label<-c(label,sample(1:nslices,nn,replace=T))
      ssr<-c(ssr,(nn-1)*var(y[test]))
      error<-c(error,nn)
    }	
  }
  ssr<-sum(ssr)/n
  error<-sum(error)/n
  return(list(label=label,ssr=ssr,error=error))
}

siri<-function(x,y,H,Q,K.fold,alpha.list,niter,range.linear,range.interact,range.sis)
{
  n<-nrow(x)
  div<-rep(K.fold,n)
  pid<-sample(c(1:n), n, replace = FALSE)
  for(k in 1:(K.fold-1))
  {
    div[pid[((k-1)*floor(n/K.fold)+1):(k*floor(n/K.fold))]]<-k
  }
  results<-NULL
  t<-1
  K<-0
  for(K in 0:Q)
  {
    for(i in 1:length(alpha.list))
    {
      result.full<-siri.iter(x,y,H,K,alpha.list[i],niter,range.linear,range.interact,range.sis)
      #print(result.full)
      cv<-NULL
      if(!is.null(result.full))
      {
        cv<-siri.cv(x,y,div,H,K,alpha.list[i],niter,range.linear,range.interact,range.sis,result.full)
      }
      results[[t]]<-list(result=result.full,div=div,cv=cv,K=K,alpha=alpha.list[i],range.linear=range.linear,range.interact=range.interact,range.sis=range.sis)
      print(results[[t]])
      t<-t+1
    }
  }
  return(results)
}