/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier D'importation des bases oracle de coblance

 Ce fichier importe les donn�es brutes sur le reseau pour permettre � tous les utilisateurs de travailler sans la licence oracle
V1 20/10/2020 -> Anthony M
V2 04/09/2023 -> Anthony M revu pour France Cohorte

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* Liste des macrovariables a param�trer : path (d�finit dans le fichier FINAL_EXE.sas qui appelle ce code);
* N�cessite Oracle 64bit et Licence SAS/Oracle pour fonctionner;
* Reserver aux DM;

* Nom du fichier pour trouver le path;
/*%let pathRAW=&path_prog\Base de donn�e SAS;*/
 *---------------------------------------------- ;

* Cr�er le dossier RAW o� se trouvera les donn�es brutes de la base oracle au moment de l'�xecution de ce code;



%macro CreatFolder(dossier);
	filename dossier "&dossier";
    option NOXWAIT;  /* Permet de retourner automatiquement a SAS apres l execution de la commande */
	%if %sysfunc(fexist(dossier))= 0 %then %do;
    x mkdir "&dossier.";  /* Creation du dossier en commande DOS */
	%end;
	%else %put NOTE: le dossier &dossier existe deja.;
%mend;
%CreatFolder(&path\load\RAW\RAW);




%MACRO suppr(table);proc sql noprint; Drop Table &table;quit;%mend;

/* Macro Getlib : Cree un dossier et le place en libname */
%macro Getlib(nom,dossier);
filename dossier "&dossier";
%if %sysfunc(fexist(dossier)) = 0 %then %do;
option NOXWAIT;
x mkdir "&dossier.";
%end;
libname &nom "&dossier.";
%mend;



 * Sous macro pour vider une libname et �viter les probl�mes d'import;
%macro vider(lib);
data nomtable ;set sashelp.vstable;where libname=upcase("&lib.");if memname='TIMEDOWN' or memname='timedown' or memname="nomtable" then delete;run;
proc sql noprint;select distinct count(*) into: nbtable from nomtable; quit;
%do i=1 %to &nbtable.;data _null_ ;set nomtable; if _N_=&i then call symput("memname",memname) ; run;%suppr(&lib..&memname.);%end;
%mend;


* Macro pour copier les table d'une libname � l'autre, avec un argument optionnel pour retirer une ou plusieurs table;
%macro copie(in,stu,exclude=NULL);
%vider(&STU);proc copy in=&in out=&STU memtype=data;%if &exclude NE NULL %then %do;exclude &exclude;%end;run;
%mend;



%macro raw_update;

* Importation de la base Cobinc_ORA;

%Getlib(Rawincl,&path\load\RAW\incl);
%copie(ora_incl,Rawincl,exclude=dataitemresponse);


* Suppression de certaines tables et variables;
/* les tables suivante ont vit� �t� "supprim�" de la base. on peut pas les retirer totalement a cause du systeme de l'eCRF assez ridide, alors il faut les retirer sous sas. il s'agit
de l'ancien m�thode de collecte de l'anapath, on a fait une base appart par la suite */

%suppr(rawincl.Anameta);%suppr(rawincl.Cysanap);%suppr(rawincl.Cysanap_loca_sieg);%suppr(rawincl.Relect1);
%suppr(rawincl.Relect2);%suppr(rawincl.Rtuvanap1);%suppr(rawincl.Rtuvrelec1);*%suppr(rawincl.Relect1);


/* afin de rester coh�rent, on retire �galement ces tables de la liste des tables */

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
%Getlib(rawsuiv,&path\load\RAW\suiv);
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
%Getlib(rawanap,&path\load\RAW\anap);
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
%Getlib(rawrel,&path\load\RAW\relec);
%copie(ora_rel,rawrel,exclude=dataitemresponse);


data rawrel.crfpage;
set	 rawrel.crfpage;
if  upcase(CRFPAGECODE)=upcase("trash") then delete;
run; 

%mend;



