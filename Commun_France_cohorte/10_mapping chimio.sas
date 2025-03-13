/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables chimio

 Ce fichier permet de créer les tables mappées concernant la chimiothérapie des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas 
		   et 05_mapping de la partie clinique.sas doivent avoir été lancés;


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

* Créer une table intermédiaire contenant les chimio de 1ère ligne à l'inclusion;
data chimio_temp1;
length IMCHMDFD 8.;
format TPTR $50.;
length TPTR $50.;

set incl.Ecoimtr_autr_proto;
rename IMCHMDCI=DCI
IMCHMDFD=DOSE
IMCHMUNIT=UNIT
IMCHMDFQ=NBCYCLE;
TPTR="CHIMIO LIGNE 1";
label TPTR="Type traitment";
where ACTIV11=1;
drop ACTIV11;
run;

* Créer une table intermédiaire contenant les chimio de 2nd ligne à l'inclusion;
data chimio_temp2;
length IMCHM2DD 8.;
format TPTR $50.;
length TPTR $50.;

set incl.Ecoimtr_autr2_prot;
where ACTIV12=1;

rename IMCHM2DCI=DCI
IMCHM2DD=DOSE
IMCHM2UNIT=UNIT
IMCHM2DQ=NBCYCLE;
TPTR="CHIMIO LIGNE 2";
label TPTR="Type traitment";
drop ACTIV12 ;
run;

* Créer une table intermédiaire contenant les chimio du traitement cible durant le suivi;
%DELETEformat(SUIV,Tvimrec_traitci1,UNITE,UNITESUIV);
data chimio_temp3;
length IMTHCDS 8.;
format TPTR $50.;
length TPTR $50.;

set Tvimrec_traitci1;
rename IMTHCDCI=DCI
IMTHCDS=DOSE
IMTHCCL=NBCYCLE
UNITE=unit;
where ACTIV101=1;
TPTR="Traitement cible";
label TPTR="Type traitment";
drop ACTIV101 ;
run;

* Créer une table intermédiaire contenant les autres chimio durant le suivi;
%DELETEformat(SUIV,Tvimrec_traitem1,UNITEDOSE,UNITEDOSESUIV);
data chimio_temp4;
length IMCHIMDS 8.;
format TPTR $50.;
length TPTR $50.;

set Tvimrec_traitem1;


where ACTIV100=1;
rename IMCHIMDCI=DCI
IMCHIMDS=DOSE
UNITEDOSE=UNIT
IMCHIMCL=NBCYCLE;
TPTR="CHIMIO SUIVI TVIM (ligne1)";
drop ACTIV100 ;
run;

* Créer une table intermédiaire contenant les chimio de 1ère ligne au suivi;
data chimio_temp5;
length IMCHMDFD 8.;
format TPTR $50.;
length TPTR $50.;

set SUIV.Tvnimprogchim_a1;


rename IMCHMDCI=DCI
IMCHMDFD=DOSE
IMCHMUNIT=UNIT
IMCHMDFQ=NBCYCLE;
TPTR="CHIMIO LIGNE 1";
label TPTR="Type traitment";
where ACTIV11=1;
drop ACTIV11 ;
run;

* Créer une table intermédiaire contenant les chimio de 2nd ligne au suivi;
data chimio_temp6;
length IMCHM2DD 8.;
length TPTR $50.;

set SUIV.Tvnimprogchim_a2;
where ACTIV12=1;


rename IMCHM2DCI=DCI
IMCHM2DD=DOSE
IMCHM2UNIT=UNIT
IMCHM2DQ=NBCYCLE;

TPTR="CHIMIO LIGNE 2";
label TPTR="Type traitment";
drop ACTIV12 ;
run;

* Fusionne les 6 tables intermédiaires en une seule;
DATA CHIMIOTHERAPIE;
retain &ordervar;

length DCI UNIT $100.;
length DOSE 8.;
length TPTR $50.;
set chimio_temp1 chimio_temp2 chimio_temp3 chimio_temp4 chimio_temp5 chimio_temp6;
run;

* Supprime toutes les tables de travail;
%suppr(chimio_temp1);  %suppr(chimio_temp2);  %suppr(chimio_temp3);  %suppr(chimio_temp4);  %suppr(chimio_temp5);
%suppr(chimio_temp6);  %suppr(Tvimrec_traitci1); %suppr(Tvimrec_traitem1 );

