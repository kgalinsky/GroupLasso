n=100
m_X<-5
m_W<-1
m_G<-50
m_I<-m_G
SNR<-10
tau1<-1


for(i in 1:100){
set.seed(i+1000)

# Generate X and Y
sigma<-cov_block(m_G,.3,10)
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

x0<-rep(0,dim(x)[2])
#### Cross Validation finding best lambda for Group Lasso
lamb_candidate<-seq(1,20,2)
lamb_candidate2<-seq(1,5,1)
sol_cv<-opt_lambda(x,y,f, gradf, g, proxg, x0, tau1, max_iters = 100, w = 10, 
                   backtrack = TRUE, recordIterates = FALSE, stepsizeShrink = 0.5, 
                   eps_n = 1e-15,m_X,m_W,m_G,m_I,K=10,n=100, lamb_candidate, lamb_candidate2,restart=TRUE,beta)
lamb_loc<-which(sol_cv$mean+sol_cv$var == min(sol_cv$mean+sol_cv$var), arr.ind = TRUE)
lamb_opt_glasso<-lamb_candidate[lamb_loc[1]]
lamb_opt2_glasso<-lamb_candidate2[lamb_loc[2]]
saveRDS(sol_cv,file=paste0("C://Users//auz5836//Documents//GitHub//GroupLasso//Final_Simu//50//sol_cv_glasso_",i,".RData"))
}