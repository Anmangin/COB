 /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables cystectomie

 Ce fichier permet de cr�er les tables mapp�es concernant les cystectomie des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir �t� lanc�;


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

%macro suppr(table);
proc sql;
DROP TABLE &table.;
quit;
%MEND;


/*----------------------------------------------------------------------------------------------------------------------------------------------

		Mappage des tables cystectomie

------------------------------------------------------------------------------------------------------------------------------------------------*/

%DELETEformat(INCL,ECONIM,NIMCYSGHM,NIMCYSGHMINCL);
%DELETEformat(WORK,ECONIM,NIMCYSIN,NIMCYSININCL);

* Creation de la table cl_cystectomie_0 � partir des donn�es d'ECONIM;
data STU.CL_CYSTECTOMIE_0 ;
LENGTH CRFTITLE $20.;
set ECONIM;
run;

* Selectionne les cas o� la cystectomie est faite et renomme les variables pour les aligner avec les autres tables CYS;
data STU.CL_CYSTECTOMIE_0;
set STU.CL_CYSTECTOMIE_0;
rename
NIMCYS=CYS
NIMCYSDB=CYSDBH
NIMCYSFN=CYSFNH
NIMCYSIN=CYSIN
NIMCYSH=CYSH
NIMCYSCD=CYSCD
NIMCYSV=CYSV
NIMCYSGHM=CYSGHM
NIMCYSGDF=CYSGDF
NIMCYSCG=CYSCG
NIMEXE=EXE
NIMEXEP=EXEP
NIMURET=URET
NIMNEPH=NEPH
NIMTNEPH=TNEPH
NIMEXTP=EXTP
NIMDRV=DRV
NIMNEO=NEO
NIMNEODF=NEODF
NIMCYSOP=CYSOP
NIMCYSSG=CYSSG
NIMCYSTF=CYSTF
NIMCYSCL=CYSCL
NIMCYSSI=CYSSI
NIMCYSCP=CYSCP
NIMCYSCPT=CYSCOMP
NIMCYSMD=CYSMD
NIMCYSMDP=CYSMDP
SNIMCYSCH=IMCYSCH
NIMCYSCH=CYSCH
NIMCYSCHP=CYSCHP;
NEODFC=put(NIMNEODFC,3.);
;
/*where NIMCYS=1;*/
keep &ordervar  NIMCYS	NIMCYSDB	NIMCYSFN	
NIMCYSIN	NIMCYSH	NIMCYSCD	NIMCYSV	NIMCYSGHM	NIMCYSGDF	NIMCYSCG	NIMEXE	
NIMEXEP	NIMURET	NIMNEPH	NIMTNEPH	NIMEXTP	NIMDRV	NIMNEO	NIMNEODF	NIMNEODFC			
NIMCYSOP	NIMCYSSG	NIMCYSTF	NIMCYSCL	NIMCYSSI	NIMCYSCP	NIMCYSCPT	NIMCYSMD	
NIMCYSMDP	SNIMCYSCH	NIMCYSCH	NIMCYSCHP;
run;



* NIMDRVCT EST UNE ERREUR. CAR EN NUM�rique;
%DELETEformat(INCL,ECOIMOP,IMCYSGHM,IMCYSGHMsuiv);
%DELETEformat(WORK,ECOIMOP,IMCYSIN,IMCYSINSUIV);

