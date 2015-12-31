

get_cont_raster<-function(){
  library(sp) #Load your libraries
  library(maptools)
  library(raster)
  #Download the continents shapefile
  download.file("http://faculty.baruch.cuny.edu/geoportal/data/esri/world/continent.zip",
                "cont.zip")
  
    #Unzip it
  unzip("cont.zip")
  #Load it
  cont.shp <- readShapeSpatial("continent.shp")
  worldclim<-getData('worldclim', var='tmean', res=2.5)
  worldclim10<-getData('worldclim', var='tmean', res=10)
  
  cont.raster<-rasterize(cont.shp,worldclim,field="CONTINENT")
  writeRaster(cont.raster,"cont2.5.grd")
}


load.gbif<-function(){
  if (Sys.info()[[1]]=="Linux") a<-fread("../../../srv/scratch/z3484779/gbif/gbif_clean.txt")
  else a<-fread("occur.csv")
return(a)
}

plot_gbif<-function(g){
  pdf("figures/temp_fig.pdf")
  plot(g$decimalLatitude~g$decimalLongitude,pch=16)
  dev.off()
}

plot_gbif_bins<-function(a){
a$yes.no<-rbinom(dim(a)[1],prob=0.5,1)
sp<-SpatialPoints(cbind(as.numeric(a$decimalLongitude),as.numeric(a$decimalLatitude)))
sp<-SpatialPointsDataFrame(coords=sp,data=data.frame(ing=a$yes.no))
genbank.sampling.map<-rasterize(sp,worldclim10,field="ing",fun=mean)
pdf("figures/genbank.pdf")
plot(genbank.sampling.map,col=brewer.pal(9,"Blues"),main="Proportion of GBIF observations that are in GenBank")
#plot(cont.shp,add=TRUE,lwd = 0.3)
dev.off()
}





other_stuff<-function(){
#get_cont_raster()
cont<-raster("cont2.5.grd")
#a<-filter(a,!is.na(as.numeric(decimalLongitude)))
a$in.genbank<-a$species%in%genbank
a$in.try<-a$species%in%try.sp


sp<-SpatialPoints(cbind(as.numeric(a$decimalLongitude),as.numeric(a$decimalLatitude)))
sp<-SpatialPointsDataFrame(coords=sp,data=data.frame(ing=a$in.genbank,int=a$in.try))
genbank.sampling.map<-rasterize(sp,worldclim10,field="ing",fun=mean)
try.sampling.map<-rasterize(sp,worldclim10,field="int",fun=mean)

pdf("genbank.pdf")
plot(genbank.sampling.map,col=brewer.pal(9,"Blues"),main="Proportion of GBIF observations that are in GenBank")
#plot(cont.shp,add=TRUE,lwd = 0.3)
dev.off()

pdf("try-genbank.pdf")
plot(try.sampling.map,col=brewer.pal(9,"Blues"),main="Proportion of GBIF observations that are in TRY")
#plot(cont.shp,add=TRUE,lwd = 0.3)
dev.off()

sp<-SpatialPoints(cbind(as.numeric(a$decimalLongitude),as.numeric(a$decimalLatitude)))

cont.x<-extract(cont,sp)
a$cont<-cont.x

endemic<-summarize(group_by(a,species),num.cont=length(unique(cont)))
table(endemic$num.cont)
one.cont.endemics<-filter(endemic,num.cont==1)

filter(a,species%in%one.cont.endemics$species)%>%
  dplyr::select(species,cont)->one.cont.list

one.cont.list<-one.cont.list[!duplicated(one.cont.list$species),]

filter(one.cont.list,cont==4)%>%
  dplyr::select(species)->known.aussie.endemics

filter(one.cont.list,cont==7)%>%
  dplyr::select(species)->known.oceania
}