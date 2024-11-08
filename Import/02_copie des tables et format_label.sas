/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De traitement et mapping des tables

 Ce fichier permet de traiter les tables stocke dans le raw
V1 20/10/2020 -> Anthony M
V2 06/09/2023 -> Anthony M et Pierre G revu pour France Cohorte
V3 29.10.2024 -> Pierre a trouve une erreur sur Planing_planing1, Temp_model2 n'etait pas gerer dans l'exception, planing etait reecris a la place de la base
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* Liste des macrovariables a parametrer : path;


* Definit l'endroit de stockage de la base locale de travail. A personnaliser;
*%let path=D:\coblance;
* Par default en commentaire car le chemin est definit dans FINAL_EXE.sas;

* Nom du fichier pour trouver le path;
/*
%let pathraw=&path_prog.;*/
 *---------------------------------------------- ;
%let ordervar= essai site  anumpat  NBVISIT    bra  vnf v vpla crftitle crfpagecyclenumber CRFPAGESTATUS;
%let ordervar_g= essai site  anumpat  NBVISIT    bra  vnf v vpla recidive crftitle crfpagecyclenumber repeatnumber CRFPAGESTATUS;


* Creer le dossier oe sera stocke la copie de la base raw Oracle sur laquelle on travaille;
%macro CreatFolder(dossier);
	filename dossier "&dossier";
    option NOXWAIT;  /* Permet de retourner automatiquement a SAS apres l execution de la commande */
	%if %sysfunc(fexist(dossier))= 0 %then %do;
    x mkdir "&dossier.";  /* Cr"eation du dossier en commande DOS */
	%end;
	%else %put NOTE: le dossier &dossier existe deja.;
%mend;
%CreatFolder(&path\DB);

* Getlib : cree un dossier et le place en libname;
%macro Getlib(nom,dossier);
filename dossier "&dossier";
%if %sysfunc(fexist(dossier)) = 0 %then %do;
option NOXWAIT;
x mkdir "&dossier.";
%end;
libname &nom "&dossier.";
%mend;

* Macro pour copier les table d'une libname e l'autre, avec un argument optionnel pour retirer une ou plusieurs table;
%macro copie(in,stu,exclude=NULL);
%vider(&STU);proc copy in=&in out=&STU memtype=data;%if &exclude NE NULL %then %do;exclude &exclude;%end;run;
%mend;

* %suppr Simple macro de suppression de table, pour rester propre;
%MACRO suppr(table);proc sql noprint; Drop Table &table;quit;%mend;
%macro vider(lib);
data nomtable ;set sashelp.vstable;where libname=upcase("&lib.");
if memname='TIMEDOWN' or memname='timedown' or memname="nomtable"  or memname="META_comment" then delete;
run;

proc sql noprint;select distinct count(*) into: nbtable from nomtable; quit;
%do i=1 %to &nbtable.;
data _null_ ;set nomtable; if _N_=&i then call symput("memname",memname) ; run;
%suppr(&lib..&memname.);
%end;
%mend;



OPTION FMTSEARCH =  ( stu   format LIBRARy) ; 

 * -------------------------Etape 1 : acces et creation des libnames------------------------------;

* Recupere les libname de RAW;
%Getlib(RAWincl,&pathraw\incl);
%Getlib(RAWsuiv,&pathraw\suiv);
%Getlib(RAWanap,&pathraw\anap);
%Getlib(RAWrel,&pathraw\relec);


* Recupere les libnames de travail (vide e ce moment le);
%Getlib(incl,&path\DB\incl);
%Getlib(suiv,&path\DB\suiv);
%Getlib(anap,&path\DB\anap);
%Getlib(stu,&path\DB\stu);
%Getlib(rel,&path\DB\relec);

* Copie les libnames de RAW dans les libnames de travail;

%copie(RAWincl,incl);
%copie(RAWsuiv,suiv);
%copie(RAWanap,anap);
%copie(RAWrel,rel);

