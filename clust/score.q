.ml.loadfile`:util/init.q
\d .ml

/---Scoring metrics---\

/Davies-Bouldin index (euclidean distance only)
/* x = results table (idx, clt, pts) produced by .clust.ml.cure/dbscan/hc/kmeans
clust.daviesbouldin:{
 n:count v:value exec a:avg pts,p:pts by clt from x;
 s:avg each clust.i.scdist[`edist]'[v`p;v`a];
 (sum{[s;a;x;y]max(s[y]+s e)%'clust.i.scdist[`edist;a e:x except y;a y]}[s;v`a;t]each t:til n)%n}

/Dunn Index
/* x = results table (idx, clt, pts) produced by .clust.ml.cure/dbscan/hc/kmeans
/* y = distance metric as a symbol
clust.dunn:{
 t:til count v:value exec pts,mx:max .ml.clust.i.dintra[pts;y]by clt from x;
 mn:min raze clust.i.dinter[y;v`pts;t]each t;
 mn%max raze v`mx}

/Elbow method
/* x = data
/* y = distance
/* z = maximum number of clusters
clust.elbow:{{sum exec sum .ml.clust.i.scdist[y;pts;avg pts]by clt from clust.kmeans[x;z;100;1b;y]}[x;y]each 2+til z-1}

/Silhouette coefficient for entire dataset
/* x = results table (idx, clt, pts) produced by .clust.ml.cure/dbscan/hc/kmeans
/* y = distance metric as a symbol
/* z = boolean(1b) if average coefficient
clust.silhouette:{$[z;avg;]exec .ml.clust.i.sil[y;pts;group clt;1%(count each group clt)-1]'[clt;pts]from x}

/Homogeneity Score
/*x = actual cluster values
/*y = predicted cluster values
clust.homogeneity:{
 if[count[x]<>n:count y;'`$"distinct lengths - lenght of lists has to be the same"];
 if[not e:clust.i.entropy y;:1.];
 cm:value confmat[x;y];
 nm:(*\:/:).((count each group@)each(x;y))@\:til count cm;
 mi:(sum/)0^cm*.[-;log(n*cm;nm)]%n;
 mi%e}

/---Utils---\

/intercluster distances
/* df = distance metric
/* p  = points per cluster
/* x = til number of clusters
/* y = index of the cluster
clust.i.dinter:{[df;p;x;y]{(min/)clust.i.scdist[x;y]each z}[df;p y]each p x except til 1+y}

/intra-cluster distances
/* x = points in the cluster
/* y = distance metric
clust.i.dintra:{raze{[df;p;x;y]clust.i.scdist[df;p x except til 1+y;p y]}[y;x;n]each n:til count x}

/entropy
/* x = distribution
clust.i.entropy:{neg sum(p%n)*(-). log(p;n:sum p:count each group x)}

/Silhouette coefficient
/* pts = points in the dataset
/* i   = clusters of all points
/* k   = coefficient to multiply by
/* c   = cluster of the point
/* p   = point
clust.i.sil:{[df;pts;i;k;c;p]
 d:clust.i.scdist[df;;p]each pts i;
 (%).((-).;max)@\:(min avg each;k[c]*sum@)@'d@/:(key[i]except c;c)}

/distance calc
/* x = distance metric
/* y = list of points
/* z = single point
clust.i.scdist:{clust.i.dd[x]each y-\:z}

/Homogeneity Score
/*x = predicted cluster vales
/*y = actual cluster values
clust.homogeneitysc:{
 pi:value count each group x; /
 ent:neg sum(pi%sum pi)*(log[pi]-log(sum pi));  /entropy of pred values
 cm:((count distinct x),count distinct y)#0;
 cont:sum {[x;y;z] .[x;y,z;:;1]}[cm]'[x;y];
 nz_val:(raze cont)except 0;
 contsum:sum nz_val;
 logcont:log(nz_val);
 contnm:nz_val%contsum;
 nonz:flip raze (til count cont),''where each cont<>0; /nonzero elements
 out:(pis:sum cont)[last nonz]*(pjs:sum each cont)[first nonz];
 logout:(neg log[out])+(log[sum pis]+log[sum pjs]);
 mi:sum (contnm*(logcont-log[contsum]))+contnm*logout;
 mi%ent}

