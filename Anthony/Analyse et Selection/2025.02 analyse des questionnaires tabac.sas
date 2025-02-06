
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






proc sql noprint; create table DDN as select  anumpat, max(vpla) as Max_visit format=ddmmYY10.  from  stu.et_planing group by anumpat;quit;

proc sql noprint; create table tabac as select a.*,Max_visit,TABAC,ARETFUME,TBCAD,TBCPRO,CANAB from stu.resume a left join stu.dm_demographie b on a.anumpat=b.anumpat
left join DDN c on a.anumpat=c.anumpat ;quit;



data suivtabac;
set stu.Dm_tabac_suivi;
where DJFUME NE . and vpla NE .;
keep anumpat v vpla NBVISIT DJFUME ACTFUME MQTETABAC;
run;
proc sort; by anumpat nbvisit;run;
proc sql noprint; create table stat_tabac as select anumpat , sum(case when vpla NE . then 1 else 0 end ) as nb_rep, min(vpla) as min_suivi format=DDMMYY10.,  max(vpla) as max_suivi format=DDMMYY10., max(case when ACTFUME=1 then 1 else 0 end) as FUMESUIV  from suivtabac group by anumpat;quit;


data final;
merge tabac stat_tabac;
by anumpat;
run;

proc format;
value stat_tabac
0="Non fumeur"
1="Fumeur"
2="Ancien fumeur";
;
data final; set final;
format stat_tabac stat_tabac.;
if FUME=1 and ARETFUME=1 then stat_tabac=2;
else if FUME=1 then stat_tabac=1;
else if FUME=2 then stat_tabac=0;
if nb_rep>0 then Suivi="Oui";else suivi="NOn";
NBDAY_SUIV=intck('day',DINCL,max_suivi);
if PDVDATE>Max_visit then Max_visit=PDVDATE;
suiv_total=intck('day',DINCL,Max_visit);

format pct PERCENT.;
pct=NBDAY_SUIV/suiv_total;

run;
proc sort;by stat_tabac;run;


proc freq data=final;
title "statut dabagique et suivi du statut tabagique";
table stat_tabac*Suivi / nopercent norow nocol missing ;

label Suivi =" Suivi tabagique";
run;

proc means data=final;

title "Nombre de questionnaire de suivi tabagique moyen en fonction du statut tabagique à l'inclusion";
by stat_tabac;

var nb_rep NBDAY_SUIV pct ; 

label nb_rep="Nombre de questionnaire";
label NBDAY_SUIV="Nomre de jours de suivi dabagique";
label pct="Pourcentage de suivi tabagique vs suivi total";
run;

title;