PROC IMPORT OUT= stu.variant DATAFILE= "\\nas-01\sbe_etudes\COBLANCE\10-informations patients (anapath,etc)\Histologic variants COBLANCE 17022020.xlsx" DBMS = xlsx REPLACE;
SHEET="Feuil1";
GETNAMES=YES;
RUN;

PROC IMPORT OUT= stu.consent DATAFILE= "\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\retrait de consentement\BDD retrait consent.xlsx" DBMS = xlsx REPLACE;
SHEET="Feuil1";
GETNAMES=YES;
RUN;




* Ajoute une table Work.EXL contenant la liste des personnes exclus lors de l'inclusion;
proc sql noprint; create table exl as select localidentifier1, 1 as EXLU from incl.Exlusion a left join incl.trialsubject b on
a.site=b.trialsite and a.personid=b.personid where DEXCL NE .;;quit;

* Table utilise ensuite pour retirer les patients exclus des selections de tables;


*------------------------ etape 2 creation des formats et des labels ------------------------------	 ;



proc format lib=stu;
value LISTVISITsuiv
0="Inclusion"
1="visite a 3 mois"
2="Visite a 6 mois"
3="Visite a 1 an"
4="Visite a 2 ans"
5="Visite a 3 ans"
6="Visite a 4 ans"
7="Visite a 5 ans"
8="Visite a 6 ans"
9="Recidive";

;
value responsestatus
-30	=DUE
-12	=NA
-11	=Absent
-10	=Vierge
-8	=Inactive
-5	=Not available
0	=Complete
10	=MIssing
25	=OKW
30	=WArning
31 =DCR
.   =inactive;
run;



* Recupere les noms des tables autres que les tables systemes;
%macro getnomtable(stu);
%let stuMaj=%sysfunc(UPCASE(&stu.));

data nomtable ;set sashelp.vstable;where libname="&stuMaj";
if memname='CLINICALTRIAL' or memname='QGROUP' or  memname='QGROUPQUESTION' or memname='STUDYVISITCRFPAGE' or memname='DATAITEMRESPONSE' or memname='SITE' or memname='DATAITEM' or memname='CLINICALTRIAL' or memname='CRFELEMENT' then delete;
if memname='CRFPAGE' or memname='CRFPAGEINSTANCE' or memname='DATAITEMVALIDATION' or memname='MACROCOUNTRY' or memname='DATAITEMVALIDATION' then delete;
if memname='MIMESSAGE' or upcase(memname)='EXL' or memname='STUDYVISIT' or memname='TRIALSITE' or memname='TRIALSUBJECT' or memname='VALIDATIONTYPE' or memname='VALUEDATA' then delete;
run;
%mend;


%macro Creation_des_proc_format(lib,stu);
proc sql noprint; create table format_table as select VALUECODE as start,  ITEMVALUE as label, "N" as type, cats(dataitemcode ,"&stu") as fmtname from &stu..valuedata left join &stu..dataitem on valuedata.dataitemid=dataitem.dataitemiD and valuedata.CLINICALTRIALID=dataitem.CLINICALTRIALID;quit;
data format_table;set format_table;if ANYALPHA(start)>0 then type="C";run;proc format cntlin=format_table lib=&lib;run;
%suppr(format_table);
%MEND;

* Cree et Applique les formats aux tables;
%Creation_des_proc_format(stu,incl);
%Creation_des_proc_format(stu,suiv);
%Creation_des_proc_format(stu,anap);
%Creation_des_proc_format(stu,rel);





%macro get_template(stu,mabase);
/* creation de la table listtable avec la liste des tables et des variable de l'etude */