* Applique une nomenclature commune pour le nom de la molécule DCI;
data chimiotherapie;
set chimiotherapie;
DCI = TRANWRD(DCI,'CHIMIO','');
DCI = TRANWRD(DCI,'N3','');
DCI = TRANWRD(DCI,'ADRIBLASTINE','DOXORUBICINE');
DCI = TRANWRD(DCI,'ADRIAMYCINE','DOXORUBICINE');
DCI = TRANWRD(DCI,'ENDOXAN','CYCLOPHOSPAMIDE');
DCI = TRANWRD(DCI,'GENZAR','GEMCITABINE');
DCI = TRANWRD(DCI,'GEMICITABINE','GEMCITABINE');
DCI = TRANWRD(DCI,'GEMITABINE','GEMCITABINE');
DCI = TRANWRD(DCI,'GEMZAR','GEMCITABINE');
DCI = TRANWRD(DCI,'JAVLOR','VINFLUNINE');
DCI = TRANWRD(DCI,'NAVELBINE','VINORELBINE');
*DCI = TRANWRD(DCI,'PACLITAXEL','TAXOL');
*DCI = TRANWRD(DCI,'PACLITAXEL (= TAXOL)','TAXOL');
DCI = TRANWRD(DCI,'PACLITAXEL (= TAXOL)','PACLITAXEL');
DCI = TRANWRD(DCI,'VINFLUNIME','VINFLUNINE');
DCI = TRANWRD(DCI,'VINFLUMINE','VINFLUNINE');
DCI = TRANWRD(DCI,'CARBOPLASTINE','CARBOPLATINE');
DCI = TRANWRD(DCI,'ETOPOXIDE','ETOPOSIDE');
DCI = TRANWRD(DCI,'TAXOL (= TAXOL)','TAXOL');
DCI = TRANWRD(DCI,'VINORELBINE','VINORELBINE');
DCI = TRANWRD(DCI,'TAXOL HEBDO','TAXOL');
DCI = TRANWRD(DCI,'TAXOL HEBDOMADAIRE','TAXOL');
DCI = TRANWRD(DCI,'TAXOLMADAIRE','TAXOL');
DCI = TRANWRD(DCI,'DOROXUBICINE','DOXORUBICINE');
DCI = TRANWRD(DCI,'GENCITABINE','GEMCITABINE');
*DCI = TRANWRD(DCI,'PAXLITAXEL','TAXOL');
DCI = TRANWRD(DCI,'PAXLITAXEL','PACLITAXEL');
DCI = TRANWRD(DCI,'CIPLASTINE','CISPLATINE');
DCI = TRANWRD(DCI,'MPDL 32 80A 1200MG IMMUNOTHERAPIE','MPDL3280A');
DCI = TRANWRD(DCI,'MP DL 3280 A','MPDL3280A');
DCI = TRANWRD(DCI,'VINORELBINE -VINORELBINE','VINORELBINE');
*DCI = TRANWRD(DCI,'PACITAXEL','TAXOL');
DCI = TRANWRD(DCI,'PACITAXEL','PACLITAXEL');
DCI = TRANWRD(DCI,'PACLITAXEL - TAXOL','PACLITAXEL');

 
		
/* codage 2021*/
DCI = TRANWRD(DCI,'TAXOLE','TAXOL');

DCI = TRANWRD(DCI,'METOTREXATE','METHOTREXATE');
DCI = TRANWRD(DCI,'METJOTREXATE','METHOTREXATE');
DCI = TRANWRD(DCI,'CARBOBLATINE','CARBOPLATINE');
DCI = TRANWRD(DCI,'CARBOPLATINE AUC 2','CARBOPLATINE');
 
 DCI = TRANWRD(DCI,'CARBOPLATINE HEBDOMADAIRE','CARBOPLATINE');


DCI = TRANWRD(DCI,'DOROXABICINE','DOXORUBICINE');
DCI = TRANWRD(DCI,'DOXORUBICINE','DOXORUBICINE');
DCI = TRANWRD(DCI,'DOXORUBICINE','DOXORUBICINE');

