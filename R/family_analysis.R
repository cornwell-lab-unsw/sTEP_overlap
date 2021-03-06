
likelihood.test<-function (x, y = NULL, conservative = FALSE) 
{
  DNAME <- deparse(substitute(x))
  if (is.data.frame(x)) 
    x <- as.matrix(x)
  if (is.matrix(x)) {
    if (min(dim(x)) == 1) 
      x <- as.vector(x)
  }
  if (!is.matrix(x) && !is.null(y)) {
    if (length(x) != length(y)) 
      stop("x and y must have the same length")
    DNAME <- paste(DNAME, "and", deparse(substitute(y)))
    OK <- complete.cases(x, y)
    x <- as.factor(x[OK])
    y <- as.factor(y[OK])
    if ((nlevels(x) < 2) || (nlevels(y) < 2)) 
      stop("x and y must have at least 2 levels")
    x <- table(x, y)
  }
  if (any(x < 0) || any(is.na(x))) 
    stop("all entries of x must be nonnegative and finite")
  if ((n <- sum(x)) == 0) 
    stop("at least one entry of x must be positive")
  if (!is.matrix(x)) 
    stop("Could not make a 2-dimensional matrix")
  nrows <- nrow(x)
  ncols <- ncol(x)
  sr <- apply(x, 1, sum)
  sc <- apply(x, 2, sum)
  E <- outer(sr, sc, "*")/n
  g <- 0
  for (i in 1:nrows) {
    for (j in 1:ncols) {
      if (x[i, j] != 0) 
        g <- g + x[i, j] * log(x[i, j]/E[i, j])
    }
  }
  q <- 1
  if (conservative) {
    row.tot <- col.tot <- 0
    for (i in 1:nrows) {
      row.tot <- row.tot + 1/(sum(x[i, ]))
    }
    for (j in 1:ncols) {
      col.tot <- col.tot + 1/(sum(x[, j]))
    }
    q <- 1 + ((n * row.tot - 1) * (n * col.tot - 1))/(6 * 
                                                        n * (ncols - 1) * (nrows - 1))
  }
  STATISTIC <- G <- 2 * g/q
  PARAMETER <- (nrow(x) - 1) * (ncol(x) - 1)
  PVAL <- 1 - pchisq(STATISTIC, df = PARAMETER)
  if (!conservative) 
    METHOD <- "Log likelihood ratio (G-test) test of independence without correction"
  else METHOD <- "Log likelihood ratio (G-test) test of independence with Williams' correction"
  names(STATISTIC) <- "Log likelihood ratio statistic (G)"
  names(PARAMETER) <- "X-squared df"
  names(PVAL) <- "p.value"
  structure(list(statistic = STATISTIC, parameter = PARAMETER, 
                 p.value = PVAL, method = METHOD, data.name = DNAME, observed = x, 
                 expected = E))
}


sync.species.lists<-function(sampled.list){
  read_csv("raw_data/tpl_names.txt")%>%
    dplyr::select(gs)%>%
    mutate(gs=gsub("_", " ", gs))->goodNames
  goodNames<-data.frame(gs=unique(goodNames$gs),stringsAsFactors=FALSE)
  goodNames$genera<-sapply(as.character(goodNames$gs),FUN=function(x) strsplit(x," ")[[1]][1],USE.NAMES=F)
  pl<-plant_lookup()
  goodNames$family<-pl$family[match(goodNames$genera,pl$genus)]
  goodNames$order<-pl$order[match(goodNames$genera,pl$genus)]
  goodNames$family[is.na(goodNames$family)]<-"bryo"
  goodNames$in.list<-goodNames$gs%in%sampled.list
  return(goodNames)
}

prepare.sampling.df<-function(sampled.list,ref.list){
  goodNames<-data.frame(gs=unique(ref.list),stringsAsFactors=FALSE)
  goodNames$genera<-sapply(as.character(goodNames$gs),FUN=function(x) strsplit(x," ")[[1]][1],USE.NAMES=F)
  pl<-plant_lookup()
  goodNames$family<-pl$family[match(goodNames$genera,pl$genus)]
  goodNames$in.list<-goodNames$gs%in%sampled.list
  goodNames<-filter(goodNames,!is.na(family))
  return(goodNames)
}