/* table temp qui sert a lister les items et les natures de variables */
proc sql noprint; create table temp as select DATAVIEWNAME,c.crfpagecode,b.dataitemcode,dataitemname,datatype,d.Qgroupcode,dataitemformat from &stu..crfelement a full join
&stu..dataitem b on a.dataitemid=b.dataitemid and a.CLINICALTRIALID=b.CLINICALTRIALID 
full join &stu..crfpage c on a.crfpageid=c.crfpageid and a.CLINICALTRIALID=c.CLINICALTRIALID
full join &stu..Qgroup d on a.OWNERQGROUPID=d.QGROUPID left join &stu..Dataviewtables e on a.crfpageid=e.crfpageid and a.CLINICALTRIALID=e.CLINICALTRIALID and a.OWNERQGROUPID=e.QGROUPID
where c.crfpagecode NE "" and  a.DATAITEMID NE 0;
quit;


/* partie construction de la liste des table, et aussi pour savoir si c'est une table de group ou non */
data temp;set temp;length table $30.;table=DATAVIEWNAME;if table="" then do;if Qgroupcode="" then table=crfpagecode;else table=cats(crfpagecode,"_",Qgroupcode);end;run;
proc sort data=temp; by table;run;
proc sql noprint; create table listtable as select distinct table,QGROUPCODE,b.CRFPAGEID from temp a left join &stu..Crfpage b on a.CRFPAGECODE=b.CRFPAGECODE;quit;
%mend;

%macro ApplyFormat_incl(stu,mabase);


proc sql noprint; create table bra_incl as select 
localidentifier1, 
TPBRA as bra "bras de visite" format=TPBRAINCL.,
datepart(dincl) as vpla "visite planning" format=DDMMYY10.,
. as v "type visite" format=LISTVISITsuiv.,
. as recidive "recidive" format=RECIPROsuiv.
from incl.idenbra a left join incl.Trialsubject b on a.site=b.trialsite and a.personid=b.personid;
quit;
/*
%let stu=incl;
%let mabase=COBINC;
*/
 %get_template(&stu,&mabase);
data _null_;set listtable end=final;call symputx("table"||left(_N_),table);call symputx("group"||left(_N_),QGROUPCODE);if final then call symputx("nbtable",_N_);run;



proc sql noprint; 

create table bra_suiv as select localidentifier1,NBVISIT, vnf, bra "bras de visite" format=TPBRAINCL.,datepart(DVISIT) as vpla "visite planning" format=DDMMYY10.,LISTVISIT as v "type visite" format=LISTVISITsuiv.,RECIPRO as recidive "recidive" format=RECIPROsuiv.
from suiv.Planing_planing1 a left join suiv.Trialsubject b on a.site=b.trialsite and a.personid=b.personid;
quit;


data _null_;set listtable end=final;
call symputx("table"||left(_N_),table);
call symputx("CRFPAGEID"||left(_N_),CRFPAGEID);
call symputx("group"||left(_N_),QGROUPCODE);
if final then call symputx("nbtable",_N_);run;


