
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


%let pathprog = C:\Users\a_mangin\Documents\GitHub\COB\Commun_France_cohorte;
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





* Différente macro variable pour chopper la date du jour;
%let daterep=%sysfunc(today(),date8.);
%let datetemp=%sysfunc(today(),yymmdd9.);
data _null_;test=strip("&datetemp");datefileL=tranwrd(test,"-",".");call symputx('datefile',datefileL);run;


%put &daterep;
%put &datefile;





proc sql noprint; create table resume as select * from stu.resume a left join stu.an_tnm_incl b on a.anumpat=b.anumpat ;quit;
 
   proc sort nodupkey; by anumpat;run;


data MyExport ;
set resume;
if DNAIS NE "" then do;
m=substr(strip(DNAIS),4,2);
d=substr(strip(DNAIS),1,2);
y=substr(strip(DNAIS),7,4);
DNAIS2=mdy(m,d,y);
end;
drop m d y DNAIS;
run;
data MyExport ;
set MyExport;
label DNAIS2 = "Date de naissance";
format DNAIS2 DDMMYY10.;
rename DNAIS2=DNAIS;
run;

/*proc sql noprint; create table MyExport2 as select a.*,meta from MyExport left join stu.Pat_meta_incl b on a.anumpat=b.anumpat;quit;
*/
data MyExport ;
set MyExport;
format METAatINCL METAatSUIV YN.;
if DNAIS NE . and DINCL NE . then  age = int(yrdif(DNAIS,DINCL,'ACTUAL'));
if (DateIndexMeta>0 and DateIndexMeta<DINCL + 3*30) or ( DateIndexMeta=. and find(tpmeta,'0')>0 ) THEN METAatINCL = 1 ; else METAatINCL = 2;
if (DateIndexMeta>0 and DateIndexMeta>DINCL + 3*30)or (META=1 and DateIndexMeta=. and find(tpmeta,'0')=0 )  THEN METAatSUIV = 1 ; else METAatSUIV = 2;
keep anumpat DNAIS DINCL SEXE AGE CRITINC BRA_INCL DateIndexMeta METAatINCL METAatSUIV NSDDC DSORTETU; 
label METAatINCL = "Metastase à l'inclusion";
label METAatSUIV = "Metastase au cours du suivi";
run;




proc sql nowarn noprint; 
create table cl_rtuv as select b.*  from stu.resume a 
left join stu.cl_rtuv b on a.anumpat=b.anumpat WHERE B.anumpat NE '' and (DINCL - 30)<=DTTIRT;
create table temp as select a.anumpat,A.DINCL, min(b.DTTIRT) as FRTUV "Première RTUV après l'inclusion" format=DDMMYY10.  from stu.resume a 
left join cl_rtuv b on a.anumpat=b.anumpat
group by a.anumpat;
create table temp2 as select a.anumpat , A.DINCL, min(b.CYSDBH) as FCYS "Première CYS après l'inclusion" format=DDMMYY10.  from stu.resume a 
left join stu.cl_cystectomie b on a.anumpat=b.anumpat
group by a.anumpat 
HAVING ( b.CYSDBH=. or (A.DINCL - 30 )<=b.CYSDBH);

create table temp3 as select * from temp full join temp2 on temp.anumpat = temp2.anumpat;

quit;
proc sort data=temp3 nodupkey;by anumpat;quit;
proc format;
value firstop
 1 = 'RTUV'
 2 = 'CYST';
 run;

data temp3;
set temp3;
format TPOP firstop.;
format BOTH NIMCYSINCL.;
if FCYS = . and FRTUV NE . then TPOP = 1;
else if  FCYS > FRTUV and FRTUV NE . then TPOP = 1;
else if  FCYS = . and FRTUV = . then TPOP = .;
else TPOP = 2;
test =  FCYS- FRTUV;
if test < 6*(30) and test > 0 and  FCYS NE . and FRTUV NE . then BOTH=1;else BOTH=2;
where anumpat NE '';
label BOTH = "pour les RTUV à l'inclusion: cystectomie après RTUV"
TPOP = "première intervention chirurgicale à l'inclusion";
drop test;
run;

proc sql nowarn noprint; create table  finalreport as select * from MyExport left join temp3 on MyExport.anumpat=temp3.anumpat;quit;
%placement(finalreport,METAatINCL,15);
%placement(finalreport,DateIndexMeta,15);
%suppr(temp3);
%suppr(temp);
%suppr(temp2);