test.family<-function(family.in,goodNames=goodNames){
  #print(family.in)
  goodNames$family.of.interest<-goodNames$family==family.in
  if(sum(goodNames$family.of.interest,na.rm=T)>0){
    return(likelihood.test(goodNames$in.list,goodNames$family.of.interest))
  }
  return(NA)
}

calc.proportion<-function(family.in,goodNames=goodNames){
  #print(family.in)
  fam.only<-filter(goodNames,family==family.in)
  return(sum(fam.only$in.list)/length(fam.only$in.list))
}

#read.in.try<-function(){
#  require(dplyr)
#  read_csv("TryAccSpecies.txt",col_names="AccSpeciesName")%>%
#    dplyr::select(AccSpeciesName)%>%
#    mutate(sp.fix=use.synonym.lookup(AccSpeciesName))->try.all
#  try.sp<-unique(try.all$sp.fix)
#  return(try.sp)
#}

process.endemic.list<-function(sp.names){
  sp.names%>%
    mutate(sp.fix=use.synonym.lookup(species))->endem.fixed
  endemic.out<-unique(endem.fixed$sp.fix)
  return(endemic.out)
}

read.genBank<-function(){
  # this is the genbank species list from the NCBI Browser website
  read.delim("genbank_spp_clean.txt",header=FALSE,as.is=T)%>%
    mutate(V3=use.synonym.lookup(V1))->genbank.all
  genbank<-unique(genbank.all$V3)
  return(genbank)
}


# fread("species_centers.txt")%>%
#   dplyr::select(sp=V2)%>%
#   mutate(sp=scrub(sp))%>%
#   mutate(sp=use.synonym.lookup(sp))->gbif
#goodNames<-sync.species.lists(gbif$sp)

firstup <- function(x) {
   substr(x, 1, 1) <- toupper(substr(x, 1, 1))
x
}

# genbank<-read.genBank()
# oceania<-process.endemic.list(known.oceania)
# oceania.try<-prepare.sampling.df(sampled.list = try.sp,ref.list = oceania)
# aussie.try<-prepare.sampling.df(sampled.list = try.sp,ref.list = aussie)
# ocenaia.genbank<-prepare.sampling.df(sampled.list=genbank,ref.list=oceania)
run_family_analysis<-function(db_list){
  goodNames<-sync.species.lists(firstup(db_list))
  database_mean_sampling<-mean(goodNames$in.list)

  #oceania.try<-filter(oceania.try,!is.na(family))
  family.list<-as.list(unique(goodNames$family))
  test<-mclapply(family.list,FUN=test.family,goodNames=goodNames)
  

  g<-unlist(lapply(test,function(x)x$statistic))
  p<-unlist(lapply(test,function(x)x$p.value))
  prop<-unlist(lapply(test,function(x)x$observed[2,2]/sum(x$observed[,2])))
  sr<-unlist(lapply(test,function(x)sum(x$observed[,2])))
  
  data.table(family=unlist(family.list),prop.sampled=prop,sr=sr,g=g,p=p)%>%
    arrange(g)->ranking
  
  under<-filter(ranking,prop.sampled<database_mean_sampling)
  under<-arrange(under,desc(g))
  
  over<-filter(ranking,prop.sampled>database_mean_sampling)
  over<-arrange(over,desc(g))

  return(rbind(under[1:10,],over[1:10,]))
}

do_big_list_family_anlysis<-function(){
  try_sp<-read.in.try()
  t_try<-run_family_analysis(try_sp)
  write_csv(t_try,"tables/try_families_ranking.csv")
  genb_sp<-read.genBank()
  t_gb<-run_family_analysis(genb_sp)
  write_csv(t_gb,"tables/genbank_families_ranking.csv")
  a<-get_gbif()
  gb_sp<-unique(a$species)
  rm(a)
  gc()
  #gb_sp<-use.synonym.lookup(scrub(gb_sp))
  t_gbif<-run_family_analysis(gb_sp)
  write_csv(t_gbif,"tables/gbif_families_ranking.csv")
  well_studied_sp <- gb_sp[gb_sp%in%try_sp & gb_sp %in% genb_sp]
  ws_out<-run_family_analysis(well_studied_sp)
 
  t_all<-rbind(t_try,t_gb,t_gbif,ws_out)
  t_all$prop.sampled<-round(t_all$prop.sampled,4)
  t_all$db<-c(rep("try",20),rep("genbank",20),rep("gbif",20),rep("well_studied",20))
  write_csv(t_all,"tables/all_families_ranking.csv")
  #print(xtable(t_all,caption="this is a caption"),file="tables/all_families_ranking.tex",booktabs=TRUE,floating=FALSE,caption.placement="top")
}
  