/*%do j=1 %to &nbtable;*/
%do j=1 %to &nbtable;
	%put travail sur la table &stu..&&table&j;



	/* Preparation des cle de table + import des fiches vides + suppression mauvais enregistrements;*/

	proc sql noprint nowarn; create table tempmodel as select "&mabase" as ESSAI format=$15. length=15, e.trialsite as site, LOCALIDENTIFIER1,visitname,0 as NBVISIT , "Inclusion" as v,crftitle,e.crfpagecyclenumber,
	e.CRFPAGESTATUS format=responsestatus., &&table&j...* 
	from
 	&stu..CRFPAGEINSTANCE e                           
	left join &stu..&&table&j a on  a.site=e.trialsite and a.personid=e.personid  and a.CLINICALTRIALID=e.CLINICALTRIALID and
 	a.visitid=e.visitid and a.visitcyclenumber=e.visitcyclenumber and a.crfpageid=e.crfpageid and a.crfpagecyclenumber=e.crfpagecyclenumber
	left join &stu..studyvisit b on e.visitid=b.visitid and e.CLINICALTRIALID=b.CLINICALTRIALID
	left join &stu..crfpage c on e.crfpageid=c.crfpageid  and e.CLINICALTRIALID=c.CLINICALTRIALID
	left join &stu..trialsubject d on e.trialsite=d.trialsite and e.personid=d.personid  and e.CLINICALTRIALID=d.CLINICALTRIALID
	where LOCALIDENTIFIER1 NE "" and e.TRIALSITE ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee" and e.CRFPAGEID=&&CRFPAGEID&j
	;
	;quit;

	proc sql noprint; create table  tempmodel_2 as select bra,b.vpla,b.v, b.recidive,. as vnf format=vnfsuiv.,a.* from tempmodel a left join bra_incl b on a.LOCALIDENTIFIER1=b.LOCALIDENTIFIER1;quit;

	%if "&&group&j" NE "" %then %do;
		data &stu..&&table&j;
		set tempmodel_2;
		label localidentifier1="Pat Ne" visitname="Visite" visitcyclenumber="Visite Ne" crftitle="form" crfpagecyclenumber="Fiche Ne" repeatnumber="Ligne Ne" ;
		drop personid clinicaltrialid visitid crfpageid ;
		where LOCALIDENTIFIER1 NE "" and site ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee";
		run;
		
		data &stu..&&table&j;
		set &stu..&&table&j;
		drop OWNERQGROUPID;
		run;

	%end;
	%else %do;

		data &stu..&&table&j;
		set tempmodel_2;
		label localidentifier1="Pat Ne" visitname="Visite" visitcyclenumber="Visite Ne" crftitle="form" crfpagecyclenumber="Fiche Ne";
		drop personid clinicaltrialid visitid crfpageid ;
		where LOCALIDENTIFIER1 NE "" and site ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee";
		run;
	%end;

	data _null_;
	set temp end=final;
	call symputx("label"||left(_N_),dataitemname);
	call symputx("code"||left(_N_),dataitemcode);
	call symputx("type"||left(_N_),DATATYPE);
	call symputx("format"||left(_N_),DATAITEMFORMAT);
	if final then call symputx("nblabel",_N_);
	where table="&&table&j";
	run;
	proc contents  data=&stu..&&table&j noprint out=tempcontent;run;
	data tempcontent_&&table&j;
	set tempcontent;
	call symputx(NAME,FORMAT);
	run;

	%let format=;
	%do i=1 %to &nblabel;

		/* Format des dates et heures;	*/
		%if "&&code&i" NE "" and "&&label&i" NE "" %then  %let format=&format %str(;) label &&code&i="&&label&i" %str(;);
		%if &&type&i=1 %then %let format=&format %str(;) format &&code&i &&code&i..&stu.. %str(;);
		%if  "&&format&i"="dd/mm/yyyy" and "&&&&&&code&i"="DATETIME" %then %do;
			%let format=&format %str(;) &&code&i=datepart(&&code&i) %str(;);
			%let format=&format %str(;)format &&code&i DDMMYY10. %str(;);
		%end;

	%end;

	%put creation des labels : &format;
	data &stu..&&table&j;set &stu..&&table&j;&format;run;

	%if "&&table&j" NE "EXLUSION"  and "&&table&j" NE "CONSENT"  and "&&table&j" NE "VARIANT" and "&&table&j" NE "TRASH" %then %do;
		proc sql noprint; create table test as select a.* from &stu..&&table&j a left join exl b on
 		a.localidentifier1=b.localidentifier1
		left join stu.consent c on
 		a.localidentifier1=c.Patient
		where EXLU =. and demande_effacement_des_donn_es NE "Oui" ;quit;
		data &stu..&&table&j; set test;run;
		%suppr(test);

	%end;	


		%if "&&group&j" = "" %then %do; data &stu..&&table&j; retain &ordervar ; set &stu..&&table&j; anumpat=localidentifier1 ; drop localidentifier1;run;%end;
		%if "&&group&j" NE "" %then %do; data &stu..&&table&j; retain &ordervar_g ; set &stu..&&table&j; anumpat=localidentifier1 ; drop localidentifier1;run;%end;


 %suppr(tempcontent_&&table&j);