* Creation de la table cl_cystectomie_1 � partir des donn�es d'ECOIMOP;
data STU.CL_CYSTECTOMIE_1;
set ECOIMOP;
rename 
IMCYS=CYS
IMCYSDBH=CYSDBH
IMCYSFNH=CYSFNH
IMCYSIN=CYSIN
IMCYSH=CYSH
IMCYSCD=CYSCD
IMCYSV=CYSV
IMCYSGHM=CYSGHM
IMCYSGDF=CYSGDF
IMCYSCG=CYSCG
IMEXE=EXE
IMEXEP=EXEP
IMURET=URET
IMNEPH=NEPH
IMTNEPH=TNEPH
IMEXTP=EXTP
IMDRV=DRV
IMNEO=NEO
IMNEODF=NEODF
IMNEODFC=NEODFC
IMDRVCT=DRVCT
IMCYSOP=CYSOP
IMCYSSG=CYSSG
IMCYSTF=CYSTF
IMCYSCL=CYSCL
IMCYSSI=CYSSI
IMCYSCP=CYSCP
IMCYSCOMP=CYSCOMP
IMCYSMD=CYSMD
IMCYSMDP=CYSMDP
IMCYSCH=CYSCH
IMCYSCHP=CYSCHP
;
/*where IMCYS=1;*/
KEEP  &ordervar  IMCYS	IMCYSDBH	IMCYSFNH	
IMCYSIN	IMCYSH	IMCYSCD	IMCYSV	IMCYSGHM	IMCYSGDF	IMCYSCG	IMEXE	IMEXEP	IMURET	IMNEPH	
IMTNEPH	IMEXTP	IMDRV	IMNEO	IMNEODF	IMNEODFC	IMDRVCT		IMCYSOP	IMCYSSG	IMCYSTF	IMCYSCL	
IMCYSSI	IMCYSCP	IMCYSCOMP	IMCYSMD	IMCYSMDP	IMCYSCH	IMCYSCHP;
run;


* Creation de la table cl_cystectomie_2 � partir des donn�es d'TVNIMPROGCYS (suivi);
%DELETEformat(SUIV,TVNIMPROGCYS,IMCYSGHM,IMCYSGHMSUIV);
%DELETEformat(WORK,TVNIMPROGCYS,IMCYSIN,IMCYSINSUIV);

data STU.CL_CYSTECTOMIE_2;
retain ESSAI anumpat ;
set TVNIMPROGCYS;
rename 
IMCYS=CYS
IMCYSDBH=CYSDBH
IMCYSFNH=CYSFNH
IMCYSIN=CYSIN
IMCYSH=CYSH
IMCYSCD=CYSCD
IMCYSV=CYSV
IMCYSGHM=CYSGHM
IMCYSGDF=CYSGDF
IMCYSCG=CYSCG
IMEXE=EXE
IMEXEP=EXEP
IMURET=URET
IMNEPH=NEPH
IMTNEPH=TNEPH
IMEXTP=EXTP
IMDRV=DRV
IMNEO=NEO
IMNEODF=NEODF
IMNEODFC=NEODFC
IMCYSOP=CYSOP
IMCYSSG=CYSSG
IMCYSTF=CYSTF
IMCYSCL=CYSCL
IMCYSSI=CYSSI
IMCYSCP=CYSCP
IMCYSCOMP=CYSCOMP
IMCYSMD=CYSMD
IMCYSMDP=CYSMDP
SNIMCYSCH=IMCYSCH
IMCYSCH=CYSCH
IMCYSCHP=CYSCHP
;
/*where IMCYS=1;*/
KEEP  &ordervar IMCYS	IMCYSDBH	
IMCYSFNH	IMCYSIN	IMCYSH	IMCYSCD	IMCYSV	IMCYSGHM	IMCYSGDF	IMCYSCG	IMEXE	
IMEXEP	IMURET	IMNEPH	IMTNEPH	IMEXTP	IMDRV	IMNEO	IMNEODF	IMNEODFC		
IMCYSOP	IMCYSSG	IMCYSTF	IMCYSCL	IMCYSSI	IMCYSCP	IMCYSCOMP IMCYSMD	IMCYSMDP	
SNIMCYSCH	IMCYSCH	IMCYSCHP;
run;



* Creation de la table cl_cystectomie_3 � partir des donn�es d'TVNIMRECI (suivi);
%DELETEformat(SUIV,TVNIMRECI,NVCYSGHM,NVCYSGHMSUIV);
%DELETEformat(WORK,TVNIMRECI,NVCYSIND,NVCYSINDSUIV);

