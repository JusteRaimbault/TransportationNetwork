

gamma<-function(g){
  return(list(
    vcount=vcount(g),
    ecount=ecount(g),
    gamma = 2*ecount(g)/(vcount(g)*(vcount(g)-1)),
    meanDegree = mean(degree(g)),
    mu = ecount(g) - vcount(g) + 1,
    alpha = (ecount(g) - vcount(g) + 1)/(2*vcount(g)-5)
  )
  )
}


#'
#'
normalizedBetweenness<-function(g,subsample=0,cutoff=0,ego.order=0){
  if(subsample>0){
    m=as_adjacency_matrix(g)
    inds = sample.int(n = nrow(m),size = floor(subsample*nrow(m)),replace = F)
    g=graph_from_adjacency_matrix(m[inds,inds])
  }
  show(paste0('computing betwenness for graph of size ',vcount(g),' with cutoff ',cutoff))
  if(cutoff==0){
    if(ego.order==0){
      bw = edge_betweenness(g)*2/(vcount(g)*(vcount(g)-1))
    }else{
      show('bootstrapping betwenness')
      # TODO
    }
  }else{
    bw = estimate_edge_betweenness(g,cutoff=cutoff)*2/(vcount(g)*(vcount(g)-1))
    # normalization should be a bit different with cutoff ?
    # let approximate
  }
  y=sort(log(bw),decreasing=T)
  reg = lm(data=data.frame(x=log(1:length(which(is.finite(y)))),y=y[is.finite(y)]),formula = y~x)
  return(
    list(
      #bw=bw,
      meanBetweenness = mean(bw),
      stdBetweenness = sd(bw),
      alphaBetweenness = reg$coefficients[2]
    )
  )
}


#'
#' @description includes closeness, efficiency, and diameter
#'      note : distances are not weighted for comparison purposes between synthetic and real
#'      , meaning that we consider only topological distance.
shortestPathMeasures<-function(g){
  distmat = distances(g)
  distmatfinite = distmat
  distmatfinite[!is.finite(distmatfinite)]=0
  # get diameter
  diameter = max(distmatfinite)
  #show(diameter)
  # get closeness
  closenesses = (vcount(g)-1) / rowSums(distmatfinite[rowSums(distmatfinite)>0,])
  #show(closenesses)
  y=sort(log(closenesses/diameter),decreasing=T)
  reg = lm(data=data.frame(x=log(1:length(which(is.finite(y)))),y=y[is.finite(y)]),formula = y~x)
  # compute efficiency
  diag(distmat)<-Inf
  efficiency=mean(1/distmat)
  return(list(
    diameter=diameter,
    efficiency=efficiency,
    meanCloseness=mean(closenesses)/diameter,
    alphaCloseness=reg$coefficients[2]
  ))
}

#'
#'
clustCoef<-function(g){
  return(list(transitivity=transitivity(g)))
}

#'
#'
louvainModularity<-function(g){
  com=cluster_louvain(g)
  return(list(
    modularity = max(com$modularity)
  ))
}




#'
#' from SpatioTempCausality/functions.R -> incorporate ?
computeAccess<-function(accessorigdata,accessdestdata=NULL,matfun,d0=1,mode="time"){
  if(is.null(dim(accessorigdata))){
    # simple data vector
    weightmat = exp(-matfun / d0)
    data = accessorigdata
    potod = which(names(data)%in%rownames(weightmat)&!is.na(data))
    if(mode=="time"){Pi=rep(1,length(potod));Pj=matrix(rep(1,length(potod)),nrow=length(potod))}
    if(mode=="weighteddest"){Pi=rep(1,length(potod));Pj=matrix(data[potod],nrow=length(potod))}
    if(mode=="weightedboth"){Pi=data[potod];Pj=matrix(data[potod],nrow=length(potod))}
    access = Pi*((weightmat[,names(data)[potod]]%*%Pj)[names(data)[potod],])
    return(access)
  }else{
    # data frame of yearly data
    accessyears = unique(accessorigdata$year)
    allaccess = data.frame()
    for(year in accessyears){
      if(is.matrix(matfun)){weightmat=matfun}else{weightmat=matfun(year)}
      yearlyaccessorig = accessorigdata[accessorigdata$year==year,]
      potorig = which(yearlyaccessorig$id%in%rownames(weightmat)&!is.na(yearlyaccessorig$var))
      potdest = which(accessdestdata$id%in%colnames(weightmat)&!is.na(accessdestdata$var))
      Pi = yearlyaccessorig$var[potorig];
      Ej = matrix(accessdestdata$var[potdest],nrow=length(potdest))
      access = Pi*(weightmat[,accessdestdata$id[potdest]]%*%Ej)[yearlyaccessorig$id[potorig],]#/(sum(Pi)*sum(Ej)*sum(weightmat[yearlyaccessorig$id[potorig],accessdestdata$id[potdest]]))
      allaccess=rbind(allaccess,data.frame(var = access,id=names(access),year=rep(year,length(access))))
      rm(weightmat);gc()
    }
    allaccess$id=as.character(allaccess$id);allaccess$year=as.character(allaccess$year)
    return(allaccess)
  }
}