%suppr(tempcontent);


%end;

%mend;



%ApplyFormat_incl(incl,COBINC);
 

%macro ApplyFormat_suiv(stu,mabase);


proc sql noprint; 

create table bra_suiv as select b.localidentifier1,NBVISIT, vnf, bra "bras de visite" format=TPBRAINCL.,datepart(DVISIT) as vpla "visite planning" format=DDMMYY10.,LISTVISIT as v "type visite" format=LISTVISITsuiv.,RECIPRO as recidive "recidive" format=RECIPROsuiv.
from suiv.Planing_planing1 a left join suiv.Trialsubject b on a.site=b.trialsite and a.personid=b.personid
WHERE b.localidentifier1 NE "" and find(b.localidentifier1,"personne non identifiee")=0 and find(b.localidentifier1,"Suppr")=0
ORDER BY b.localidentifier1 ,a.NBVISIT;
quit;


data suiv.studyvisit;
set suiv.studyvisit;
NUMVISIT_pre=VISITORDER-1;
if NUMVISIT_pre LE 16;
run;


 %get_template(&stu,&mabase);
/* suppression des tables qui ne servent plus */
  data temp;
 set temp;
 if CRFPAGECODE not in("CYSANAP","CYSANAP_LOC_SIEG","RELECT1","RELECT2","RTUVANAP1","RTUVRELEC1","ANAMETA");
 run;
 data listtable;
 set listtable;
 if table not in("CYSANAP","CYSANAP_LOC_SIEG","RELECT1","RELECT2","RTUVANAP1","RTUVRELEC1","ANAMETA");
 run;



data temp_table_suiv;set listtable end=final;
call symputx("table"||left(_N_),table);
call symputx("CRFPAGEID"||left(_N_),CRFPAGEID);
call symputx("group"||left(_N_),QGROUPCODE);if final then call symputx("nbtable",_N_);run;

/*
%let j=1;
*/
/*%do j=1 %to &nbtable;*/
%do j=1 %to &nbtable;
	%put travail sur la table &stu..&&table&j;

	/* Preparation des cle de table + import des fiches vides + suppression mauvais enregistrements;*/


	
%if "&&table&j.." NE "PLANING_PLANING1" %then %do;
proc sql noprint nowarn; create table tempmodel as select "&mabase" as ESSAI format=$15. length=15, e.trialsite as site, LOCALIDENTIFIER1,visitname,e.VISITCYCLENUMBER,b.NUMVISIT_pre ,crftitle,e.crfpagecyclenumber,
e.CRFPAGESTATUS format=responsestatus., &&table&j...* 
from
 &stu..CRFPAGEINSTANCE e                           
left join &stu..&&table&j a on  a.site=e.trialsite and a.personid=e.personid  and a.CLINICALTRIALID=e.CLINICALTRIALID and
 a.visitid=e.visitid and a.visitcyclenumber=e.visitcyclenumber and a.crfpageid=e.crfpageid and a.crfpagecyclenumber=e.crfpagecyclenumber
left join &stu..studyvisit b on e.visitid=b.visitid and e.CLINICALTRIALID=b.CLINICALTRIALID
left join &stu..crfpage c on e.crfpageid=c.crfpageid  and e.CLINICALTRIALID=c.CLINICALTRIALID
left join &stu..trialsubject d on e.trialsite=d.trialsite and e.personid=d.personid  and e.CLINICALTRIALID=d.CLINICALTRIALID
where LOCALIDENTIFIER1 NE "" and e.TRIALSITE ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee" and e.CRFPAGEID=&&CRFPAGEID&j
;
;quit;
data tempmodel; set tempmodel;
if visitcyclenumber=. then visitcyclenumber=1;
NBVISIT=NUMVISIT_pre+visitcyclenumber-1;
drop NUMVISIT_pre;
run;


