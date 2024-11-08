/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier D'importation des bases oracle de coblance

 Ce fichier importe les données brutes sur le reseau pour permettre à tous les utilisateurs de travailler sans la licence oracle
V1 20/10/2020 -> Anthony M
V2 04/09/2023 -> Anthony M revu pour France Cohorte

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* Liste des macrovariables a paramétrer : path (définit dans le fichier FINAL_EXE.sas qui appelle ce code);
* Nécessite Oracle 64bit et Licence SAS/Oracle pour fonctionner;
* Reserver aux DM;

* Nom du fichier pour trouver le path;
/*%let pathRAW=&path_prog\Base de donnée SAS;*/
 *---------------------------------------------- ;

* Créer le dossier RAW où se trouvera les données brutes de la base oracle au moment de l'éxecution de ce code;

%let pathRAW=\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\GITHUB\Base de donnée SAS\RAW;


%macro CreatFolder(dossier);
    option NOXWAIT;  /* Permet de retourner automatiquement a SAS apres l execution de la commande */
	%if %sysfunc(fexist(&dossier))= 0 %then %do;
    x mkdir "&dossier.";  /* Creation du dossier en commande DOS */
	%end;
	%else %put NOTE: le dossier &dossier existe deja.;
%mend;
%CreatFolder(&pathRAW\RAW);




%MACRO suppr(table);proc sql noprint; Drop Table &table;quit;%mend;

/* Macro Getlib : Cree un dossier et le place en libname */
%macro Getlib(nom, dossier);
    option NOXWAIT;  
    %if %sysfunc(fexist(&dossier)) = 0 %then %do;
        x mkdir "&dossier.";  /* Creation du dossier en commande DOS si inexistant */
    %end;
    libname &nom "&dossier."; /* Assignation de la libname */
    %vider(&nom);  /* Appel de la macro pour vider le contenu si necessaire */
%mend;



 * Sous macro pour vider une libname et éviter les problèmes d'import;
%macro vider(lib);
data nomtable ;set sashelp.vstable;where libname=upcase("&lib.");if memname='TIMEDOWN' or memname='timedown' or memname="nomtable" then delete;run;
proc sql noprint;select distinct count(*) into: nbtable from nomtable; quit;
%do i=1 %to &nbtable.;data _null_ ;set nomtable; if _N_=&i then call symput("memname",memname) ; run;%suppr(&lib..&memname.);%end;
%mend;


* Macro pour copier les table d'une libname à l'autre, avec un argument optionnel pour retirer une ou plusieurs table;
%macro copie(in,stu,exclude=NULL);
%vider(&STU);proc copy in=&in out=&STU memtype=data;%if &exclude NE NULL %then %do;exclude &exclude;%end;run;
%mend;



%macro raw_update;

* Importation de la base Cobinc_ORA;

%Getlib(Rawincl,&pathRAW\incl);
%copie(ora_incl,Rawincl,exclude=dataitemresponse);


* Suppression de certaines tables et variables;
/* les tables suivante ont vité été "supprimé" de la base. on peut pas les retirer totalement a cause du systeme de l'eCRF assez ridide, alors il faut les retirer sous sas. il s'agit
de l'ancien méthode de collecte de l'anapath, on a fait une base appart par la suite */

%suppr(rawincl.Anameta);%suppr(rawincl.Cysanap);%suppr(rawincl.Cysanap_loca_sieg);%suppr(rawincl.Relect1);
%suppr(rawincl.Relect2);%suppr(rawincl.Rtuvanap1);%suppr(rawincl.Rtuvrelec1);*%suppr(rawincl.Relect1);


/* afin de rester cohérent, on retire également ces tables de la liste des tables */

data rawincl.crfpage;
set	 rawincl.crfpage;
if CRFPAGECODE=upcase("Anameta") or CRFPAGECODE=upcase("Cysanap") or  CRFPAGECODE=upcase("Cysanap_loca_sieg") or  CRFPAGECODE=upcase("Relect1") or CRFPAGECODE=upcase("Relect2") 
or CRFPAGECODE=upcase("Rtuvanap1") or 
CRFPAGECODE=upcase("Rtuvrelec1") or CRFPAGECODE=upcase("Relect1") or CRFPAGECODE=upcase("DM") then delete;
run; 
data rawincl.dataviewtables;
set	 rawincl.dataviewtables;
if DATAVIEWNAME=upcase("Anameta") or DATAVIEWNAME=upcase("Cysanap") or  DATAVIEWNAME=upcase("Cysanap_loca_sieg") or  DATAVIEWNAME=upcase("Relect1") or DATAVIEWNAME=upcase("Relect2") 
or DATAVIEWNAME=upcase("Rtuvanap1") or 
DATAVIEWNAME=upcase("Rtuvrelec1") or DATAVIEWNAME=upcase("Relect1") or DATAVIEWNAME=upcase("DM") then delete;
run; 



