 /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables hospitalisation

 Ce fichier permet de créer les tables mappées concernant les hospitalisation des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas,
              07_mapping RTUV.sas
		   et 08_mapping cystectomie.sas doivent avoir été lancés;


/*----------------------------------------------------------------------------------------------------------------------------------------------

					Les Macros

---------------------------------------------------------------------------------------------------------------------------------------------------*/


%macro mapping(table);

	%etude(incl.&table.,COBINC);
	%etude(suiv.&table.,COBSUIVI);

	data STU.&table.;
	set incl.&table. suiv.&table.;
	run;
%mend;

%macro replace(oldtable,table);
data &table;
set &oldtable;
run;
%suppr(&oldtable);
%MEND;


/*----------------------------------------------------------------------------------------------------------------------------------------------

		Mappage des tables hospitalisation

------------------------------------------------------------------------------------------------------------------------------------------------*/

* Fusionne les tables REHOSPT de incl et suivi en une table STU.REHOSPT;
* PG: la macro génère plusieurs erreurs et warnings. A revoir;
%mapping(Rehospt);

* PROC format pour l'hospitalisation;
proc format lib=stu;
value mymotif 
1 = Retention
2=Hemorragie
3=Perforation vesicale
4=Infection
5=Classe I
6=Classe II
7=Classe III
8=Classe IV
9=Autre
11=Motif Chirurgical
12=Motif Medical
13=Soins Paliatifs
14=Radiofrequence
15=Complications
16=Traitement physique
17=Alteration de l etat general
18=Toxicite de chimiotherapie
19=Autre;
run;

* Applique le format;
data STU.Rehospt;
set STU.Rehospt;
if TTIRHMOTS NE "" then TTIRHMOT=TTIRHMOTS +10 ;
format TTIRHMOT mymotif.;
motif=put(TTIRHMOT,mymotif.); 
drop TTIRHMOTS TTIRHMOT;
run;

* Renomme la table en CL_Hospi;
%replace(STU.rehospt,STU.CL_Hospi);

* Elimine les valeurs nulles de la table;
data STU.CL_Hospi;
set  stu.CL_Hospi;
/*if (TTIRHDB = . or TTIRH=2 )and TTIRHGHM="" and TTIRHREA=. then delete;*/
run;


/* WARNING: Cette partie nécessite d'avoir lancer 07_mapping RTUV.sas; */


* Récupère les RTUV de la table mappée CL_RTUV et met en forme la table;
data stu.atemp;
set stu.CL_RTUV;
/*if TTIDBH = . and TTIFNH=. and TTIRMOT=. and TTIGHM="" and TTIRHCD="" then delete ;*/
motif="RTUV";
TTIRMOT2=put(TTIRMOT,TTIR2MOTINCL.);
if TTIRMOT=4 then TTIRMOT2=TTIRTMOTP;
rename
TTIRH=TTIRHH
TTIDBH=TTIRHDB
TTIFNH=TTIRHFN
TTIRMOT2=TTIRHMOTP
TTIGHM=TTIRHGHM
;
 keep &ordervar TTIRH TTIRH TTIDBH  TTIFNH TTIRMOT2 
TTIGHM TTIRHCD motif ;
run;

* Ajoute les RTUV à la table mappée CL_hospi;
data stu.CL_HOSPI;
length TTIRHGHM $6.;
set  stu.CL_HOSPI;
run;
data stu.atemp;
length TTIRHGHM $6.;
format TTIRHGHM $6.;
set  stu.atemp;
run;

data stu.CL_HOSPI;
set stu.CL_HOSPI  stu.atemp;
run;

* Supprime la table intermédiaire;
%suppr(stu.atemp);


/* WARNING: Cette partie nécessite d'avoir lancer 08_mapping cystectomie.sas; */

* Récupère les cystectomie de la table mappée CL_CYSTECTOMIE et met en forme la table;
data stu.atemp;
set stu.CL_CYSTECTOMIE;
LENGTH TTIRHGHM $6.;
motif="CYSTECTOMIE";

if CYSGDF ne "" then TTIRHGHM=CYSGDF; else TTIRHGHM=CYSGHM;
rename
CYSDBH=TTIRHDB
CYSFNH=TTIRHFN
CYSH=TTIRHH;
TTIRHMOTP=CYSIN;
if TTIRHGHM="" then TTIRHGHM="Manquant";
keep &ordervar CYSDBH CYSFNH CYSH   TTIRHMOTP TTIRHGHM motif ;
run;

* Ajoute les cystectomies à la table mappée CL_hospi;
data stu.CL_HOSPI;
set stu.CL_HOSPI stu.atemp;
run;
%suppr(stu.atemp);

data stu.CL_HOSPI;
set  stu.CL_HOSPI;
if CRFTITLE="" then CRFTITLE="REHOSPT";
run;