data tempmodel; 
retain NBVISIT;
set tempmodel;
run;
proc sql noprint; create table  tempmodel_2 as select b.bra,b.vpla,b.v, b.recidive,b.VNF,a.* from tempmodel a left join bra_suiv b on a.LOCALIDENTIFIER1=b.LOCALIDENTIFIER1
and a.NBVISIT=b.NBVISIT;quit;
%end;
%else %do;
%put "bosse table visite";

proc sql noprint nowarn; create table tempmodel as select "&mabase" as ESSAI format=$15. length=15, e.trialsite as site, LOCALIDENTIFIER1,visitname,e.VISITCYCLENUMBER,crftitle,e.crfpagecyclenumber,
e.CRFPAGESTATUS format=responsestatus., &&table&j...* 
from
 &stu..CRFPAGEINSTANCE e                           
left join &stu..&&table&j a on  a.site=e.trialsite and a.personid=e.personid  and a.CLINICALTRIALID=e.CLINICALTRIALID and
 a.visitid=e.visitid and a.visitcyclenumber=e.visitcyclenumber and a.crfpageid=e.crfpageid and a.crfpagecyclenumber=e.crfpagecyclenumber
left join &stu..studyvisit b on e.visitid=b.visitid and e.CLINICALTRIALID=b.CLINICALTRIALID
left join &stu..crfpage c on e.crfpageid=c.crfpageid  and e.CLINICALTRIALID=c.CLINICALTRIALID
left join &stu..trialsubject d on e.trialsite=d.trialsite and e.personid=d.personid  and e.CLINICALTRIALID=d.CLINICALTRIALID
where LOCALIDENTIFIER1 NE "" and e.TRIALSITE ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee" and e.CRFPAGEID=&&CRFPAGEID&j
;
;quit;

data tempmodel;set tempmodel; drop bra vnf;run;
proc sql noprint; create table  tempmodel_2 as select b.bra,b.vpla,b.v, b.recidive,b.VNF,a.* from tempmodel a left join bra_suiv b on a.LOCALIDENTIFIER1=b.LOCALIDENTIFIER1
and a.NBVISIT=b.NBVISIT;quit;
%end;

