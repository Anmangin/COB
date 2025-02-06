 /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables RTUV

 Ce fichier permet de créer les tables mappées concernant les RTUV des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir été lancé;

/*----------------------------------------------------------------------------------------------------------------------------------------------

					Les Macros

---------------------------------------------------------------------------------------------------------------------------------------------------*/

%macro DELETEformat(LIBNAME,table,var,format);
data &table;
set &LIBNAME..&table;
var2=put(&var,&format..);
drop &var;
run;
data &table;
set &table;
format &var $100.;
&var=var2;
drop var2;
run;
%mend;

%macro replace(oldtable,table);
data &table;
set &oldtable;
run;
%suppr(&oldtable);
%MEND;

%macro suppr(table);
proc sql;
DROP TABLE &table.;
quit;
%MEND;


%macro mapping(table);

	data STU.&table.;
	set incl.&table. suiv.&table.;
	run;
%mend;
	
/*----------------------------------------------------------------------------------------------------------------------------------------------

		Association de tous les RTUV

------------------------------------------------------------------------------------------------------------------------------------------------*/

* Fusionne les 2 tables RTUV supplémentaires (inclusion et suivie) et renomme la table fusionnée CL_RTUV;
%mapping(RTUVSUP);
%replace(STU.RTUVSUP,STU.CL_RTUV);

* Retire toutes les fiches RTUV supplémentaires vides;
data STU.CL_RTUV;
format CRFTITLE $20.;
length CRFTITLE $20.;
set STU.CL_RTUV;
run;
data STU.CL_RTUV;
set STU.CL_RTUV;
/*CRFTITLE="RTUVSUP"; if NBRTUV=. and TTIR2HEX=. then delete*/ /* PGU : à décommenter ou supprimer cette partie */
;run;

* Renomme les variables pour les faire correspondre à celles des autres tables RTUV;
data STU.CL_RTUV;
retain &ordervar;
set STU.CL_RTUV;

CRFTITLE="RTUV supplementaire";
rename 
TTIR2MOT=TTIRMOT
TTIRT2MOTP=TTIRTMOTP
TTIR2HEX=TTIRTHEX
TTIR2NBI=TTIRTNBI
TTIR2LIT=TTIRLIT
TTIR2NV=TTIRNV
TTIR2DBH=TTIDBH
TTIR2FNH=TTIFNH
TTIR2H=TTIRH
TTIR2CD=TTIRHCD
TTIR2GHM=TTIGHM
TTIR2GDF=TTIGHMDF
;
run;



* Récupère les RTUV principales de l'inclusion;
data STU.CL_RTUV_1;
set incl.Traitinc;
CRFTITLE = "RTUV principale";
visitname="inclusion";
NBRTUV = 1;
/*where TTIRTV=1;*/
run;

proc sort ;by anumpat;run; /* PGU : ???? à supprimer */

/* Fusionne les tables RTUV princispale inclusion avec la table des RTUVS supplémentaires et supprime la table intermédiaire;*/
data STU.CL_RTUV;
set  STU.CL_RTUV STU.CL_RTUV_1;
run;
proc sort; by anumpat;run; /* PGU : ???? à supprimer */

%suppr(STU.CL_RTUV_1);


* Récupère les RTUV principales du suivi;
data STU.CL_RTUV_2;
retain ESSAI anumpat  CRFTITLE FORMU CCDSUIVI NBVISIT ;
set SUIV.TVNIMRECI;
/*if NF1=1 or (DNVHOSDB=. and DNVHOSFN=. and NVGHM=. ) then delete;*/
CRFTITLE = "TVNIMRECI";
drop  formu CCBRA  NVBCG NVBCGDB	NVBCGFN	NVBCGPRT	NVBCGPRTP	NVBCGSVI	NVBCGSVIP	
NVAE NVDAEBD	NVDAEFN	NVAEINS	NVAESVI	NVAESVIP	NVAUTE	NVAUTENOM	NVAUTENB	NVCYS	
NVDCYSDB NVDCYSFN	NVCYSIND	NVCISHO	NVCISCP	NVCYSVOD	NVCYSGHM	NVCYSGHMP	NVCYSCUR	
NVCYSTPEX	NVCYSTPEXP	NVCYSURE	NVCYSNP	NVCYSNPTP	NVCYSAEX	NVCUR	NVCURES	NVURDR	NVURDRES	
NVURGH	NVURGHRES	NVURET	NVURETRES	NVAUTR	NVAUTRP	NVAUTRRES	NVDURI	IMDRV	IMNEO	IMNEODF	IMNEODFC	
IMDRVCT	IMDRVCTC	NVDURE	NBPERTS	NVTRANS	NVCULO	NVSEJ	IMCYSCP	IMCYSCOMP	IMCYSMD	IMCYSMDP	SNIMCYSCH	
IMCYSCH	IMCYSCHP; 
run;