data STU.CL_CYSTECTOMIE_3;
set TVNIMRECI;
CRFTITLE = "TVNIMRECI";
if NVCYSGHM="autre" then NVCYSGHM=NVCYSGHMP;
rename 
NVCYS=CYS
NVDCYSDB=CYSDBH
NVDCYSFN=CYSFNH
NVCYSIND=CYSIN
NVCISHO=CYSH
NVCISCP=CYSCD
NVCYSVOD=CYSV
NVCYSGHM=CYSGHM
NVCYSCUR=CYSCG
NVCYSTPEX=EXE
NVCYSTPEXP=EXEP
NVCYSURE=URET
NVCYSNP=NEPH
NVCYSNPTP=TNEPH
NVCYSAEX=EXTP
IMDRV=DRV
IMNEO=NEO
IMNEODF=NEODF
IMNEODFC=NEODFC

NVDURE=CYSOP
NBPERTS=CYSSG
NVTRANS=CYSTF
NVCULO=CYSCL
NVSEJ=CYSSI
IMCYSCP=CYSCP
IMCYSCOMP=CYSCOMP
IMCYSMD=CYSMD
IMCYSMDP=CYSMDP
SNIMCYSCH=IMCYSCH
IMCYSCH=CYSCH
IMCYSCHP=CYSCHP

;/*where NVCYS=1;*/
KEEP &ordervar  BRA  CCDSUIVI  NVCYS	NVDCYSDB	
NVDCYSFN	NVCYSIND	NVCISHO	NVCISCP	NVCYSVOD	NVCYSGHM	NVCYSCUR				
NVCYSTPEX	NVCYSTPEXP	NVCYSURE	NVCYSNP	NVCYSNPTP	NVCYSAEX	IMDRV	IMNEO	
IMNEODFC	IMNEODF		NVDURE	NBPERTS	NVTRANS	NVCULO	NVSEJ	IMCYSCP	IMCYSCOMP	
IMCYSMD	IMCYSMDP	SNIMCYSCH	IMCYSCH	IMCYSCHP;
run;


* Fusion des 4 tables de cystectomie;
data STU.CL_CYSTECTOMIE;
set STU.CL_CYSTECTOMIE_0 STU.CL_CYSTECTOMIE_1  STU.CL_CYSTECTOMIE_2  STU.CL_CYSTECTOMIE_3;
drop IMCYSCH;
run;
proc sort;by anumpat;run;

* Red�finit l'ordre des variables;
data STU.CL_CYSTECTOMIE;
retain &ordervar 	CYS	CYSDBH	CYSFNH	
CYSIN	CYSV	CYSH	CYSCD	CYSGHM	CYSGDF	CYSCG	EXE	EXEP	URET	NEPH	TNEPH	
EXTP	DRV	NEO	NEODF	NEODFC	NIMNEODFC	DRVCT	CYSOP	CYSSG	CYSTF	CYSCL	CYSSI	
CYSCP	CYSCOMP	CYSMD	CYSMDP	CYSCH	CYSCHP;
set STU.CL_CYSTECTOMIE;
run;

* Suppression des tables interm�diares de CYS;
%suppr(STU.Cl_cystectomie_0);
%suppr(STU.Cl_cystectomie_1);
%suppr(STU.Cl_cystectomie_2);
%suppr(STU.Cl_cystectomie_3);

* Supprime les tables interm�diaires de Work;
%suppr(Ecoimop); %suppr(econim);
%suppr(Tvnimprogcys);%suppr(Tvnimreci);

proc sort data=STU.CL_CYSTECTOMIE; ;by anumpat NUMVISIT;run;

/* filtre de fin */ 
data STU.CL_CYSTECTOMIE;;
set  STU.CL_CYSTECTOMIE;
if CRFPAGESTATUS GE 0;
/*drop visitname visitcyclenumber numvisit;*/
run;
proc sort data=STU.CL_CYSTECTOMIE ;by anumpat nbvisit;run;