DCI = TRANWRD(DCI,'ECTOPOSIDE','ETOPOSIDE');
DCI = TRANWRD(DCI,'ETOPOSIDE','ETOPOSIDE');
DCI = TRANWRD(DCI,'ETOPOSIDE','ETOPOSIDE');
DCI = TRANWRD(DCI,'VP16','ETOPOSIDE');
 DCI = TRANWRD(DCI,'VP 16','ETOPOSIDE');

 DCI = TRANWRD(DCI,'G CI','GEMCITABINE');
if DCI='GEMCI' then DCI = TRANWRD(DCI,'GEMCI','GEMCITABINE');
DCI = TRANWRD(DCI,'E GEMCIABINE','GEMCITABINE');
DCI = TRANWRD(DCI,'GELCITABINE','GEMCITABINE');
DCI = TRANWRD(DCI,"GEMCITABINE (TTT D'ENTRETIEN)",'GEMCITABINE');
DCI = TRANWRD(DCI,"ATEZOLIZUMAB",'ATEZOLIZUMAB');
DCI = TRANWRD(DCI,"5FU",'C5FU');
DCI = TRANWRD(DCI,"5 FU",'C5FU');
DCI = TRANWRD(DCI,"5-FU",'C5FU');
DCI = TRANWRD(DCI,"5 FLUOROURACILE",'C5FU');	
DCI = TRANWRD(DCI,"FLUOROURACILE(5-FU)",'C5FU'); 
DCI = TRANWRD(DCI,"FLUOROURACILE(5 FU)",'C5FU');
 DCI = TRANWRD(DCI,"FLUOROURACILE(C5FU)",'C5FU');

		 
 	  
DCI = TRANWRD(DCI,"  VINORELBINE",'VINORELBINE');	 
DCI = TRANWRD(DCI,"VINORELBINE VINORELBINE",'VINORELBINE');		
DCI = TRANWRD(DCI,"VINFLULINE = VINFLUNINE",'VINFLUNINE');		
 


DCI = TRANWRD(DCI,"PEMBROZILUMAB",'PEMBROLIZUMAB');	
if find(DCI,"PEMBROLIZUMAB")=0 then DCI = TRANWRD(DCI,"PEMBRO",'PEMBROLIZUMAB');	

	
DCI = TRANWRD(DCI,"PANITUMUMAB (VECTIBIX)",'PANITUMUMAB');		
DCI = TRANWRD(DCI,'PACLITAXEL TAXOL','PACLITAXEL');
DCI = TRANWRD(DCI,'PACLITAXEL-TAXOL','PACLITAXEL');


DCI = TRANWRD(DCI,'ADRIAMYCINE','DOXORUBICINE'); /* c'est la meme molécule */
				    
 DCI = TRANWRD(DCI,"C5FU",'5FU');

 if DCI="G" then  DCI="GEMCITABINE";
 if DCI="CI" then DCI="CISPLATINE";
DCI = strip(DCI);
run;


* Ajoute un compteur de ligne de chimiothérapie;
proc sort data=CHIMIOTHERAPIE ; by anumpat   nbvisit TPTR ;run;
data CHIMIOTHERAPIE;set CHIMIOTHERAPIE;count=repeatnumber;run;
proc sort data =CHIMIOTHERAPIE ; by anumpat   nbvisit TPTR  ;run;


* Transpose la table en différents tableaux;
proc transpose data=CHIMIOTHERAPIE out=C1; by anumpat  nbvisit TPTR ;var DCI; run;
proc transpose data=CHIMIOTHERAPIE out=C2; by anumpat  nbvisit TPTR;var DOSE; run;
proc transpose data=CHIMIOTHERAPIE out=C3; by anumpat  nbvisit TPTR;var UNIT; run;
proc transpose data=CHIMIOTHERAPIE out=C4; by anumpat  nbvisit TPTR;var NBCYCLE;run;
 
* Macro pour éliminer les colonnes redondantes et renommer le reste;
%macro mychangechim(num,name);
proc sql noprint; select max(count) into : nbmax from CHIMIOTHERAPIE;quit;
%let nbmaxstr=%SYSFUNC(strip(&nbmax));
%put &nbmax;
data C&num;
set C&num;
rename col1-col&nbmaxstr=&name.1-&name.&nbmaxstr.;
drop _NAME_ _LABEL_;
run;
%MEND;
%mychangechim(1,DCI);
%mychangechim(2,DOSE);
%mychangechim(3,UNIT);
%mychangechim(4,NBCYCLE);

