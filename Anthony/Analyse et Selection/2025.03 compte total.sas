


data atest;
set stu.resume;
   WHERE anumpat IN (
        '01-018', '01-120', '01-171', '01-197', '01-263', '01-299', '01-315', '01-352', '01-363',
        '04-033', '04-057', '04-060', '04-066', '06-011', '06-016', '06-131', '09-020', '09-024',
        '10-054', '10-064', '12-126', '13-098', '13-215', '16-083', '19-041'
    );
run;

/*
Je dois rendre prochainement un rapport scientifique COBLAnCE à l'ANR. Pourriez-vous me donner les infos suivantes :
nombre (et %) de patients décédés durant les 6 ans de suivi
nombre (et %) de patients perdus de vue durant les 6 ans de suivi
nombre (et %) de patients encore vivants à 6 ans de suivi
nombre (et %) de patients ayant eu au moins 1 récidive au cours du suivi

Merci++

Simone
*/

proc format ;
value YNNA
1 = "Oui"
2 = "Non"
3 = "Non connu (suivi manquant sans précision)"
4= "PDV AVANT";
run;



proc sql noprint; create table pat as select  distinct anumpat,v,PRDEVNT, PRPROG from stu.Cl_tvnim_suiv where PRPROG NE . and PRDEVNT ne .;quit;



proc sql noprint; create table max_dt as select  anumpat,max(vpla) as max_visit format=DDMMYY10.,
max(case when RECIPRO=1 then 1 else 0 end) as TVNIMreci,
max(case when RECIPRO=2 then 1 else 0 end) as TVNIMPROG   from suiv.Planing_planing1 GROUP BY ANUMPAT,vnf HAVING vnf ne 1;quit;

proc sql noprint; create table resume as select * from stu.resume a left join max_dt b on a.anumpat=b.anumpat;quit;

data resume; set resume; 
if TVNIMreci NE 1 then TVNIMreci=.;
if TVNIMPROG NE 1 then TVNIMPROG=.;
format finsuivi DDMMYY10.; 
finsuivi=DINCL + int(365.25 * 6);
format VV6an YNNA.;
if PDVDATE NE . and PDVDATE<finsuivi then NBPDV=1;
if  NSDDC<finsuivi and NSDDC NE . then   NBDC=1;
if NSDDC>0 and finsuivi>=NSDDC then VV6an=2;
else if  NSDDC>0 and finsuivi<NSDDC then VV6an=1;
else if  PDVDATE>0 and finsuivi<PDVDATE then VV6an=1;
else if  DNN>0 and finsuivi<DNN then VV6an=1;
else if  max_visit>0 and finsuivi<max_visit then VV6an=1;

else if  PDVDATE>0 and finsuivi>PDVDATE then VV6an=4;
else VV6an=3;


nbjour = intck("day",max_visit,finsuivi);

run;

proc freq data=resume;
table VV6an*CENTRE ;
run;

data atest;
set resume;
where VV6an=3 and nbjour<180;
run;

proc means data=resume;
var nbjour;
where VV6an="3";
run;



proc sql noprint; create table aatest as select count(*) as NBTT "Nombre total", count(NBDC) as NBDC  "Nombre de décès durant les 6 ans de suivi", 
sum(case when VV6an = 1 then 1 else 0 end ) as nbvie  "Nombre de patients en vie 6 ans après l'inclusion",
count(NBPDV) as NBPDV "Nombre de perdu de vue" ,
count(TVNIMreci) as TVNIMreci "Nombre de patient TVNIM recidive ",
count(TVNIMPROG) as TVNIMPROG "Nombre de patient TVNIM progression "

from resume
;quit;
