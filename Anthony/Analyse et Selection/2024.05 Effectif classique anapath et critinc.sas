
/******************************************************************************
* Programme: Chargement des donnees de l'etude MEDEA
* Description: Ce programme permet de charger les donnees de l'etude MEDEA 
*              en utilisant un utilitaire Git pour integrer les macros SAS
*              et des fonctions de chargement de donnees.
* Auteur: Anthony Mangin
* Date de creation: 2024-11-04
* Notes: Utilise le script "git_utils.sas" pour installer et gerer les macros
*        necessaires depuis un depot Git.
******************************************************************************/


/* local path */ 
%global pathRAW path pathin pathout DATEFILE study local_folder;   /* Declaration des variables globales ne pas toucher*/

%let path=C:\Users\a_mangin\Documents\GitHub\COB;

/* -------------------------PARTIE A CUSTO------------------------------------------*/
/* Declaration des chemins et variables globales */

/* Chemin reseau pour les fichiers de l'etude */

/* -------------------------NE PAS TOUCHER AU RESTE SANS SAVOIR CE QU'ON FAIT ! ------------------------------------------*/


%let pathprog = C:\Users\a_mangin\Documents\GitHub\COB;
%include "&pathprog\_autoexec.sas";  /* Chemin du script d'installation Git */


%macro update_raw(update=0);

* Macro de connexion ï¿½ Oracle;
%macro connexion(login,base,password,serveur,ora=ora);libname &ora oracle user=&login. password = &password. path=&serveur schema=&base. DBMAX_TEXT=32767;%MEND;

%if &update %then %do;
%connexion('cobinc','cobinc_ORA','sbam01','@macro4',ora=ora_incl);
%connexion('cobsuivi','cobsuivi_ORA','sbam01','@macro4',ora=ora_suiv);
%connexion('cobanap','cobanap_ora','copa50','@macro4',ora=ora_anap);
%connexion('cob_relec_qual','COBANAP_RELEC_ORA','jbam01','@macro4',ora=ora_rel); 


%raw_update;

libname ora_incl  clear;
libname ora_rel  clear;
libname ora_anap  clear;
libname ora_suiv  clear;
  
%end;
%mend;

%update_raw(update=1); /* mettre update=0 pour ne pas mettre à jour les données a partir de la base oracle */


%Run_mapping(update=1); /* mettre update=0 pour ne pas relancer le mapping et lire les données mappé déja présente */



data cis;
set stu.an_cystec;
length TYPEH $200.;
*if ANCCISEX = 1 or find(ANTPHISTOP,"CIS")>0 or find(ANSSTPUROP,"CIS")>0 ;
*if (ANCTNMT=8  or ANCCISEX = 1 or ANCCISAS=1 or( find(ANTPHISTOP,"CIS")>0 or find(ANSSTPUROP,"CIS")>0)) and v NE 2 ;
if v NE 2 ;
t=put(ANCTNMT,ANCTNMTANAP3.);
rename ANDPRELP=DT;
TYPEH=put(ANTPHISTO,ANTPHISTOANAP15.);
if TYPEH="Autre" then TYPEH=ANTPHISTOP;
keep anumpat t ANDPRELP v TYPEH ANCCISEX ANCCISAS;
run;


data cis2;
set stu.An_rtuv;
length TYPEH $200.;
*if ANCCISEX = 1 or find(ANTPHISTOP,"CIS")>0 or find(ANSSTPUROP,"CIS")>0 ;
*if (ARCLASTNM=8 or ARCISEX=1 or ARCISASS=1  or find(ARTPHISTOP,"CIS")>0  or find(ARTPUROP,"CIS")>0 )and V NE 2;
if v NE 2 ;
rename ARCISEX=ANCCISEX;
rename ARCISASS=ANCCISAS;
t=put(ARCLASTNM,ARCLASTNMANAP3.);
rename ARDPREL=dt;
TYPEH=put(ARTPHISTO,ARTPHISTOANAP15.);
if TYPEH="Autre" then TYPEH=ARTPHISTOP;
keep anumpat t TYPEH ARDPREL v ARCISEX ARCISASS;
run;

data cis3;
set cis cis2;
if not (DT=. and ANCCISEX=. and ANCCISAS=.);
if ANCCISEX=. then ANCCISEX=3;
if ANCCISAS=. then ANCCISAS=3;
label ANCCISAS="CIS associé"
ANCCISEX="CIS exclusif";
run;

proc sort; by anumpat ANCCISAS ANCCISEX;run;




data cis3; 
set cis3;
by anumpat;
if first.anumpat;
if ANCCISEX=3 then ANCCISEX=.;
if ANCCISAS=3 then ANCCISAS=.;
rename t=tbrut;
run;

/*
proc sql noprint; create table listpat as select anumpat, count(*) as nb from cis group by anumpat HAVING nb>1;quit;

proc sql noprint; create table cis_doubl as select a.* from cis a inner join listpat b on a.anumpat=b.anumpat;quit;

proc sort; by anumpat dt v;run;


proc freq data=cis;
table anumpat*ANCCISEX*ANCCISAS / list;
run;
*/

data test;
set stu.Cl_tvnim_suiv;
where NVBCG=1;
bcg=1;
keep anumpat bcg ;
run;

data test2;
set stu.Cl_tvnim;
where NIMBCG=1;
bcg=1;
keep anumpat bcg ;
run;

data bcg;
set test test2;
format bcg NIMBCGINCL.;
run;
proc sort nodupkey;by anumpat;
run;



Proc sql noprint;
create table stu.resume as
select a.anumpat,a.nbvisit,a.centre,a.SITE AS trialsite,a.SEXE,a.DNAIS,DINTRW, TPBRA as BRA_INCL, IDENBRA.DINCL as DINCL,FUME,CRITINC ,case when bcg=1 then 1 else 2 end as BCG " BCG en inclusion OU Suivi" format=NIMBCGINCL. ,NSDCD,CAUSDC,SORTETU,DSORTETU,MOTIFSORTI,MOTIFP,PDV,PDVDATE,PDVCOMMENT, i.* FROM INCL.DEMOGR a
left join INCL.Idenbra b on a.anumpat=b.anumpat 
left join INCL.Descpat c on a.anumpat=c.anumpat 
left join INCL.Econim  d on a.anumpat=d.anumpat 
left join INCL.Ecoimop e on a.anumpat=e.anumpat 
left join INCL.F_tabac f on a.anumpat=f.anumpat 
left join INCL.TRAITINC g on a.anumpat=g.anumpat 
left join INCL.Ecoimtr h on a.anumpat=h.anumpat 
left join SUIV.planing  on DEMOGR.anumpat= planing.anumpat
left join stu.an_tnm_incl i on a.anumpat=i.anumpat 
left join bcg j on a.anumpat=j.anumpat 


where demogr.anumpat NE "" and demogr.anumpat NE "personne non identifiee"
ORDER BY anumpat;
quit;

data stu.resume;
set stu.resume;
drop NBVISIT TRIALSITE crfpagecyclenumber crftitle;
label v="Source du rapport d'anapath"
TPBRA="Bras à l'inclusion"
DINCL="Date d'inclusion"
CAUSDC="Cause de décès si connu"
SORTETU="Patient sortie d'étude au cours du suivi"
CASASS="CIS associé"
CASEXL="CIS Excusif";
run;


proc sort data=stu.resume nodupkey; by anumpat;run;

ods excel file="&path\OUT\Effectif.xlsx";
proc print data=stu.resume noobs label;run;
ods excel close;