proc sort data=C1;by anumpat  nbvisit tptr;run;
proc sql noprint; 
create table base as select distinct anumpat ,nbvisit,CRFTITLE,TPTR from CHIMIOTHERAPIE;
quit;

* Regroupe les tables transposées en une seul CIOMIOTHERAPIE2;
proc sql noprint; create table CHIMIOTHERAPIE2 as select * from base a
	left join C1 b on  a.anumpat=b.anumpat    and a.tptr=b.tptr   and a.nbvisit=b.nbvisit
		left join C2 c on  a.anumpat=c.anumpat and a.tptr=c.tptr and a.nbvisit=c.nbvisit
		left join C3 d on  a.anumpat=d.anumpat and a.tptr=d.tptr and a.nbvisit=d.nbvisit
		left join C4 e on  a.anumpat=e.anumpat and a.tptr=e.tptr and a.nbvisit=e.nbvisit;
quit;

%macro pos;
%let retain=;
proc sql noprint; select max(count) into : nbmax from CHIMIOTHERAPIE;quit;
%do i=1 %to &nbmax;
%let retain= &retain DCI&i DOSE&i UNIT&i NBCYCLE&i;
%END;
%put &retain;
data CHIMIOTHERAPIE2;
retain &ordervar  &retain;
set CHIMIOTHERAPIE2;
run;
%MEND;
%pos;

* Remplace CHIMIOTHERAPIE par sa table transposée;
data CHIMIOTHERAPIE;
set CHIMIOTHERAPIE2;
run;

proc sort data=chimiotherapie; by anumpat  nbvisit;quit;

* Supprime les tables intermédiaires;
%suppr(CHIMIOTHERAPIE2);
%suppr(base);
%suppr(C1);%suppr(C2);%suppr(C3);%suppr(C4);



/* WARNING: Cette partie nécessite d'avoir lancer 05_mapping de la partie clinique.sas; */

* Table des chimio TVIM ligne 1 de l'inclusion;
data incl_ligne1;
set incl.Ecoimtr;
format TPTR $50.;
length TPTR $50.;

TPTR="CHIMIO LIGNE 1";
ligne=.;
if IMCHM=1;
keep &ordervar  ligne IMCHM	IMCHMIN	IMCHMDB	IMCHMFN	IMCHMNB	
IMCHMGC	IMCHMVI	IMCHMMV	IMCHMDF	IMCHMTL	IMCHMTLP IMCHMTT TPTR;
run;

* Table des chimio TVIM ligne 2 de l'inclusion;
data incl_ligne2;
set incl.Ecoimtr;
LIGNE=.;
format TPTR $50.;
length TPTR $50.;

TPTR="CHIMIO LIGNE 2";
keep &ordervar ligne IMCHM2 IMCHM2DB IMCHM2FN IMCHM2GC	IMCHM2MV IMCHM2VQ IMCHM2VI 
IMCHM2DF IMCHM2TL IMCHM2TT TPTR;
run;
data incl_ligne2;
set incl_ligne2;
if IMCHM2MQ NE . then IMCHM2VQ=IMCHM2MQ;
rename IMCHM2VQ=IMCHMNB IMCHM2=IMCHM IMCHM2DB=IMCHMDB IMCHM2FN=IMCHMFN IMCHM2MV=IMCHMMV 
IMCHM2TT=IMCHMTT IMCHM2TL=IMCHMTL IMCHM2DF=IMCHMDF IMCHM2GC=IMCHMGC IMCHM2VI=IMCHMVI;
ligne=.;
keep  &ordervar  TPTR ligne IMCHM2 IMCHM2DB IMCHM2FN	IMCHM2GC IMCHM2MV IMCHM2VQ 
IMCHM2VI IMCHM2DF IMCHM2TL IMCHM2TT TPTR;
run;

* Table des chimio TVIM du suivi;
data test3;
set suiv.tvimrec;
ligne=.;
format TPTR $50.;
length TPTR $50.;