data test;
set stu.Et_exclusion;
format EXLMOT $50.;
format Exl NIMCYSINCL.;
format DateExl DDMMYY10.;
EXLMOT='';
DateExl=DEXCL;
if DEXCL NE . or REFUS=1 or NOCANCER=1 or AUTMOTIFEX=1 then Exl = 1;
if REFUS=1 then EXLMOT = cats(EXLMOT,'REFUS');
if NOCANCER=1 then EXLMOT = cats(EXLMOT,'NOCANCER');
if AUTMOTIFEX=1 then EXLMOT = cats(EXLMOT,'Autre motif');
keep anumpat  EXLMOT  DateExl;
run;
proc sort;by anumpat;run;
proc sort data=finalreport;by anumpat;run;

data finalreport;
merge finalreport test;
by anumpat;
label EXLMOT="Raison Exlusion"
DateExl="Date exclusion"
DateIndexMeta="date metastase";
;
where ANUMPAT NE "" and find(ANUMPAT,"Suppr")=0;
run;
%suppr(test);






proc sql noprint; create table stat_visit as select distinct fn_fol,DVISIT,NBVISIT,localidentifier1,OID, BRA,BRA_incl,
case when VISITNAME = "CTRL" then "Planing de suivi" when find(VISITNAME,"Visit")=0 then "Inclusion" else VISITNAME end   as vtype,
sum(case when crfpagestatus=-30 and not ( base=2 and CRFPAGEORDER>12) then 1 else 0 end) as nbmis ,
sum(case when crfpagestatus=-30  and base=2 and CRFPAGEORDER>12 then 1 else 0 end) as nbmisQLQ ,
sum(case when crfpagestatus=10 or crfpagestatus=30 or (DISCREPANCYSTATUS NE 0 and DISCREPANCYSTATUS NE 10) then 1 else 0 end) as nbq,
sum(case when SDVSTATUS=40 then 1 else 0 end) as nbsdv  ,
sum(case when crfpagestatus>=0  and DESAC NE 1 and CRFPAGECODE NE "ACSUIVIACT"  then 1 else 0 end) as nbOK  ,
PDVDATE	 ,
max(Date_LASTM) as Date_LASTM format=DDMMYY10.,
VNF	format=1.
from Status_fiche group by OID,DVISIT, NBVISIT,localidentifier1, vtype ,fn_fol,VNF having dexcl=. ORDER BY localidentifier1 ,NBVISIT ;

quit;




proc sql noprint; create table test2b as select DISTINCT ANUMPAT, VISITCODE, LISTVISIT,recipro2,BRA from test;quit;




data test2b;set test2b;where LISTVISIT=9 and BRA=2 and ( recipro2 = 1 or recipro2 = .);run;


proc sql noprint; create table test2c as select  ANUMPAT,count( LISTVISIT) as nbrec "Nombre de recidives TVNIM->TVNIM" from test2b group by anumpat;quit;

proc sql noprint; create table test2b as select DISTINCT ANUMPAT, VISITCODE, LISTVISIT,recipro2 from test;quit;
data test2b;set test2b;where LISTVISIT=9 and recipro2 = 2;run;

proc sql noprint; create table test2D as select  ANUMPAT,count( LISTVISIT) as nbprog "Nombre de progression TVNIM->TVIM" from test2b group by anumpat;quit;


proc sql noprint; create table test2b as select DISTINCT ANUMPAT, VISITCODE, LISTVISIT,recipro2,bra from test;quit;
data test2b;set test2b;where LISTVISIT=9 and bra = 1;run;

proc sql noprint; create table test2e as select  ANUMPAT,count( LISTVISIT) as nbprogIM "Nombre de progression TVIM" from test2b group by anumpat;quit;



proc sql noprint; create table test2 AS SELECT LOCALIDENTIFIER1 as anumpat, sum(case when (nbq>0 or nbOK>0 )and vtype NE "Inclusion" then 1 else 0 end ) as NBok,


sum(case when nbmis>0  and vtype NE "Inclusion" then 1 else 0 end ) as NBMISS FROM STAT_visit group by 	LOCALIDENTIFIER1;quit;







data finalreport;
merge finalreport test2;
by anumpat;
run;

proc sort data=test2c;by anumpat;run;
data finalreport;
merge finalreport test2c;
by anumpat;
run;

proc sort data=test2d;by anumpat;run;
data finalreport;
merge finalreport test2d;
by anumpat;
run;

proc sort data=test2e;by anumpat;run;
data finalreport;
merge finalreport test2e;
by anumpat;
run;





data finalreport;
set finalreport;
label NBMISS = "Nombre de visites manquantes"
NBok = "Nombre de visite remplis";
run;



 proc sql noprint; create table temp55 as select anumpat, sum(case when IMPRLHIST=1 then 1 else 0 end) as nbhisto " Nombre prélèvement histo de progression des TVIM "  from suiv.Tvimrec  group by anumpat;quit;