* Renomme les variables pour les aligner avec les autres tables RTUV;
data STU.CL_RTUV_2;
set STU.CL_RTUV_2;
rename DNVRES=DTTIRT
DNVHOSDB=TTIDBH
DNVHOSFN=TTIFNH
NVGHM=TTIGHM
NVGHMP=TTIGHMDF
NVURE=TTILOCUR
NVTRI=TTILOCTR
NVDOM=TTILOCDO
NVCOL=TTILOCCV
NVATDR=TTILOCLD
NVATGH=TTILOCLG
NVFANT=TTILOCFA
NVMEADR=TTILOCMD
NVMEAGH=TTILOCMG
NVTALTV=TTIGTMES
NVASP=TTIGTASP
NVBASE=TTIGTBAS
NVRESEC=TTIGTTOT
NVBIOPS=TTIBP
NVIPOP=TTIIPOP
NVASPCIS=TTIRTCIS
NVHINCL=TTIRH
NVNBTU=TTIRTNB
NVHEX=TTIRTHEX
NVNBI=TTIRTNBI
NVCPOST=TTIRHCD
;
/*where CCDSUIVI NE . or DNVRES NE . or NVHEX NE .;*/
;
run;

* Ajoute les RTUV suivi à la table fusionnant les RTUV inclusion et supplémentaires;
* PGU: valeurs CRFTITLE devrait être aussi renommé sur le même modèle que les autres tables;
data STU.CL_rtuv_2;
length CRFTITLE $20.;
format CRFTITLE $20.;
set STU.CL_rtuv_2;
run;


data STU.CL_rtuv;

set STU.CL_rtuv STU.CL_rtuv_2;
run;
%suppr(STU.CL_rtuv_2);
proc sort; by anumpat;run;

* Retire format de TTIGHM;
data STU.CL_rtuv;
set STU.CL_rtuv;
rename TTIGHM=TTIR2GHM;
run;
%DELETEformat(STU,CL_rtuv,TTIR2GHM,TTIR2GHMINCL);

data STU.CL_rtuv;
set CL_rtuv;
rename TTIR2GHM=TTIGHM;
run;


* Dernières modifications sur la table mappée;
data STU.CL_rtuv;
set STU.CL_rtuv;
if TTIGHM=:"au" then TTIGHM=TTIGHMDF;
if index(TTIGHM,'-')>0 then TTIGHM=SUBSTR(TTIGHM,3,LENGTH(TTIGHM)-2);
drop   TTIGHMDF    ;
label NBRTUV = "Numéro RTUV";
run;

data STU.CL_rtuv;
retain &ordervar;
set STU.CL_rtuv;
format TTIRTHEX TTIRTNBIINCL.;
format TTIRTNBI TTIRTNBIINCL.;
if NBVISIT=. and visitname NE "" and find(visitname,"16")=0 and visitname NE "inclusion" then NBVISIT=input(substr(visitname,length(NBVISIT)-2,2),2.);
else if NBVISIT=. and find(visitname,"16")>0 then NBVISIT="16" + visitcyclenumber - 1 ;
else NBVISIT=0;

drop CCBRA ASEXE	TTIRTV2 AAGE	CCCENT	FORMU	CCDSVPRE	NUMLIGN	CCRECIPRO	ERRBRA	VFORM	TPVISIT	CCNEPASREM	CCDSUIVI	DESAC	SECRTUV	CENT	IDPAT	IDCOB
 
;run;
proc sort;by anumpat NBVISIT;run;



/* retrait des lignes non pertinente */
data STU.CL_rtuv;
set STU.CL_rtuv;

if NBRTUV = . and TTIRTV=.  and TTIDBH=. Then delete;
 run;

/* note perso 


01-143 -> mauvais bras

 */



%suppr(CL_rtuv);