data &stu..&&table&j;
set tempmodel_2;
label localidentifier1="Pat Ne" visitname="Visite" visitcyclenumber="Visite Ne" crftitle="form" crfpagecyclenumber="Fiche Ne" repeatnumber="Ligne Ne" ;
numvisit=0;
drop personid clinicaltrialid visitid crfpageid numvisit;
where LOCALIDENTIFIER1 NE "" and site ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee";
run;



	%if "&&group&j" NE "" %then %do;
		data &stu..&&table&j;
		set tempmodel_2;
		label localidentifier1="Pat Ne" visitname="Visite" visitcyclenumber="Visite Ne" crftitle="form" crfpagecyclenumber="Fiche Ne" repeatnumber="Ligne Ne" ;
		drop personid clinicaltrialid visitid crfpageid ;
		where LOCALIDENTIFIER1 NE "" and site ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee";
		run;

		data &stu..&&table&j;
		set &stu..&&table&j;
		drop OWNERQGROUPID;
		run;

	%end;
	%else %do;
	
		data &stu..&&table&j;
		set tempmodel_2;
		label localidentifier1="Pat Ne" visitname="Visite" visitcyclenumber="Visite Ne" crftitle="form" crfpagecyclenumber="Fiche Ne";
		drop personid clinicaltrialid visitid crfpageid ;
		where LOCALIDENTIFIER1 NE "" and site ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee";
		run;
	%end;

	data _null_;
	set temp end=final;
	call symputx("label"||left(_N_),dataitemname);
	call symputx("code"||left(_N_),dataitemcode);
	call symputx("type"||left(_N_),DATATYPE);
	call symputx("format"||left(_N_),DATAITEMFORMAT);
	if final then call symputx("nblabel",_N_);
	where table="&&table&j";
	run;
	proc contents  data=&stu..&&table&j noprint out=tempcontent;run;
	data tempcontent_&&table&j;
	set tempcontent;
	call symputx(NAME,FORMAT);
	run;

	%let format=;
	%do i=1 %to &nblabel;

		/* Format des dates et heures;	*/
		%if "&&code&i" NE "" and "&&label&i" NE "" %then  %let format=&format %str(;) label &&code&i="&&label&i" %str(;);
		%if &&type&i=1 %then %let format=&format %str(;) format &&code&i &&code&i..&stu.. %str(;);
		%if  "&&format&i"="dd/mm/yyyy" and "&&&&&&code&i"="DATETIME" %then %do;
			%let format=&format %str(;) &&code&i=datepart(&&code&i) %str(;);
			%let format=&format %str(;)format &&code&i DDMMYY10. %str(;);
		%end;

	%end;

	%put creation des labels : &format;
	data &stu..&&table&j;set &stu..&&table&j;&format;run;

	%if "&&table&j" NE "EXLUSION"  and "&&table&j" NE "CONSENT"  and "&&table&j" NE "VARIANT"  and "&&table&j" NE "TRASH"  %then %do;
		proc sql noprint; create table test as select a.* from &stu..&&table&j a left join exl b on
 		a.localidentifier1=b.localidentifier1
		left join stu.consent c on
 		a.localidentifier1=c.Patient
		where EXLU =. and demande_effacement_des_donn_es NE "Oui" ;quit;
		data &stu..&&table&j; set test;run;
		%suppr(test);

	%end;	



		%if "&&group&j" = "" %then %do; data &stu..&&table&j; retain &ordervar;set &stu..&&table&j; anumpat=localidentifier1 ; drop localidentifier1;run;%end;
		%if "&&group&j" NE "" %then %do; data &stu..&&table&j; retain &ordervar_g ;set &stu..&&table&j; anumpat=localidentifier1 ; drop localidentifier1;run;%end;



%suppr(tempcontent);
 %suppr(tempcontent_&&table&j);	


%end;

%mend;
%ApplyFormat_suiv(suiv,COBSUIV);








%macro ApplyFormat_anap(stu,mabase);



 %get_template(&stu,&mabase);

data _null_;set listtable end=final;call symputx("table"||left(_N_),table);call symputx("group"||left(_N_),QGROUPCODE);if final then call symputx("nbtable",_N_);run;