* Importation de la base Cosuivi_ORA;
%Getlib(rawsuiv,&pathRAW\RAW\suiv);
%copie(ora_suiv,rawsuiv,exclude=dataitemresponse);

/* idem que pour l'inclusion */
%suppr(rawsuiv.Anameta);%suppr(rawsuiv.Cysanap);%suppr(rawsuiv.Relect1); %suppr(rawsuiv.Cysanap_loc_sieg);
%suppr(rawsuiv.Relect2);%suppr(rawsuiv.Rtuvanap1);%suppr(rawsuiv.Rtuvrelec1);
data rawsuiv.crfpage;
set	 rawsuiv.crfpage;
if CRFPAGECODE=upcase("Anameta") or CRFPAGECODE=upcase("Cysanap") or  CRFPAGECODE=upcase("Cysanap_loc_sieg") or  CRFPAGECODE=upcase("Relect1") or CRFPAGECODE=upcase("Relect2") 
or CRFPAGECODE=upcase("Rtuvanap1") or 
CRFPAGECODE=upcase("Rtuvrelec1") or CRFPAGECODE=upcase("Relect1") or CRFPAGECODE=upcase("DM") then delete;
run; 
data rawsuiv.dataviewtables;
set	 rawsuiv.dataviewtables;
if DATAVIEWNAME=upcase("Anameta") or DATAVIEWNAME=upcase("Cysanap") or  DATAVIEWNAME=upcase("Cysanap_loc_sieg") or  DATAVIEWNAME=upcase("Relect1") or DATAVIEWNAME=upcase("Relect2") 
or DATAVIEWNAME=upcase("Rtuvanap1") or 
DATAVIEWNAME=upcase("Rtuvrelec1") or DATAVIEWNAME=upcase("Relect1") or DATAVIEWNAME=upcase("DM")
then delete;
run; 




* Importation de la base Cobanap_ORA;
%Getlib(rawanap,&pathRAW\RAW\anap);
%copie(ora_anap,rawanap,exclude=dataitemresponse);

%suppr(rawanap.Rtuvrelec1);%suppr(rawanap.Rtuvrelec1_sous_1);%suppr(rawanap.Rtuvrelec1_uro_st1);
%suppr(rawanap.Relect2);%suppr(rawanap.Relect2_uro_sous1);%suppr(rawanap.Relect1);%suppr(rawanap.Relect1_uro_sous1);

data rawanap.crfpage;
set	 rawanap.crfpage;
if CRFPAGECODE=upcase("Rtuvrelec1") or CRFPAGECODE=upcase("Rtuvrelec1_sous_1") or  CRFPAGECODE=upcase("Rtuvrelec1_uro_st1")
or CRFPAGECODE=upcase("Relect2") or 
CRFPAGECODE=upcase("Relect2_uro_sous1") or CRFPAGECODE=upcase("Relect1") or CRFPAGECODE=upcase("Relect1_uro_sous1") then delete;
run; 
data rawanap.dataviewtables;
set	 rawanap.dataviewtables;
if DATAVIEWNAME=upcase("Rtuvrelec1") or DATAVIEWNAME=upcase("Rtuvrelec1_sous_1") or  DATAVIEWNAME=upcase("Rtuvrelec1_uro_st1") or  DATAVIEWNAME=upcase("Relect1") or DATAVIEWNAME=upcase("Relect2") 
or DATAVIEWNAME=upcase("Relect2") or 
DATAVIEWNAME=upcase("Relect2_uro_sous1") or DATAVIEWNAME=upcase("Relect1") or DATAVIEWNAME=upcase("Relect1_uro_sous1")
then delete;
run; 





* Importation de la base relec;
%Getlib(rawrel,&pathRAW\RAW\relec);
%copie(ora_rel,rawrel,exclude=dataitemresponse);


data rawrel.crfpage;
set	 rawrel.crfpage;
if  upcase(CRFPAGECODE)=upcase("trash") then delete;
run; 

%mend;