TPTR="CHIMIO SUIVI TVIM (ligne1)";
rename  IMLIGN=ligne IMCHIMIO=IMCHM IMDCHIMDB=IMCHMDB IMDCHIMFN=IMCHMFN IMNBCYCL = IMCHMNB IMGC=IMCHMGC 
IMMVAC1=IMCHMMV IMMVAC2=IMCHMVI IMAUTPROT=AUPRT IMCHIMTOL=IMCHMTL IMCHIMEF=IMCHMTLP IMCHIMST=IMCHMTT;
keep  &ordervar TPTR IMCHIMIO IMNBCYCL IMLIGN IMDCHIMDB IMDCHIMFN IMNBCYCL IMGC 
IMAUTPROT IMMVAC1 IMMVAC2 IMCHIMTOL IMCHIMEF IMCHIMST;
run;

* Table des chimio traitement cible TVIM du suivi;
data test4;
set suiv.tvimrec;
format TPTR $50.;
length TPTR $50.;

TPTR="Traitement cible TVIM (ligne2)";
keep TPTR &ordervar IMTHCIBL IMDTHCICLBD IMDTHCICLFN IMTHCTL IMTHCES IMTHCST;
run;
data test4;
set test4;
rename IMTHCIBL=IMCHM IMDTHCICLBD=IMCHMDB IMDTHCICLFN=IMCHMFN IMTHCTL=IMCHMTL IMTHCES=IMTHCES IMTHCST=IMTHCST;
keep TPTR &ordervar IMTHCIBL IMDTHCICLBD IMDTHCICLFN IMTHCTL IMTHCES IMTHCST;
run;

* Table des chimio TVNIM ligne 1 du suivi;
data test5;
set suiv.Tvnimprogchim;
format TPTR $50.;
length TPTR $50.;

TPTR="CHIMIO SUIVI LIGNE 1 TVNIM";
ligne=.;
/*nbvisit=enbvisit;*/
/*
RENAME EIMCHM=IMCHM	EIMCHMIN=IMCHMIN EIMCHMDB=IMCHMDB EIMCHMFN=IMCHMFN EIMCHMNB=IMCHMNB	EIMCHMGC=IMCHMGC
EIMCHMVI=IMCHMVI EIMCHMMV=IMCHMMV EIMCHMDF=IMCHMDF EIMCHMTL=IMCHMTL	EIMCHMTLP=IMCHMTLP EIMCHMTT=IMCHMTT;
*/
keep &ordervar ligne IMCHM IMCHMIN IMCHMDB IMCHMFN	IMCHMNB IMCHMGC IMCHMVI 
IMCHMMV IMCHMDF IMCHMTL IMCHMTLP IMCHMTT TPTR;
run;

* Table des chimio TVNIM ligne 1 du suivi;
data test6;
set suiv.Tvnimprogchim;
length TPTR $50.;
format tptr $50.;
TPTR="CHIMIO SUIVI LIGNE 2 TVNIM";

rename 
IMCHM2=IMCHM 
IMCHM2QG=IMCHMNB 

IMCHM2DB=IMCHMDB 
IMCHM2FN=IMCHMFN 
IMCHM2MV=IMCHMMV

IMCHM2TT=IMCHMTT 
IMCHM2TL=IMCHMTL 
IMCHM2VI=IMCHMVI
IMCHM2DF=IMCHMDF;
ligne=.;
keep &ordervar

IMCHM2	
IMCHM2QG 
IMCHM2DB
IMCHM2FN
IMCHM2MV
IMCHM2TT
IMCHM2TL
IMCHM2MV
IMCHM2VI
IMCHM2DF
TPTR;
run;


* Fusion des 6 tables intermédiaires de chimio;
data testa;
format TPTR $50.;
length TPTR $50.;

set incl_ligne1 incl_ligne2 test3 test4 test5 test6;
if IMCHM ne .;
run;

proc sort; by anumpat  nbvisit;run;




* Retire les data sans chimio;
data testa;
retain anumpat  LIGNE;
set testa;
/*where IMCHM=1;*/
run;
proc sort; by  anumpat  nbvisit;run;

