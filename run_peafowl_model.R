#run_peafowl_model.R
# This file samples from a Bayesian hierarchical model of peahen gaze at
# peacocks. Each region of interest on the males is treated as having an 
# independent intrinsic attractiveness, controlling for area.

# import the rjags package
suppressPackageStartupMessages(library(rjags))
load.module('glm')

# Now get ready to choose a model:
# 1) Choose a model type 
# 1 = Overdispersed Poisson 
# 2 = Negative Binomial
# 3 = OD Poisson (include eye as a factor)
# 4 = OD Poisson (exclude female effects)
model = 1

# 2) Now choose a side of the bird (0 = back, 1 = front):
side = 1

if (model == 1){
  modstr = 'poisson'
  suffix = ''
} else if (model == 2){
  modstr = 'negbin'
  suffix = ''
} else if (model == 3){
  modstr = 'poisson_eye'
  suffix = '_eye'
} else if (model == 4){
  modstr = 'poisson_nofem'
  suffix = '_nofem'
}

bugstr=paste(modstr,".bug",sep="")

if (side){
  datstr=paste('peafowl_front',suffix,'.R',sep='')
  maxcount=10000
  setstr = 'front'
} else {
  datstr=paste('peafowl_back',suffix,'.R',sep='')
  maxcount=1000
  setstr = 'back'
}

# 3) Read in data and initialize JAGS model:
d <- read.jagsdata(datstr)
m <- jags.model(bugstr, d, n.chains=5,n.adapt=1000)

# 4) Update the chain (burn-in):
update(m,5000)

# 5) Sample from the model:
if (model==1){
  qnames = c(d$roinames,'Mean',c('female std','male std','disp std'))
  x <- coda.samples(m, c('beta','mstd','fstd','odstd','B','N','M'), n.iter=20000,thin=100)
} else if (model==2){
  qnames = c(d$roinames,'Mean',paste('plook',d$roinames),c('female std','male std'))
  x <- coda.samples(m, c('beta','mstd','fstd','r','B','N','lp','M'), n.iter=20000,thin=100)
} else if (model==3){
  qnames = c(d$roinames,'Mean','Eye',c('female std','male std','disp std'))
  x <- coda.samples(m, c('beta','mstd','fstd','odstd','B','N','M','E','C'), n.iter=8000,thin=40)
} else if (model==4){
  qnames = c(d$roinames,'Mean',c('male std','disp std'))
  x <- coda.samples(m, c('beta','mstd','odstd','B','N','M'), n.iter=20000,thin=100)
}

# 6) Now, do diagnostics:
jagssum=summary(x)
ss<-jagssum$statistics
qq<-jagssum$quantiles
rejectionRate(x)
ff=effectiveSize(x)
xx = do.call(rbind,x)

# 7) Grab quantiles for most the important variables:
sel=grepl('B',rownames(qq))|grepl('M',rownames(qq))|grepl('E',rownames(qq))|grepl('lp',rownames(qq))|grepl('std',rownames(qq))
post.quants=qq[sel,] #posterior quantiles
rownames(post.quants) <- qnames #label correctly
write.table(post.quants,file=paste(paste('quants',setstr,modstr,sep='_'),'.csv',sep=''),
            row.names=TRUE,col.names=NA,sep=',')

# 8) Posterior predictive checking: 
# The plan is to assemble a data frame from fake data simulated from the 
# fitted model.

# Load up the reshape library
suppressPackageStartupMessages(library(reshape))

# Now take a random subset of samples drawn from the fitted model:
roi = factor(d$roi,labels=d$roinames) #roi labels
ngrab = 100 #number of samples data sets
# the JAGS models sample the counts (N) from the fitted model
csel = grepl('N',colnames(xx)) #columns containing simulated fixation numbers
rsel = sample(dim(xx)[1],ngrab) #rows to select
fakedat=data.frame(roi=roi,count=t(xx[rsel,csel])) #simulated dataframe
fkdt = melt(fakedat,id='roi')
simdat = subset(fkdt,select=c('roi','value'))
names(simdat) <- c('roi','count')
simdat$issim = 'simulated'

# Get ready to plot original data:
olddat = data.frame(roi=roi,count=d$count,issim='actual')
alldat = rbind(simdat,olddat)
alldat <- transform(alldat,issim = factor(issim))

#plot it!
# Use ggplot2:
suppressPackageStartupMessages(library(ggplot2))
ph = qplot(count,y=..density..,data=alldat,geom="histogram",facets=issim~roi)
ph = ph + scale_x_log10(limits=c(1,maxcount))
ggsave(filename=paste(modstr,'_',setstr,'.pdf',sep=''), plot=ph, width=11, height=8.5)
