
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
%global  path   DATEFILE study ;   /* Declaration des variables globales ne pas toucher*/

%let path=C:\Users\a_mangin\Documents\GitHub\COB;


%let daterep=%sysfunc(today(),date8.);
%let datetemp=%sysfunc(today(),yymmdd9.);
data _null_;test=strip("&datetemp");datefileL=tranwrd(test,"-",".");call symputx('datefile',datefileL);run;

%put &daterep;
%put &datefile;

/*%let ACTUEL=ACTUEL;*/
%let ACTUEL=&datefile;
%put &actuel;

/* -------------------------PARTIE A CUSTO------------------------------------------*/
/* Declaration des chemins et variables globales */

/* Chemin reseau pour les fichiers de l'etude */

/* -------------------------NE PAS TOUCHER AU RESTE SANS SAVOIR CE QU'ON FAIT ! ------------------------------------------*/
%let ordervar= essai site  anumpat  NBVISIT    bra  vnf v vpla crftitle crfpagecyclenumber CRFPAGESTATUS;
%let ordervar_g= essai site  anumpat  NBVISIT    bra  vnf v vpla recidive crftitle crfpagecyclenumber repeatnumber CRFPAGESTATUS;



%let pathprog = \\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Mapping France Cohorte\Commun_France_cohorte;
%include "&pathprog/00_autoexec.sas";  /* Chemin du script d'installation Git */


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