* Supprime les intermédiaires;
%suppr(incl_ligne1);
%suppr(incl_ligne2);
%suppr(test3);
%suppr(test4);
%suppr(test5);
%suppr(test6);


proc sort data=CHIMIOTHERAPIE nodupkey; by  anumpat  nbvisit  TPTR;run;
proc sort data=Testa nodupkey; by  anumpat  nbvisit TPTR;run;

* Merge les 2 tables de chimio crées jusqu'à présent dans une table CL_CHIMIOTHERAPIE;
data stu.CL_CHIMIOTHERAPIE;
merge Testa CHIMIOTHERAPIE;
by anumpat  nbvisit TPTR;
run;

* Retire les data sans chimio;
data stu.CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
if IMCHM=1;
run;

* Supprime les tables de WORK;
%suppr(CHIMIOTHERAPIE);
%suppr(testa);


* Macro ajoutant une colonne pour savoir si cette CDI a été employée à cette visite;
%macro newvar(var);
data stu.CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
format &var IMCHMINCL.;
if DCI1="&var" or DCI2="&var" or DCI3="&var" or DCI4="&var" then do;
if DCI1="&var" then DCI1="";
if DCI2="&var" then DCI2="";
if DCI3="&var" then DCI3="";
if DCI4="&var" then DCI4="";
&var=1 ;
end; else &var = 2 ;
if IMCHM NE 1 then &var=.;
run;
%mend;

* Lance la macro pour une liste de produits de chimio;
%newvar(PACLITAXEL);
%newvar(TAXOL);
%newvar(GEMCITABINE);
%newvar(CARBOPLATINE);
%newvar(VINFLUNINE);
%newvar(CISPLATINE);
%newvar(METHOTREXATE);
%newvar(VINBLASTINE);
%newvar(ADRIAMYCINE);
%newvar(DOXORUBICINE);
%newvar(ETOPOSIDE);
%newvar(ATEZOLIZUMAB);
%newvar(PEMBROLIZUMAB);
%newvar(VINORELBINE);





* Ajoute les cas où d'autres produits sont employées;
data stu.CL_CHIMIOTHERAPIE;
retain &ordervar;
set stu.CL_CHIMIOTHERAPIE;
format AUTRE IMCHMINCL.;
if IMCHM = 1 then do; 

if /*DCI1 in("","PACLITAXEL","TAXOL","GEMCITABINE","CARBOPLATINE","VINFLUNINE","CISPLATINE","METHOTREXATE","VINBLASTINE","ADRIAMYCINE","DOXORUBICINE","ETOPOSIDE","ATEZOLIZUMAB","PEMBROLIZUMAB","VINORELBINE") and 
DCI3 in("","PACLITAXEL","TAXOL","GEMCITABINE","CARBOPLATINE","VINFLUNINE","CISPLATINE","METHOTREXATE","VINBLASTINE","ADRIAMYCINE","DOXORUBICINE","ETOPOSIDE","ATEZOLIZUMAB","PEMBROLIZUMAB","VINORELBINE") 
and DCI2 in("","PACLITAXEL","TAXOL","GEMCITABINE","CARBOPLATINE","VINFLUNINE","CISPLATINE","METHOTREXATE","VINBLASTINE","ADRIAMYCINE","DOXORUBICINE","ETOPOSIDE","ATEZOLIZUMAB","PEMBROLIZUMAB","VINORELBINE") 
and DCI4 in("","PACLITAXEL","TAXOL","GEMCITABINE","CARBOPLATINE","VINFLUNINE","CISPLATINE","METHOTREXATE","VINBLASTINE","ADRIAMYCINE","DOXORUBICINE","ETOPOSIDE","ATEZOLIZUMAB","PEMBROLIZUMAB","VINORELBINE")*/
DCI1 = "" and DCI2 = "" and DCI3 = "" and DCI4 = "" then do;
 AUTRE=2 ;
end;else do;
AUTRE=1;
AUTRE_S=cats(DCI1,"-",DCI2,"-",DCI3,"-",DCI4);
end;
end;
test=cats(DCI1,"-",DCI2,"-",DCI3,"-",DCI4);
run;