proc sort data=temp55 nodupkey;by anumpat;run;
data finalreport;
merge finalreport temp55;
by anumpat;
run;


data test56;
set stu.CL_TVNIM_SUIV;
progmeta_cur=1;
label progmeta_cur="Nombre de curages positifs";
where (BNVCUR=1 and BNVCURES=1) or (DIMEXCU=1  and DIMEXCUR=1);
keep ANUMPAT  progmeta_cur;
run;

data testCurageInclusion1;
set stu.CL_TVIM;
format curincl NIMCYSINCL.;
curincl=1;
where IMEXCUR=1;
keep ANUMPAT curincl;
run;
proc sort nodupkey; by ANUMPAT;run;


data testCurageInclusion2;
set stu.CL_TVNIM;
format curincl NIMCYSINCL.;
curincl=1;
where NIMTEXTP=1 and NIMEXTPR=1;
keep ANUMPAT curincl;
run;
proc sort nodupkey; by anumpat;run;

data ajoutcurage;
set testCurageInclusion1 testCurageInclusion2;
run;
proc sort nodupkey; by anumpat;run;




data finalreport;
merge finalreport test56 ajoutcurage;
by anumpat;
run;

data finalreport ;
set finalreport;
if nbrec=. then nbrec=0;
if nbprog=. then nbprog=0;
if nbprogIM=. then nbprogIM=0;
if nbhisto=. then nbhisto=0;
if progmeta_cur=. then progmeta_cur=0;
label curincl="Nombre de curages positifs à l'inclusion";
if curincl=. then curincl=2;
run;


%placement(finalreport,NSDDC,50);
%placement(finalreport,DSORTETU,50);
%placement(finalreport,METAatSUIV,20);
%placement(finalreport,curincl,14);
%placement(finalreport,test,50);
data finalreport;
retain ANUMPAT SEXE DNAIS DINCL ;
set finalreport;
format DNAIS DDMMYY10.;
run;


ods excel file="\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Nouvelle methode de travail\out\Rapport pour monitoring_&datefile..xlsx"
 options (sheet_name="Table 1 - Rapport détaillé e") 
options (frozen_headers = "Yes")
options (autofilter = "All");

proc print data=finalreport noobs label;
var 
ANUMPAT
SEXE
DNAIS
DINCL
CRITINC
BRA_INCL
age
FRTUV
FCYS
DateIndexMeta
METAatINCL
BOTH
TPOP
curincl
DateExl
EXLMOT
NBMISS
NBok
METAatSUIV
nbrec
nbprog
nbprogIM
nbhisto
progmeta_cur
NSDDC
DSORTETU;
run;
ods excel close;
			   


ods excel file="\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Nouvelle methode de travail\out\Rapport listing chirurgie_&datefile..xlsx"
 options (sheet_name="Table 1 - Rapport détaillé e") 
options (frozen_headers = "Yes")
options (autofilter = "All");

proc print data=stu.List_chir noobs label;
run;

ods excel close;


/* texte du message */
%let strMsg = <font color=#0052cc> <center><h1> Mail automatique - Indicateurs de coblance </h1></center>
<br>
<br>
Bonjour à tous,<br>
 <br>
Vous trouverez ci-joint le rapport ainsi que le listing des patients de coblance. <br>
Bonne journée, <br>
<b>Anthony MANGIN</B><br> </font>

x mkdir;
FILENAME script "\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Nouvelle methode de travail\out\print.vbs";
DATA _NULL_;
FILE script;
PUT "dim objOutlk";
PUT "dim objMail";

PUT "const olMailItem = 0";

PUT "set objOutlk = createobject(""Outlook.Application"")";
PUT "set objMail = objOutlk.createitem(olMailItem)";

PUT "objMail.To = ""anthony.mangin@gustaveroussy.fr;Francoise.TERRIER@gustaveroussy.fr""";

PUT "objMail.subject = ""[COBLANCE] -  Indicateurs + Fichier pour monitoring (mail automatique)""";
    
PUT "objMail.HTMLbody = "" &strMsg """;
PUT "objMail.attachments.add(""\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Nouvelle methode de travail\out\Rapport pour monitoring_&datefile..xlsx"")";
PUT "objMail.attachments.add(""\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Nouvelle methode de travail\out\Rapport listing chirurgie_&datefile..xlsx"")";
PUT "objMail.SaveAs ""\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Nouvelle methode de travail\out\Coblance metrics.msg""";


PUT "set objMail = nothing";
PUT "set objOutlk = nothing";
RUN;
x   "\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Nouvelle methode de travail\out\print.vbs"; 


;
