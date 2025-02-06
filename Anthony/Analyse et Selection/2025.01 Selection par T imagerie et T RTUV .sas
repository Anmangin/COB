
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





/*
brouillon de selection patient a partir d'imagerie et de T d'RTUV

*/

data imagerie;
set stu.cl_imagerie;
if NBVISIT=0 and Adenop NE ""   and strip(Adenop) NE "." ;
if Adenop NE "Non" then cN="+";
else cN="-";
run;
data imagerie;
set imagerie;
format fCN $2.;
retain fCN;
by anumpat;
if first.anumpat then fCN="";
if cN="+" then fCN="N+";
IM_done="1";
if last.anumpat and fCN="" then fCN="N-";
if last.anumpat;
keep anumpat FCN;
;run;

data An_tnm_all;
set stu.An_tnm_all;
if crftitle="RTUV Anatomopathologie" and V NE 2 and V NE 5;
run;

data Cl_cystectomie;
set stu.Cl_cystectomie;
if NBVISIT=0 and CYS=1;
run;
proc sort;by anumpat;run;
data Cl_cystectomie;
set Cl_cystectomie; 
by anumpat;
if First.anumpat;
rename CYS=CYSINCL;
label CYS="Cystectomie à l'inclusion";
keep anumpat CYS;
run;

data patient_TVNIM_PROG;
set stu.cl_TVNIM_suiv;
if recidive=2 or PRDEVNT NE . or PRPROG=1 or PROGMET=1 ;
PROG="TVNIM->TVIM";
keep anumpat PROG;
run;
data patient_TVNIM_PROG;
set patient_TVNIM_PROG;
by anumpat;
if last.anumpat;
run;

proc sql noprint ;create table TNM_RTUV as select anumpat, max(TF) as TF 'T RTUV' format=t. from An_tnm_all group by anumpat;quit;

proc sql noprint; create table resume as select a.*,b.TTIRTV "RTUV saisie dans la base clinique",c.TF, case  when d.FCN ne "" then FCN else "Nx" end as cN "N imagerie",e.CYSINCL,f.prog  from stu.resume a 
left join stu.Cl_rtuv b on a.anumpat=b.anumpat and b.NBVISIT=0 and b.crftitle="RTUV principale"
left join TNM_RTUV c on a.anumpat=c.anumpat
left join imagerie d  on a.anumpat=d.anumpat
left join Cl_cystectomie e on  a.anumpat=e.anumpat
left join patient_TVNIM_PROG f on  a.anumpat=f.anumpat;
;quit;


data resume2;
set resume;
label Filtre1="Filtre 1 Doit etre TVIM";
format Filtre1 Filtre2 Filtre3 PDVSUIV3.;
if BRA_INCL=1 then Filtre1 = 1;
else Filtre1=2;

label Filtre2="Critère 2 : CRITINC=1 ou CRITINC=2";
if critinc=1 or critinc=2 then Filtre2 = 1;
else Filtre2=2;


label Filtre3="ANAPATH DE RTUV T2 minimum";
if Tf>6 then Filtre3 = 1;
else Filtre3=2;

/*if PROG NE "" or (Filtre1=1 and Filtre2=1 and Filtre3=1 );*/
if CYSINCL=. then CYSINCL=2;

if Filtre1=1 and Filtre2=1 and Filtre3=1 then SELECTION="TVIM Qui respecte les critères";
else if PROG NE "" then SELECTION="TVNIM qui progresse";

label Warning1="Warning T Manquant";
if critinc=1  and TTIRTV=1 and TF=. then Warning1="T manquant a demander ?";
else if critinc=1  and TTIRTV NE 1 then Warning1="RTUV MANQUANTE ?";
keep ANUMPAT BRA_INCL  prog Critinc TTIRTV CYSINCL  Tf cN Filtre1 Filtre2 Filtre3 Warning1;
run;


data test;
set resume;
where BRA_INCL=1 and (critinc=1 or critinc=2 )and Tf=.;
run;


data resume2;
set resume;
where BRA_INCL=1 and ( critinc=1 or (critinc=2  and TTIRTV=1)) and TF>6 and IM_done="1";
run;