* Répond oui à l'utilisation de certains GIC si des traitements spécifiques ont été administrées (GC et M-VAC);
data stu.CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
if IMCHMVI=1 or IMCHMMV=1 then do;
METHOTREXATE=1;
VINBLASTINE=1;
DOXORUBICINE=1;
CISPLATINE=1;
end;
if IMCHMGC=1 then do;
GEMCITABINE=1;
CISPLATINE=1;
end;

run;

* Créer une table de travail simplifiée;
data stu.CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
keep &ordervar LIGNE IMCHM IMCHMIN IMCHMNB  IMCHMDB IMCHMFN TPTR PACLITAXEL TAXOL 
GEMCITABINE CARBOPLATINE VINFLUNINE CISPLATINE METHOTREXATE VINBLASTINE ADRIAMYCINE  DOXORUBICINE ETOPOSIDE ATEZOLIZUMAB PEMBROLIZUMAB VINORELBINE AUTRE AUTRE_S;
run;
proc sort; by anumpat  IMCHMDB;run;

* Traite certains des cas Autres produits;
data stu.CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
if autre_s = "MVAC I SANS CARBOPLATINE---" then do;
autre=2;
autre_s="";
METHOTREXATE=1;
VINBLASTINE=1;
ADRIAMYCINE=1;
CISPLATINE=1;
end;
if autre_s = "GEMCITABINE CARBO PLATINE---" then do;
autre=2;
autre_s="";
CARBOPLATINE=1;
GEMCITABINE=1;
end;

if find(autre_s,"CARBOPLATINE GEMCITABINE") then do;
autre=2;
autre_s="";
CARBOPLATINE=1;
GEMCITABINE=1;
end;

run;

* Ajoute un comptage du nombre de traitement par patient;
data stu.CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
count+1;
by anumpat;
if first.anumpat then count=1;
run;



* Retire les tirets et espaces vides sur Autres produits;
data stu.CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
AUTRE_S= TRANWRD(AUTRE_S,'-','');
AUTRE_S= TRANWRD(AUTRE_S,' ','');
run;

* AM: A revoir;
data stu.CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
if PACLITAXEL=1 then TAXOL = 1;
run;

* Créer une variable d'identification contenant la liste des produits;
data stu.CL_CHIMIOTHERAPIE; set stu.CL_CHIMIOTHERAPIE;
if IMCHM=1 then id=cats(anumpat,PACLITAXEL,TAXOL,GEMCITABINE,CARBOPLATINE,VINFLUNINE,CISPLATINE,METHOTREXATE,VINBLASTINE,ADRIAMYCINE,DOXORUBICINE,ETOPOSIDE,ATEZOLIZUMAB,PEMBROLIZUMAB,VINORELBINE,AUTRE,AUTRE_S);

run;

proc sql noprint; create table atest as select a.*, 

case when PACLITAXEL=1 then "A" else "" end ||
case when TAXOL=1 then "B" else "" end||
case when GEMCITABINE=1 then "C" else "" end||
case when CARBOPLATINE=1 then "D" else "" end||
case when VINFLUNINE=1 then "E" else "" end||
case when CISPLATINE=1 then "F" else "" end||
case when METHOTREXATE=1 then "G" else "" end||
case when VINBLASTINE=1 then "H" else "" end||
case when ADRIAMYCINE=1 then "I" else "" end||
case when DOXORUBICINE=1 then "J" else "" end||
case when ETOPOSIDE=1 then "K" else "" end||
case when ATEZOLIZUMAB=1 then "L" else "" end||
case when PEMBROLIZUMAB=1 then "M" else "" end ||
case when AUTRE=1 then "N" else "" end



as id2

from stu.CL_CHIMIOTHERAPIE a;
quit;
data stu.CL_CHIMIOTHERAPIE; set atest;run;



* La macro sert à vérifier si chaque ligne de traitement est identique à une autre et de lui attribuer 
une valeur sur newligne en fonction;
%let ligne=;


data  CL_CHIMIOTHERAPIE;
set stu.CL_CHIMIOTHERAPIE;
if nbvisit=. then nbvisit=1;
/* ajout 2024, on cré une date index pour remplacer les visites */
format DINDEX DDMMYY10.;
IF IMCHMDB ne . then DINDEX=IMCHMDB ;else DINDEX=vpla ;
run;