perform_endemic_analysis<-function(cont_name,db,one=one){
  one.p<-filter(one,!is.na(cont))
  out<-prepare.sampling.df(db,one.p$species[one.p$cont_name==cont_name])
  
  if(sum(out$in.list)==0){
    return(NA)
  }
  
  family.list<-as.list(unique(out$family))
  test<-lapply(family.list,FUN=test.family,goodNames=out)
  
  g<-unlist(lapply(test,function(x)x$statistic))
  p<-unlist(lapply(test,function(x)x$p.value))
  prop<-unlist(lapply(test,function(x)x$observed[2,2]/sum(x$observed[,2])))
  sr<-unlist(lapply(test,function(x)sum(x$observed[,2])))
  
results<-data_frame(family=unlist(family.list),prop.sampled=prop,sr=sr,g=g,p=p,cont_name=cont_name)
 # db=deparse(db))
  under<-filter(results,prop.sampled<0.3) # hack here to get undersampled only
  under<-arrange(under,desc(g))
  return(under[1:3,])
}

do.endemic.analysis<-function(){
  one<-read_csv("one_cont_list.csv")
  try.sp<-firstup(read.in.try())
  genbank<-firstup(read.genBank())
  one<-filter(one,!is.na(cont))
  one<-filter(one,cont!=2)
  one$cont_name<-as.character(one$cont)
  one$cont_name<-recode(one$cont_name, "1" = "Africa","3"="Asia","4"="Australia","5"="Europe",
                                        "6" = "N. America", "7"="NZ and Oceania","8"="S.America")

  try_by_cont<-mclapply(as.list(unique(one$cont_name)),perform_endemic_analysis,db=try.sp,one=one)
  gb_by_cont<-mclapply(as.list(unique(one$cont_name)),perform_endemic_analysis,db=genbank,one=one)

  sum.df<-bind_rows(try_by_cont,gb_by_cont)

  sum.df$db<-c(rep("try",21),rep("genbank",21))
    write_csv(sum.df,"tables/summary_of_endemic_analysis.csv")
    return(sum.df)
}

## TRY

# Global for TRY: Acanthaceae, Orchidaceae

#North America = Dryopteridaceae
#Australia = Lamiaceae
#Asia = Gesneriaceae
#Africa = Apocynaceae
#S America = Asteraceae
#Oceania = Rubiaceae
#Europe = Asteraceae


## GenBank

#Europe = Asteraceae
#Asia = Myrtaceae
#Australia = Hypnaceae
#North America = Myrtaceae
#South America = Asteraceae
#Oceania = Euphorbiaceae
#Africa = Acanthaceae

process_family_output<-function(test){
  #sr<-summarize(group_by(goodNames,family),length(gs))
  g<-unlist(lapply(test,function(x)x$statistic))
  p<-unlist(lapply(test,function(x)x$p.value))
  prop<-unlist(lapply(test,function(x)x$observed[2,2]/sum(x$observed[,2])))
  sr<-unlist(lapply(test,function(x)sum(x$observed[,2])))
  
  a<-test.family("Euphorbiaceae",goodNames)
  calc.proportion("Euphorbiaceae",ocenaia.genbank)
  
  
  data.table(family=unlist(family.list),prop.sampled=prop,sr=sr,g=g,p=p)%>%
    arrange(g)->ranking
  
  
  
  mean(ranking$prop.sampled,na.rm=T)
  
  filter(ranking,prop.sampled<mean(prop.sampled,na.rm=T))%>%
    arrange(desc(g))->oceania.try.fam
  
  stargazer(aussie.try.fam[1:5,], summary=FALSE)
}