* Créer une table contenant les chirurgies non programmées;
%deleteformat(SUIV,TVIMREC,IMCHEXE,IMCHEXESUIV);

data stu.atemp;
set TVIMREC;
ESSAI="COBSUIVI";
motif="CHIRURGIE";
CRFTITLE="TVIMREC";
if IMCHEXE=:"Au" then IMCHEXE=IMCHEXEP;
rename
IMCHDB=TTIRHDB
IMCHFN=TTIRHFN
IMCHHSP=TTIRHH
IMCHEXE=TTIRHMOTP;
TTIRHGHM="Non demandé";
where (IMCHDB NE . or IMCHFN NE . or IMCHEXE NE "" )and 	IMCH=1;
keep &ordervar IMCHDB IMCHFN IMCHHSP   IMCHEXE  motif ;
run;

* Ajoute les chirurgies non programmées à la table mappée CL_hospi;
data stu.CL_HOSPI;
set stu.CL_HOSPI stu.atemp;
run;

data stu.cl_hospi;
set stu.cl_hospi;
if find(TTIRHGHM,'Man')>0 then TTIRHGHM="";
run;

* Fais le tri dans les variables de la table mappée;
data stu.cl_hospi;
retain &ordervar
TTIRH TTIRHDB TTIRHFN TTIRHH TTIRHCD TTIRHMOTP TTIRHCOMPL TTIRHMOTPR
 motif TTIRHGHM TTIRHREA TTIRHURO TTIRHHOPJ TTIRHCHI TTIRHAU TTIRHAUP;
set stu.cl_hospi;
if CRFPAGESTATUS GE 0;
drop CCCENT ASEXE CENT IDPAT IDCOB aage DESAC CCDSVPRE FORMU
CCRECIPRO ERRBRA VFORM NUMLIGN TPVISIT CCNEPASREM CCDSUIVI CCBRA NUMVISIT;
run;

* Supprime la table intermédiaire;
%suppr(tvimrec);
%suppr(stu.atemp);
proc sort data=stu.cl_hospi; by anumpat nbvisit;run;


/*

 PROC IMPORT OUT=reponse DATAFILE= "\\nas-01\SBE_ETUDES\COBLANCE\10-informations patients (anapath,etc)\GHM\Copie de GHM ct 01.xlsx" DBMS = xlsx REPLACE;
SHEET="Table 1 - Rapport détaillé e";
GETNAMES=YES;
RUN;



 PROC IMPORT OUT=listingall DATAFILE= "\\nas-01\SBE_ETUDES\COBLANCE\10-informations patients (anapath,etc)\GHM\Copie de GHM ct 01.xlsx" DBMS = xlsx REPLACE;
SHEET="séjour";									
GETNAMES=YES;
RUN; 






proc sql noprint;create table  ident as select distinct Nom_Pr_nom,	  Pat_N_  ,IPP from reponse order by Pat_N_ ;quit;

proc sql noprint;create table  toident as select  a.*, Nom_Pr_nom,	  Pat_N_  ,b.IPP as BIPP  from  listingall a  left join    ident b on   a.IPP=b.IPP  where A NE "" order by Pat_N_ ;quit;

data toident;
retain Pat_N_   entree2 Sortie  GHS GHM;
format 	  entree2 Sortie DDMMYY10.;
set toident;
entree2=input(Entr_e,DDMMYY10.);
rename GHM=GHM_XLS;
keep  Pat_N_   entree2 Sortie  GHS GHM;
run;

data orig_XLS;
retain Pat_N_   entree2 Sortie  GHS GHM;
format 	   entree2 Sortie DDMMYY10.;
Sortie=VAR10 ;
set reponse;
entree2=input(Date_de_debut,DDMMYY10.);
rename GHM=GHM_XLS2;
keep  Pat_N_   entree2 Sortie  GHS GHM Motif_hospitalisation;
run;


data test;
set stu.cl_hospi   ;
 run;

proc sql noprint; create table cl_hospi2 as select a.*,b.GHS "GHS XLS COMPLET",b.GHM_XLS "GHM XLS COMPLET",c.GHS as GHS2 " GHS XLS ONGLET 2", GHM_XLS2 "GHM XLS ONGLET2",Motif_hospitalisation from stu.cl_hospi a
left join  orig_XLS c on  localidentifier1=c.Pat_N_  and c.entree2=TTIRHDB and TTIRHFN=c.Sortie
left join  toident b on  localidentifier1=b.Pat_N_  and b.entree2=TTIRHDB and TTIRHFN=b.Sortie;
quit;

data stu.cl_hospi;
set cl_hospi2;
run;

data stu. FOCH_GHS_FULL;
set toident;
run;

%suppr(Cl_hospi2);%suppr(Ident);%suppr(Listingall);%suppr(Orig_xls);%suppr(Reponse);%suppr(Test);%suppr(Toident);
*/