proc sql noprint; create table n_ligne_0 as select distinct anumpat, min(DINDEX) as DINDEX, id2 from CL_CHIMIOTHERAPIE group by anumpat,ID,id2  HAVING id2 NE "" ORDER BY anumpat ;quit;
proc sql noprint; create table n_ligne_1 as select distinct anumpat, min(DINDEX) as DINDEX, id2 from n_ligne_0 group by anumpat,id2 ORDER BY anumpat, DINDEX ;quit;


data excludeL1;
set n_ligne_1;
by anumpat;
if not first.anumpat;
rename anumpat=anumpat2 DINDEX=DINDEX2  id2=id22;

run;


proc sql noprint; create table cartesian as select * from n_ligne_1 inner join excludeL1 on anumpat=anumpat2  and DINDEX2>DINDEX;quit;


data cartesian2;
    set cartesian;
    longueur_var2 = length(id22);
    match = 1; /* Initialise à 1, on suppose que toutes les lettres de var2 sont dans var1 */

    /* Boucle sur chaque caractère de var2 */
    do i = 1 to longueur_var2;
        lettre_var2 = substr(id22, i, 1); /* Extrait chaque lettre de var2 */

        if find(id2, strip(lettre_var2)) = 0 then do;
		ttt=id2;
            match = 0; /* Si une lettre n'est pas trouvée dans var1, met match à 0 */
			leave;
        end;
		
    end;
if match=1;
keep anumpat DINDEX2 id22 id2;
drop DINDEX;
rename  DINDEX2=DINDEX

id2=original_TRT
id22=id2;
run;

proc sql noprint; create table n_ligne as select a.*,original_TRT from n_ligne_1 a left join cartesian2 b on a.anumpat=b.anumpat and a.id2=b.id2;quit;



data n_ligne_Sans_retrain;
set n_ligne;
where original_TRT="";
run;
proc sort;by anumpat DINDEX;run;


data n_ligne_Sans_retrain;
set n_ligne_Sans_retrain;
retain newligne;

by anumpat;
if first.anumpat then newligne=0;
newligne=newligne+1;
run;


proc sql noprint; create table n_ligne_final as select a.*,newligne from n_ligne a left join n_ligne_Sans_retrain b on a.anumpat=b.anumpat and (a.id2=b.id2 or a.original_TRT=b.id2) order by a.anumpat ,a.DINDEX;quit;


data n_ligne_final;
set n_ligne_final;
if id2="" then newligne=.;
run;

proc sql noprint;create table CL_CHIMIOTHERAPIE2 as select a.* ,b.newligne from CL_CHIMIOTHERAPIE a left join n_ligne_final b on a.anumpat=b.anumpat and a.id2=b.id2;quit;

/*
proc sql noprint;create table CL_CHIMIOTHERAPIE3 as select a.* ,b.newligne from stu.Cl_chimiotherapie_oldresult  a left join  CL_CHIMIOTHERAPIE2 b on a.anumpat=b.anumpat and a.nbvisit=b.nbvisit;quit;
*/
data CL_CHIMIOTHERAPIE;
set CL_CHIMIOTHERAPIE2;
run;

proc sort;by anumpat NBVISIT;run;








data stu.CL_CHIMIOTHERAPIE;
set CL_CHIMIOTHERAPIE;
NBJ=IMCHMFN - IMCHMDB ;
NBC=round(NBJ/28);
run;

* Créer une table contenant les traitements de chimiothérapie;
data stu.CL_CHIMIO_TRT;
retain  &ordervar  LIGNE newligne IMCHMNB NBC; 
set stu.CL_CHIMIOTHERAPIE;
run;

proc sort data=stu.CL_CHIMIO_TRT;by anumpat nbvisit;run;

data stu.CL_CHIMIO_TRT;
set stu.CL_CHIMIO_TRT;
if IMCHM =1;
run;

* Supprime la table intermédiaire;

  %suppr(stu.Cl_chimiotherapie);  %suppr(n_ligne);  %suppr(Cl_chimiotherapie); %suppr(Cl_chimiotherapie2);

  %suppr(N_ligne_0);  %suppr(N_ligne_1); %suppr(N_ligne_final); %suppr(N_ligne_sans_retrain);  %suppr(Cartesian); %suppr(Cartesian2);    