%do j=1 %to &nbtable;
	%put travail sur la table &stu..&&table&j;

	/* Preparation des cle de table + import des fiches vides + suppression mauvais enregistrements;*/
	proc sql noprint; create table tempmodel as select  "&mabase" as ESSAI format=$15. length=15,LOCALIDENTIFIER1,visitname,crftitle,e.CRFPAGESTATUS, &&table&j...* from &stu..&&table&j a
	left join &stu..studyvisit b on a.visitid=b.visitid and a.CLINICALTRIALID=b.CLINICALTRIALID
	left join &stu..crfpage c on a.crfpageid=c.crfpageid  and a.CLINICALTRIALID=c.CLINICALTRIALID
	left join &stu..trialsubject d on a.site=d.trialsite and a.personid=d.personid  and a.CLINICALTRIALID=d.CLINICALTRIALID
	left join &stu..CRFPAGEINSTANCE e on                           
 	a.site=e.trialsite and a.personid=e.personid  and a.CLINICALTRIALID=e.CLINICALTRIALID and
 	a.visitid=e.visitid and a.visitcyclenumber=e.visitcyclenumber and a.crfpageid=e.crfpageid and a.crfpagecyclenumber=e.crfpagecyclenumber
	where LOCALIDENTIFIER1 NE "" and site ne "supprime" and LOCALIDENTIFIER1 ne "personne non identifiee";
	;quit;
	/* Reorganise et harmonise la labelisation des variables d'identification des tables; */
	data &stu..&&table&j;
	retain site localidentifier1 visitname visitcyclenumber crftitle crfpagecyclenumber repeatnumber CRFPAGESTATUS nbq;
	set tempmodel;
	label localidentifier1="Pat Ne" visitname="Visite" visitcyclenumber="Visite Ne" crftitle="form" crfpagecyclenumber="Fiche Ne" repeatnumber="Ligne Ne" ;
	drop personid clinicaltrialid visitid crfpageid;
	run;

	%if "&&group&j" NE "" %then %do;
		data &stu..&&table&j;
		set &stu..&&table&j;
		drop OWNERQGROUPID;
		run;
		%end;

	%suppr(tempmodel);
	data _null_;
	set temp end=final;
	call symputx("label"||left(_N_),dataitemname);
	call symputx("code"||left(_N_),dataitemcode);
	call symputx("type"||left(_N_),DATATYPE);
	call symputx("format"||left(_N_),DATAITEMFORMAT);
	if final then call symputx("nblabel",_N_);
	where table="&&table&j";
	run;

	proc contents  data=&stu..&&table&j noprint out=tempcontent;run;
	data tempcontent_&&table&j;
	set tempcontent;
	call symputx(NAME,FORMAT);
	run;

	%let format=;
	%do i=1 %to &nblabel;

		/* Format des dates et heures;	*/
		%let format=&format %str(;) label &&code&i="&&label&i" %str(;);
		%if &&type&i=1 %then %let format=&format %str(;) format &&code&i &&code&i..&stu.. %str(;);
		%if  "&&format&i"="dd/mm/yyyy" and "&&&&&&code&i"="DATETIME" %then %do;
			%let format=&format %str(;) &&code&i=datepart(&&code&i) %str(;);
			%let format=&format %str(;)format &&code&i DDMMYY10. %str(;);
		%end;

	%end;
	data &stu..&&table&j;
	set &stu..&&table&j;
	&format;
	run;
	%if "&&group&j" NE "" %then %do;
	proc sort data=&stu..&&table&j; by localidentifier1 VISITCYCLENUMBER crfpagECYCLENUMBER repeatnumber;run;
	%end; %else %do;
	proc sort data=&stu..&&table&j; by localidentifier1 VISITCYCLENUMBER crfpagECYCLENUMBER ;run;

	%end;

	%if "&&table&j" NE "EXLUSION" %then %do;
 		proc sql noprint; create table test as select a.* from &stu..&&table&j a left join exl b on
 		a.localidentifier1=b.localidentifier1 where EXLU=.;quit;
		data &stu..&&table&j; set test;run;
		%suppr(test);

	%end;






	%if "&&group&j" NE "" %then %do;

		data &stu..&&table&j;set &stu..&&table&j;anumpat=localidentifier1 ; drop localidentifier1;;run;
		proc sort data=&stu..&&table&j; by site  anumpat   visitcyclenumber  crfpagecyclenumber repeatnumber ;;run;
	%end; %else %do;
		data &stu..&&table&j;set &stu..&&table&j;anumpat=localidentifier1 ; drop localidentifier1;run;
		proc sort data=&stu..&&table&j; by site  anumpat   visitcyclenumber  crfpagecyclenumber ;run;
		data &stu..&&table&j;set &stu..&&table&j;run;
	%end;
		data &stu..&&table&j;retain  site  anumpat   visitcyclenumber  crfpagecyclenumber ;set &stu..&&table&j;run;
%suppr(tempcontent);
 %suppr(tempcontent_&&table&j);	

%end;
%mend;


%ApplyFormat_anap(anap,COBANAP);
%ApplyFormat_anap(rel,COBREL);


/*

* Suppression des tables intermediaires;
%suppr(temp);
%suppr(Listtable);
%suppr(Tempmodel);
%suppr(Tempmodel_2);
%suppr(Nomtable);
%suppr(bra_incl);
%suppr(bra_suiv);
%suppr(exl);
*/
