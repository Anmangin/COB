
/* importer les fiches brutes avec leur statut */

%macro importFICHE(lib,nom);
proc sql nowarn noprint;create table Schedul as select * from &lib..studyvisitcrfpage left join &lib..studyvisit on studyvisitcrfpage.visitid=studyvisit.visitid
left join &lib..Crfpage on studyvisitcrfpage.CRFPAGEID=Crfpage.CRFPAGEID order by VISITORDER ,CRFPAGEORDER;
create table ScedulPRpat as select * from Schedul, &lib..trialsubject; QUit;
%suppr(Schedul)

data ScedulPRpat;
retain localidentifier1 trialsite personid VISITNAME VISITCODE VISITORDER CRFTITLE CRFPAGECODE CRFPAGEORDER visitid CRFPAGEID  ;
set ScedulPRpat;

keep localidentifier1 trialsite personid VISITNAME VISITCODE VISITORDER CRFTITLE CRFPAGECODE CRFPAGEORDER visitid CRFPAGEID ;
run;
data ScedulPRpat;set ScedulPRpat;rename trialsite=site;run;


proc sql noprint;
create table temp1 as select ScedulPRpat.*,VISITCYCLENUMBER,CRFPAGECYCLENUMBER, CRFPAGESTATUS,DISCREPANCYSTATUS,LOCKSTATUS,SDVSTATUS, int(MODIFIED)-21916 as Date_LASTM  format=DDMMYY10.  from ScedulPRpat
left join &lib..Crfpageinstance on ScedulPRpat.visitid=Crfpageinstance.visitid and ScedulPRpat.site=Crfpageinstance.trialsite and
ScedulPRpat.personid=Crfpageinstance.personid and ScedulPRpat.CRFPAGEID=Crfpageinstance.CRFPAGEID; QUit;
proc sql noprint; create table &nom as select a.* from temp1 a left join exl b  on a.localidentifier1=b.localidentifier1 where EXLU NE 1;quit;
%suppr(temp1);%suppr(ScedulPRpat);
%mend;
%importFICHE(INCL,relance_INCL);%importFICHE(SUIV,relance_SUIV);

proc format ;value base 1="Inclusion" 2="Suivi";run;
data relance_INCL;retain base;set relance_INCL;format base base.;base=1;run;
data relance_SUIV;retain base;set relance_SUIV;format base base.;base=2;run;
data Status_fiche;set relance_INCL relance_suiv;rename site=trialsite;if CRFTITLE NE "";run;
%suppr(relance_INCL);%suppr(relance_suiv);


 /* corriger les erreur de statut pour les OKWarning */
proc sql noprint; create table correctincl as select  1 as base,PERSONID, trialsite, visitid, CRFPAGEID, VISITCYCLENUMBER,CRFPAGECYCLENUMBER, count(CASE WHEN RESPONSESTATUS=10 THEN 1 ELSE . END) as st from ora_stui.dataitemresponse group by PERSONID, trialsite, visitid, CRFPAGEID, VISITCYCLENUMBER,CRFPAGECYCLENUMBER;quit;
proc sql noprint; create table correctSUIV as select DISTINCT 2 as base,PERSONID, trialsite, visitid, CRFPAGEID, VISITCYCLENUMBER,CRFPAGECYCLENUMBER, count(CASE WHEN RESPONSESTATUS=10 THEN 1 ELSE . END) as st as st from  ora_stus.dataitemresponse group by PERSONID, trialsite, visitid, CRFPAGEID, VISITCYCLENUMBER,CRFPAGECYCLENUMBER ;quit;
data correct;set correctincl correctSUIV;if ST = 0 then delete;run;%suppr(correctincl);%suppr(correctSUIV);
proc sort data= correct;by base PERSONID trialsite visitid CRFPAGEID VISITCYCLENUMBER CRFPAGECYCLENUMBER ; run;
proc sort data= Status_fiche;by base PERSONID trialsite visitid CRFPAGEID VISITCYCLENUMBER CRFPAGECYCLENUMBER ; run;
data Status_fiche;merge correct Status_fiche;by base PERSONID trialsite visitid CRFPAGEID VISITCYCLENUMBER CRFPAGECYCLENUMBER;run;
data Status_fiche;set Status_fiche;format CRFPAGESTATUS responsestatus.; if st>10 then CRFPAGESTATUS=-30; else if ST NE . then CRFPAGESTATUS=10 ;drop st ;run;
%suppr(correct);

  /* suppression des patients vide et des patients suppr et patient locké */
data Status_fiche;set Status_fiche; if localidentifier1 NE "" and LOCALIDENTIFIER1 ne "personne non identifiee" and CRFPAGESTATUS NE . and
CRFTITLE NE "" and localidentifier1 NE "" and find(localidentifier1,"Suppr")=0;
if substr(VISITCODE,1,5)="VISIT" then NBVISIT=VISITORDER-1;if NBVISIT=. then NBVISIT=0;
if visitname="Visite 16 et plus" then NBVISIT=15+ VISITCYCLENUMBER;


DROP LOCKSTATUS ;run;
proc sort data=Status_fiche;by LOCALIDENTIFIER1 NBVISIT;run;
 
/* apport d'info complémentaire sur les visite -> préparation des visites */
data planing_planing1;set suiv.planing_planing1;where anumpat NE "" and LISTVISIT NE . and DVISIT NE .;rename recipro=recipro2;keep anumpat DVISIT LISTVISIT BRA NBVISIT RECIPRO VNF;run;
proc sql noprint; create table 	 planing_planing2 as select a.*,DINCL,DSORTETU,PDVDATE, NSDDC from planing_planing1 a left join suiv.Planing b	on a.anumpat=b.anumpat;quit;
 data planing_planing1;set planing_planing2;run;


%macro planing_rec;
data planing_planing1;set planing_planing1;bra2=lag(BRA);if BRA=. then BRA=bra2; drop bra2;;run;
proc sql noprint; select sum(case when bra=. then 1 else 0 end) into:nbbram from planing_planing1;quit;
%if  &nbbram>0 %then %planing_rec;
%mend;
%planing_rec;

%macro addvisit;

 data test1; set planing_planing1; by localidentifier1;if last.localidentifier1;run; 
data test2;set test1;NBVISIT=NBVISIT+1;if LISTVISIT = 1 or LISTVISIT = 9 then DVISIT = DVISIT + 3*30 ;
if LISTVISIT = 2 then DVISIT = DVISIT + 6*30 ;if LISTVISIT > 2 and LISTVISIT NE 9  then DVISIT = DVISIT + 365 ;
if LISTVISIT = 8 then delete;if LISTVISIT<8 then LISTVISIT=LISTVISIT+1;if LISTVISIT=9 then LISTVISIT=1;
if dvisit>DINCL+ (6*365)  or dvisit>DSORTETU or dvisit>PDVDATE or dvisit>NSDDC  then delete;run;
proc sql noprint; select count(*) into:leftv from test2;quit;
%put  nb a renter : &leftv;
 %if &leftv>0 %then %do;
data planing_planing1;set planing_planing1 test2;run;
proc sort data=planing_planing1;by localidentifier1 NBVISIT;run;
%addvisit;
%end;
proc sort data=planing_planing1;by localidentifier1 NBVISIT;run;
%MEND;
%addvisit;%suppr(test1); %suppr(test2);

data planing_planing1;set planing_planing1; drop DINCL  DSORTETU PDVDATE NSDDC ;run;

proc sort data=planing_planing1;by anumpat DVISIT;run;
data planing_planing1;set planing_planing1;retain rec;by anumpat;if first.anumpat then rec=0;if LISTVISIT=9 then rec= rec+1;run;



data planing_planing1;set planing_planing1;format OID $10.;lastv=lag( LISTVISIT);if LISTVISIT=9 then do;LISTVISIT=	lastv +1 ;R=1;
end;
if rec=0 then OID="S";else OID=cats("R",rec,"-");
if LISTVISIT=1 then OID=cats(OID,"3M");else if LISTVISIT=2 then OID=cats(OID,"6M");
else if LISTVISIT=3 then OID=cats(OID,"1A");else if LISTVISIT=4 then OID=cats(OID,"2A");
else if LISTVISIT=5 then OID=cats(OID,"3A");else if LISTVISIT=6 then OID=cats(OID,"4A");
else if LISTVISIT=7 then OID=cats(OID,"5A");else if LISTVISIT=8 then OID=cats(OID,"6A");
if r=1 then	LISTVISIT=9;drop lastv;run;










proc sort data=planing_planing1;  by anumpat  rec LISTVISIT dvisit ; run;
data planing_planing1;set planing_planing1;by anumpat  rec LISTVISIT; format FLIV YN.; label FLIV="premiere visite du type"; if first.listvisit then FLIV=1;run;


proc sql noprint; create table Status_fiche2 as select Status_fiche.*, dvisit,  LISTVISIT, BRA, recipro2, VNF, OID, FLIV from Status_fiche 
left join planing_planing1 on Status_fiche.localidentifier1=planing_planing1.anumpat and  Status_fiche.NBVISIT=planing_planing1.NBVISIT;
quit;
data Status_fiche;set Status_fiche2;run;
%suppr(Status_fiche2);%suppr(planing_planing1); %suppr(planing_planing2);

proc sql;
create table desacF as
select Localidentifier1 ,CRFPAGECODE,CRFPAGECYCLENUMBER,VISITNAME,VISITORDER,VISITORDER-1 as NBVISIT ,VISITCYCLENUMBER from ora_stus.dataitemresponse
left join suiv.dataitem on dataitemresponse.DATAITEMID=dataitem.DATAITEMID 
left join suiv.trialsubject on dataitemresponse.personid=trialsubject.personid and dataitemresponse.trialsite=trialsubject.trialsite
left join suiv.studyVISIT on dataitemresponse.VISITID=studyVISIT.VISITID
left join suiv.CRFPAGE on dataitemresponse.CRFPAGEID=CRFPAGE.CRFPAGEID
where dataitemcode="DESAC" and VALUECODE="1";
QUit;


data desacF;set desacF;DESAC=1;run;
proc sort; by localidentifier1 NBVISIT CRFPAGECODE;run;
proc sort data=Status_fiche; by localidentifier1 NBVISIT CRFPAGECODE;run;

proc sql noprint; create table Status_fiche2 as select a.*,b.DESAC from Status_fiche a left join desacF b on
a.localidentifier1=b.localidentifier1 and a.NBVISIT=b.NBVISIT and a.CRFPAGECODE=b.CRFPAGECODE and a.VISITCYCLENUMBER=b.VISITCYCLENUMBER;  
quit;
%suppr(desacF);

data Status_fiche;set Status_fiche2; 
if DESAC = 1 AND CRFPAGEORDER > 11 AND BASE = 2 then CRFPAGESTATUS = -8 ;
else if DESAC = 1 then CRFPAGESTATUS = -10;
;run;







	   data QLQ1;set stu.Qlq_blm30;
			where BLMURINJ NE . or BLMURINN NE .  or BLMUNIRVIT NE . ;
			BLM30=1;
			if find(visitname,"Vis") then base=2; else do;
			base=1;

			end;
			rename anumpat=localidentifier1;
			keep anumpat 	base	nbvisit	  BLM30;
			run;

	   	data QLQ2;set stu.Qlq_bls24;
			where  BLSURINJ NE . and BLSURINN NE . and BLSFIEVRE NE .;
			bls24=1;
			if find(visitname,"Vis") then base=2; else do;
			base=1;
			visitname="";
			end;
			rename anumpat=localidentifier1;
			keep anumpat base nbvisit 			   bls24;  
			run;
		
		   data QLQ3;set stu.Qlq_qlq30;
			where not( QVEFFORT=. and EVASANT=.);
			QLQC30=1;
			if find(visitname,"Vis") then base=2; else do;
			base=1;
			end;
			rename anumpat=localidentifier1;
			keep anumpat 	base	nbvisit	   QLQC30;
			run;

			   data QLQ4;set stu.Dm_tabac_suivi;
			where  ( DJFUME NE . or REVMENS NE .);
			QLQTABA=1;
			if find(visitname,"Vis") then base=2; else do;
			base=1;

			end;
			rename anumpat=localidentifier1;
			keep anumpat 	base	nbvisit	   QLQTABA;
			run;

				   data QLQ5;set stu.Qlq_5d5l;
			where   ( MOBILITE NE . or OTONOM NE . or ACTIVIT NE . or DOULEUR NE . or ANXIETE NE . or ECHSANT NE .);
			Qlq_5d5l=1;
			if find(visitname,"Vis") then base=2; else do;
			base=1;
	
			end;
			rename anumpat=localidentifier1;
			keep anumpat 	base	nbvisit	   Qlq_5d5l;
			run;



 proc sql noprint nowarn; create table Status_fiche2 as select * from Status_fiche left join qlq1 
on  Status_fiche.localidentifier1=qlq1.localidentifier1 and  ( qlq1.base=2 and Status_fiche.nbvisit=qlq1.nbvisit  or (  qlq1.nbvisit=0 and Status_fiche.base=qlq1.base))
left join qlq2	  on  Status_fiche.localidentifier1=qlq2.localidentifier1 and (qlq2.base=2 and Status_fiche.nbvisit=qlq2.nbvisit  or (  qlq2.nbvisit=0 and Status_fiche.base=qlq2.base)) 
left join qlq3	  on  Status_fiche.localidentifier1=qlq3.localidentifier1 and Status_fiche.nbvisit=qlq3.nbvisit and (Status_fiche.crfpageid=10237 or Status_fiche.crfpageid=10277)   
left join qlq4	  on  Status_fiche.localidentifier1=qlq4.localidentifier1 and Status_fiche.nbvisit=qlq4.nbvisit and (Status_fiche.crfpageid=10309)
left join qlq5	  on  Status_fiche.localidentifier1=qlq5.localidentifier1 and Status_fiche.nbvisit=qlq5.nbvisit and (Status_fiche.crfpageid=10241 or Status_fiche.crfpageid=10235) ;quit;

data  Status_fiche2; 
set  Status_fiche2 ;
format DQLQ DDMMYY10.;
if 	Qlq_5d5l=1 or QLQTABA=1 or QLQC30=1 or bls24=1 or BLM30=1 then DQLQ=DVISIT;
run;
proc sql noprint; create table Status_fiche as select  a.*, max(DQLQ) as LASTQLQ format=DDMMYY10. from 	Status_fiche2 a group by localidentifier1
ORDER BY localidentifier1,VISITORDER,CRFPAGEORDER; quit;





data Status_fiche;
set Status_fiche;
if CRFPAGESTATUS NE -8 then do;
if DQLQ<DVISIT then do;
	if crfpagecode="QLQ30" and QLQC30 NE 1 then  CRFPAGESTATUS=-10;
	if crfpagecode="BLM30" and BLM30 NE 1 then  CRFPAGESTATUS=-10;
	if crfpagecode="BLS24" and BLS24 NE 1 then  CRFPAGESTATUS=-10;
	if crfpagecode="QPROFTABAC" and QLQTABA NE 1 then  CRFPAGESTATUS=-10;
	if crfpagecode="EQ_5D5L" and Qlq_5d5l NE 1 then  CRFPAGESTATUS=-10;
if LASTQLQ>DVISIT and crfpagecode in ("QLQ30","BLM30","BLS24","QPROFTABAC","EQ_5D5L") and  CRFPAGESTATUS=-10 then  CRFPAGESTATUS=-12;
end;end;
drop QLQC30  QLQTABA Qlq_5d5l;

run;
%suppr(Status_fiche2); %suppr(QLQ1);%suppr(QLQ2); %suppr(QLQ3);%suppr(QLQ4);%suppr(QLQ5);




proc sql noprint;create table Id_inc as select  a.anumpat as localidentifier1, a.anumpat as anumpat,  DEXCL,b.DINCL , /*input(a.DNAIS,DDMMYY10.) as DNAIS format=DDMMYY10. */ a.dnais, TPBRA as bra_incl,CRITINC,NSDDC,
DSORTETU, PDVDATE
from incl.demogr a
left join incl.Idenbra b on a.anumpat=b.anumpat 
left join incl.Exlusion c on a.anumpat=c.anumpat 
left join incl.descpat d on a.anumpat=d.anumpat
left join suiv.planing e on a.anumpat=e.anumpat;
quit;

proc sql noprint; create table Status_fiche2 as select * from Status_fiche a left join  Id_inc b on a.localidentifier1=b.localidentifier1;quit;
data Status_fiche;set Status_fiche2;CRFTITLE=CRFPAGEORDER||"-"||CRFTITLE;run;%suppr(Status_fiche2);
data Status_fiche;set Status_fiche;
fn_fol=DINCL + (6 * 365);if NSDDC NE . then fn_fol=NSDDC;if DSORTETU NE . then fn_fol=DSORTETU;if PDVDATE NE . then fn_fol=PDVDATE;format fn_fol DDMMYY10.;run;
 
data Status_fiche;
set Status_fiche;
if BRA=. and base=1 then BRA=BRA_INCL;
run;






*----------------------------------;

PROC IMPORT OUT= WORK.QLQ DATAFILE= "\\Nas-01\sbe_etudes\COBLANCE\07-Autres dossiers et fichiers crées\Statut_QLQ.xlsx" DBMS = xlsx REPLACE;
SHEET="QLQ";
GETNAMES=YES;
RUN;
   proc format;
value yn
1="Oui"
0="non"
2="Non";
run;
data QLQ;
set qlq;
*format Date ddmmyy10.;
rename Patient=localidentifier1
VAR2=NUMVISIT
Date=DVISIT
VAR4=reas
Autre_et_commentaire=reas_s	;
if upcase(VAR6)="NON" then NEXT=0;
else NEXT=1;

drop VAR6;
label next=Prochain QLQ dispo;
format NEXT YN.;
;
run;


 %macro runloop;
 proc sort data=qlq; by  localidentifier1 NUMVISIT;run;
data QLQ2;set qlq; by  localidentifier1 NUMVISIT; if last.localidentifier1 and NEXT=0 and NUMVISIT<30;DVISIT=.;NUMVISIT=NUMVISIT+1; run;
 proc sql noprint; select count(*) into:nbl from qlq2;quit;
%if &nbl>0 %then %do ;data qlq;set qlq qlq2;run;%runloop;%end;



%mend;
data liste_QLQ_NA; if 1=2;run;%runloop	;
data liste_QLQ_NA;set qlq;NAQLQ=1;run;%suppr(qlq);%suppr(qlq2);

*_______________________________;



%macro feuille(nomfeuille,ndb);
PROC IMPORT OUT= WORK.&ndb DATAFILE= "\\Nas-01\sbe_etudes\COBLANCE\07-Autres dossiers et fichiers crées\QQVMonitosKG2020.xlsx" DBMS = xlsx REPLACE;SHEET="&nomfeuille";GETNAMES=YES;RUN;
%runmappingmonito(&ndb);
%mend;
%macro runmappingmonito(base);
proc contents data=&base noprint out=listvar;run;
proc sort data=listvar; by VARNUM;run;
data listvar;set listvar;if NAME="N__COBLAnCE" or NAME="date_inclusion" or NAME="date_dc" or NAME="Commentaire" or LABEL="commentaires" then delete;run;
data _null_;set listvar end=endv;call symputx("name"||left(_N_),NAME);call symputx("LABEL"||left(_N_),LABEL);if endv then call symputx("nbvisit",_N_);run;
%DO i=1 %to &nbvisit;%MAPV(&base,&&name&i.,&i,&&label&i.);%end;
%suppr(listvar);
%mend;
 %macro MAPV(base,var,i,label);
data tempm;set &base;NVISIT=&i;labvisit="&label";rename &var=statut;label &var="Statut";rename N__COBLAnCE=Num_patient;keep N__COBLAnCE NVISIT labvisit &var;if &var ne "";run;
data final_monito;set final_monito tempm;run;
%suppr(Tempm);
%mend;
 data final_monito;if 1=2; format labvisit $30.;run;
%feuille(Foch 12-2020,QLQ1);%feuille(Lille 10-2020,QLQ2);
%feuille(Colmar 09-2020,QLQ3);%feuille(Nimes 07-2020,QLQ4);   
%feuille(Clermont 01-2020,QLQ5);%feuille(Mondor 03-2019,QLQ6);   
 proc sort data=final_monito;by Num_patient nvisit; run;
%suppr(QLQ1);%suppr(QLQ2);%suppr(QLQ3);%suppr(QLQ4);%suppr(QLQ5);%suppr(QLQ6);

 data final_monito; set final_monito; numvisit + 1; by Num_patient; if first.Num_patient then numvisit=1; run;
data final_monito;set final_monito;statut=upcase(statut);if statut="F" or statut="NA" or statut="C" or statut="VF" then statuQLQ=0;else  if statut="V" or statut="OK" then statuQLQ=1;drop statut; run;

data final_monito;set final_monito;labvisit=strip(labvisit);labvisit=tranwrd(labvisit,".","");
labvisit=tranwrd(labvisit," ","");labvisit=upcase(labvisit);if 	find(labvisit,"3M") then QLQV=1;else if find(labvisit,"6M") then QLQV=2;
else if find(labvisit,"1A") then QLQV=3;else if find(labvisit,"2A") then QLQV=4;
else if find(labvisit,"3A") then QLQV=5;else if find(labvisit,"4A") then QLQV=6;
else if find(labvisit,"5A") then QLQV=7;else if find(labvisit,"6A") then QLQV=8;
format QLQV LISTVISITSUIV.;numvisit=numvisit+1;format OID $10.;
if find(labvisit,"S") then OID="S";else OID=cats(substr(labvisit,1,2),"-");
if QLQV=1 then OID=cats(OID,"3M");else if QLQV=2 then OID=cats(OID,"6M");
else if QLQV=3 then OID=cats(OID,"1A");else if QLQV=4 then OID=cats(OID,"2A");
else if QLQV=5 then OID=cats(OID,"3A");else if QLQV=6 then OID=cats(OID,"4A");
else if QLQV=7 then OID=cats(OID,"5A");else if QLQV=8 then OID=cats(OID,"6A");
run;

 proc format lib=stu; value statuQLQ 1="Papier vu en monito" 0="QLQ absent en monito"; run;
 /*AJOUT dans Status_fiche DES VARIABLES POUR LES QLQ issue des monito de Karine et un fichier excel crée par moi issu des comentaires pour ne plus demander les qlq */
proc sql noprint; create table Status_fiche2 as select a.*, statuQLQ format=statuQLQ. , QLQV, labvisit from Status_fiche  a full join final_monito b on a.localidentifier1=b.Num_patient and a.oid=b.oid and FLIV=1;quit;
data Status_fiche;set Status_fiche2;run;%suppr(Status_fiche2);
proc sql noprint; create table Status_fiche2 as select a.*, NAQLQ	"Comment NA QLQ" from Status_fiche  a  left join Liste_qlq_na b on a.localidentifier1=b.localidentifier1 and a.NBVISIT=b.NUMVISIT;quit;
data Status_fiche;set Status_fiche2;if CRFPAGESTATUS NE .;run;%suppr(Status_fiche2);
/* CALCUL DES Fiches manquantes -30 = missing ; -12 = c'est manquant mais on ne peut pas obtenir l'information (ex: deviation protocolaire) */
data Status_fiche;
set Status_fiche;
/* partie QLQ */
if 	crfpagestatus=-10  then do;
	if (CRFPAGECODE="BLS24" or CRFPAGECODE="BLM30" or CRFPAGECODE="EQ_5D5L" or CRFPAGECODE="QPROFTABAC" or CRFPAGECODE="QPROFTABAC" or CRFPAGECODE="QLQ30"   ) then do;
		if NAQLQ = 1 or FLIV NE 1 then crfpagestatus=-12;
			else if LISTVISIT=1 and NBVISIT=1 then crfpagestatus=-12;
			else if  (bls24 NE . or BLM30 NE .) and (CRFPAGECODE="BLS24" or CRFPAGECODE="BLM30") then crfpagestatus=-12;
			else if LISTVISIT=9 then crfpagestatus=-12;
			else if CRFPAGECODE="BLS24" and bra=1 then crfpagestatus=-12;
			else  if CRFPAGECODE="BLM30" and bra=2 then crfpagestatus=-12;
			else crfpagestatus=-30;
	end;

	else if  base=1 then do;/* partie inclusion */
		if crfpageorder=20  then  crfpagestatus=-12	 ;
		else if VISITCODE="Ident_bra"  then  crfpagestatus=-30;
		else if VISITCODE="Eco_com"  then  crfpagestatus=-30;
		else if crfpageorder=28  then crfpagestatus=-12;
		else if crfpagecode="REHOSPT" or VISITCODE="Epid"  then	crfpagestatus=-12;
		else if (BRA=1 or BRA=3 ) and VISITCODE="Eco_TVIM"  then  crfpagestatus=-30;
		else if BRA=2   and VISITCODE="Eco_TVNIM"  then  crfpagestatus=-30;
		else if BRA=2   and VISITCODE="Eco_TVIM"  then  crfpagestatus=-12;
		else if (BRA=1 or BRA=3)  and VISITCODE="Eco_TVNIM"  then  crfpagestatus=-12;
	end	 ;

 	else if  base=2 then do;/* partie suivi */	

		if VNF=1 then  crfpagestatus=-12;
		if LISTVISIT=9 and CRFPAGEORDER>12 then crfpagestatus=-12; 
		else if BRA NE 1 and CRFPAGEORDER>=9 and CRFPAGEORDER<=11 then crfpagestatus=-12;
		else if  BRA NE 2 and CRFPAGEORDER>=4 and CRFPAGEORDER<=9 then  crfpagestatus=-12;
		else if CRFPAGEORDER=3 and DVISIT NE . then  crfpagestatus=-30; 
 		else if BRA=2 and CRFPAGEORDER>=4 and CRFPAGEORDER<=9 then do ;
			if CRFPAGEORDER =7 then crfpagestatus=-12;
  			else if  CRFPAGEORDER=4  then crfpagestatus=-30;
			else if  CRFPAGEORDER=5 then do ;if recipro2=1 then crfpagestatus=-30; else crfpagestatus=-12; end;
			else if  CRFPAGEORDER =>6 then do ;if recipro2=2 then crfpagestatus=-30; else crfpagestatus=-12; end;
		end;
	
 		else if BRA=1 and CRFPAGEORDER>=9 and CRFPAGEORDER<=11 then do ;
  			if       CRFPAGEORDER=10  then crfpagestatus=-30;
			else if  LISTVISIT=9 then crfpagestatus=-30; else crfpagestatus=-12; 		
		end;
	end ;
end ;
if VNF=1 and crfpagestatus=-30 then  crfpagestatus=-12;


if  find( crftitle,"Identifiant patient")>0 and crfpagestatus=-30 then crfpagestatus=-10;
run;

/*if crfpagestatus=-12 then crfpagestatus=-10;*/
run;
data Status_fiche;set Status_fiche; if base=1 then OID="Inclusion";	run;
proc sort data=Status_fiche nodupkey;by localidentifier1 base VISITORDER visitcyclenumber crfpageorder crfpagecyclenumber  ;run;
proc format lib=stu ;
value LISTVISITS
0="inclusion"
1="visite à 3 mois"
2="Visite à 6 mois"
3="visite à 1 an"
4="visite a 2 ans"
5="visite à 3 ans"
6="visite à 4 ans"
7="visite à 5 ans"
8="visite à 6 ans"
9="récidive";
QUit;
  /*CORRECTION DES LABEL DE VISITE POUR UNE MEILLEUR LISIBILITé */
data Status_fiche;set Status_fiche;if find(visitname,"16")>0 then NBVISIT= 15 + VISITCYCLENUMBER;
if find(visitname,"16")>0 then VISITORDER= 15 + VISITCYCLENUMBER; if find(visitname,"16")>0 then visitname='Visite N?'||left(NBVISIT);
if nbvisit=0 then DVISIT=dincl;run;


proc sql noprint; create table stat_visit as select distinct fn_fol,DVISIT,NBVISIT,localidentifier1,OID, BRA,BRA_incl,
case when VISITNAME = "CTRL" then "Planing de suivi" when find(VISITNAME,"Visit")=0 then "Inclusion" else VISITNAME end   as vtype,
sum(case when crfpagestatus=-30 and not ( base=2 and CRFPAGEORDER>12) then 1 else 0 end) as nbmis ,
sum(case when crfpagestatus=-30  and base=2 and CRFPAGEORDER>12 then 1 else 0 end) as nbmisQLQ ,
sum(case when crfpagestatus=10 or crfpagestatus=30 or (DISCREPANCYSTATUS NE 0 and DISCREPANCYSTATUS NE 10) then 1 else 0 end) as nbq,
sum(case when SDVSTATUS=40 then 1 else 0 end) as nbsdv  ,
sum(case when crfpagestatus>=0  and DESAC NE 1 and find(crftitle,"3-Identifiant patient")=0 then 1 else 0 end) as nbOK  ,
PDVDATE	 ,
max(Date_LASTM) as Date_LASTM format=DDMMYY10.,
VNF	format=1.
from Status_fiche group by OID,DVISIT, NBVISIT,localidentifier1, vtype ,fn_fol,VNF having dexcl=. ORDER BY localidentifier1 ,NBVISIT ;

quit;



	
data stat_visit;
set stat_visit;
if DVISIT=. or VTYPE="Planing de suivi" then delete;
run;

/* on suppose les visite suivante */
%macro extrapol_stat_visit;
proc sql noprint; create table stat_visit_temp0 as select a.*, max(NBVISIT) as MAXVISIT from stat_visit a group by localidentifier1;quit;

  proc sort data=stat_visit_temp0; by  localidentifier1 DVISIT;run;
data stat_visit_temp;set stat_visit_temp0;by localidentifier1;delta=intck('month',DVISIT,fn_fol);

if find(OID,"Inclusion") then do;
OID="S6M";DVISIT=DVISIT+(30*6);
end ;
else if find(OID,"3M") then do;OID=cats(substr(OID,1,length(OID)-2),"6M"); DVISIT=DVISIT+(30*3); end;
else if find(OID,"6M") then do; OID=cats(substr(OID,1,length(OID)-2),"1A");DVISIT=DVISIT+(30*6); end;
else if find(OID,"1A") then do; OID=cats(substr(OID,1,length(OID)-2),"2A");DVISIT=DVISIT+(365); end	 ;
else if find(OID,"2A") then do; OID=cats(substr(OID,1,length(OID)-2),"3A");DVISIT=DVISIT+(365); end	 ;
else if find(OID,"3A") then do; OID=cats(substr(OID,1,length(OID)-2),"4A");DVISIT=DVISIT+(365); end	;
else if find(OID,"4A") then do; OID=cats(substr(OID,1,length(OID)-2),"5A");DVISIT=DVISIT+(365); end	;
else if find(OID,"5A") then do; OID=cats(substr(OID,1,length(OID)-2),"6A");DVISIT=DVISIT+(365); end	;
else if find(OID,"6A") then delete;
else do; OID=cats(OID,"1A");DVISIT=DVISIT+(365); end;
if delta>=12;nbmis=99;
if DVISIT<date() and DVISIT<fn_fol and last.localidentifier1;
ADD=1;drop delta;
run;

data stat_visit_temp;
set stat_visit_temp;
NBVISIT=NBVISIT+1;
if MAXVISIT+1 >NBVISIT then NBVISIT=AXVISIT+1;
vtype='Visite N?'||left(NBVISIT);
run;
data stat_visit;set stat_visit stat_visit_temp;run;
proc sort data=stat_visit; by localidentifier1 DVISIT;run;

proc sql noprint; select count(*) into:nbadd from stat_visit_temp;quit;
%suppr(stat_visit_temp0);
%suppr(stat_visit_temp);

   %if &nbadd > 0 %then %extrapol_stat_visit;
%mend;
%extrapol_stat_visit	;




proc sql noprint; create table atest as select a.* from Stat_visit a left join stu.Et_exclusion b on a.localidentifier1=b.localidentifier1 where b.dexcl = .;quit;
data Stat_visit;set  atest;format statut $500.;
if vtype="Planing de suivi" then delete;
statut= catx(" ", put(dvisit,ddmmyy10.),OID);
if nbmis=0 and nbq=0 and nbsdv=0 and nbmisQLQ=0 then statut= catx(" ",statut,"(*ESC*)n","OK");;
if nbmis=99 then statut= catx(" ",statut,"(*ESC*)n"," Nouvelle visite à saisir");
if nbmis>0  and nbmis NE 99 then statut= catx(" ",statut,"(*ESC*)n",nbmis," Fiche(s) manquante(s)");
if nbmisQLQ>0 and nbmis NE 99 then statut= catx(" ",statut,"(*ESC*)n",nbmisQLQ," QLQ Absent(s)");

if nbq>0 then  statut= catx(" ", statut,"(*ESC*)n" ,nbq, "Requete(s) DM");
if nbsdv>0 then  statut= catx(" ", statut,"(*ESC*)n",nbsdv, "Requete(s) MONITO"); 
nom= "V"||left(NBVISIT);;lab= "Vis. "||left(NBVISIT);run;  


%suppr(atest);


proc sort data=Stat_visit;  by localidentifier1	 NBVISIT DVISIT;run;
data  Stat_visit; set Stat_visit; by localidentifier1 NBVISIT; if last.NBVISIT;run;

proc transpose data=Stat_visit out=stat_final;
by  localidentifier1 ;
ID nom;
var statut	;
run;




proc format;
value $color
ok=green
other=white;
run;

data stat_final;retain CENTRE; set stat_final;
CENTRE=substr(localidentifier1,1,2);
run;

%suppr(Id_inc);
/*%suppr(Status_fiche2);%suppr(Stat_visit_temp);%suppr(Test2);*/


%macro CreatMetric;

proc sort data= Status_fiche;by trialsite;run;
Proc sql noprint; create table stats as select  trialsite as site2, sum(case when  CRFPAGESTATUS=0 or CRFPAGESTATUS=25 or CRFPAGESTATUS=30 then 1 else 0 end) as FILLED, sum(case when  CRFPAGESTATUS=-30 then 1 else 0 end) as DUE from Status_fiche group by trialsite ;quit;
Proc sql noprint; create table statstemp as select  SITE as site2,filled, DUE from incl.site  a left join stats b on a.site=b.site2 ;quit;

proc sql noprint; create table nbcount as  select TRIALSITE,sum(case when responsestatusTXT LIKE '%Missing%' then 1 else 0 end) as Missing,  sum(case when responsestatusTXT LIKE '%Warning%' then 1 else 0 end) as warning, sum(case when responsestatusTXT LIKE '%DCR%' then 1 else 0 end) as DCR from FINALDCR group by TRIALSITE;quit;

proc sql noprint; create table finalcount as select * from statstemp a full join nbcount b on a.site2=b.TRIALSITE;quit;

						 
data finalcount;
set finalcount;
if FILLED=. then FILLED=0;
if TRIALSITE="" then TRIALSITE=site2;
if site2="" then site2=TRIALSITE;
if Missing=. then Missing=0;
if due=. then due=0;
if dcr=. then dcr=0;
if warning=. then warning=0;
run;

proc sql noprint; create table temp as select finalcount.*, SITEdescription,COUNTRYDESCRIPTION, COUNTRYCODE from finalcount right join incL.SITE on trialsite=SITE
left join incl.macrocountry on COUNTRYID=SITECOUNTRY;



data _METRICS_SITE;
retain COUNTRYCODE COUNTRYDESCRIPTION trialsite SITEdescription due missing warning dcr;
set temp;
drop site2;
format pc percent.;
pc=FILLED / (FILLED+DUE);

label missing="Missing data"
due="Missing form"
dcr="Discrepancies from DM"
warning="Active warning"
COUNTRYCODE="Country"
COUNTRYDESCRIPTION="Country"
trialsite="Site"
SITEDESCRIPTION="Site"
run;
proc sort; by SITEdescription;run;
%suppr(temp);
%suppr(stats);
%suppr(statstemp);
%suppr(finalcount);
%suppr(nbcount);





proc sort data= status_fiche;by trialsite;run;

Proc sql noprint; create table stats as select  trialsite as site2,personid as personid2,sum(case when  CRFPAGESTATUS=0 or CRFPAGESTATUS=25 or CRFPAGESTATUS=30 then 1 else 0 end) as FILLED, sum(case when  CRFPAGESTATUS=-30 then 1 else 0 end) as DUE from Status_fiche  group by trialsite ,personid ;quit;

Proc sql noprint; create table statstemp as select  trialsite as site2,personid as personid2,DUE from incl.trialsubject a left join stats b on a.TRIALSITE=b.site2 and a.personid=b.personid2;quit;


proc sql noprint; create table nbcount as  select TRIALSITE,personid, sum(case when responsestatusTXT LIKE '%Missing%' then 1 else 0 end) as Missing,  sum(case when responsestatusTXT LIKE '%Warning%' then 1 else 0 end) as warning, sum(case when responsestatusTXT LIKE '%DCR-Raised%' then 1 else 0 end) as DCR from FINALDCR group by TRIALSITE , personid;quit;

proc sql noprint; create table finalcount as select * from statstemp a full join nbcount b on a.site2=b.TRIALSITE and a.personid2=b.personid;quit;


data finalcount;
set finalcount;
if personid=. then personid=personid2;
if personid2=. then personid2=personid;
if TRIALSITE="" then TRIALSITE=site2;
if site2="" then site2=TRIALSITE;
if Missing=. then Missing=0;
if due=. then due=0;
if dcr=. then dcr=0;
if warning=. then warning=0;
run;

proc sql noprint; create table temp as select finalcount.*, SITEdescription,COUNTRYDESCRIPTION, COUNTRYCODE,localidentifier1 from finalcount right join 
incl.SITE  on trialsite=SITE
left join incl.macrocountry on COUNTRYID=SITECOUNTRY
left join incl.trialsubject on  finalcount.TRIALSITE=trialsubject.TRIALSITE and finalcount.personid=trialsubject.personid;



data _METRICS_PAT;
retain  COUNTRYCODE COUNTRYDESCRIPTION  SITEdescription  trialsite personid localidentifier1  due missing warning dcr;
set temp;
drop site2 personid2 COUNTRYCODE COUNTRYDESCRIPTION;
where LOCALIDENTIFIER1 NE "";
label missing="Missing data"
due="Missing form"
dcr="Discrepancies from DM"
warning="Active warning"
COUNTRYCODE="Country"
COUNTRYDESCRIPTION="Country"
trialsite="Site"
SITEDESCRIPTION="Site"
LOCALIDENTIFIER1="N°pat";
run;
proc sort; by localidentifier1 ;run;
%suppr(temp);
%suppr(stats);
%suppr(statstemp);
%suppr(finalcount);
%suppr(nbcount);



data Stat_visit



proc sort data= status_fiche;by trialsite;run;
Proc sql noprint; create table stats as select   sum(case when  CRFPAGESTATUS=0 or CRFPAGESTATUS=25 or CRFPAGESTATUS=30 then 1 else 0 end) as FILLED, sum(case when  CRFPAGESTATUS=-30 then 1 else 0 end) as DUE from status_fiche;quit;

proc sql noprint; create table nbcount as  select sum(case when responsestatusTXT LIKE '%Missing%' then 1 else 0 end) as Missing,  sum(case when responsestatusTXT LIKE '%Warning%' then 1 else 0 end) as warning, sum(case when responsestatusTXT LIKE '%DCR-Raised%' then 1 else 0 end) as DCR from FINALDCR;quit;

proc sql noprint; create table finalcount as select * from stats, nbcount;quit;


data _METRICS_TRIAL;
set finalcount;
if FILLED=. then FILLED=0;
if Missing=. then Missing=0;
if due=. then due=0;
if dcr=. then dcr=0;
if warning=. then warning=0;
label missing="Missing data"
due="Missing form"
dcr="Discrepancies from DM"
warning="Active warning"
run;


%suppr(stats);
%suppr(finalcount);
%suppr(nbcount);

%MEND;
%CreatMetric;



/*



%MACRO suppr(table);
proc sql noprint; Drop Table &table;quit;
%mend;
%macro vider(lib);
%put macro vider activée  lib=&lib;
data nomtable ;set sashelp.vstable;where libname="&lib.";
if memname='TIMEDOWN' or memname='timedown' or memname="NOMTABLE" or memname="Finaldcr" or memname="FINAL_MONITO" or memname="STAT_FINAL" or memname="EXL" or memname="FINALDCR" or memname='_METRICS_PAT' or memname='_METRICS_SITE'
or memname='_METRICS_TRIAL'  then delete;
run;

proc sql noprint;select distinct count(*) into: nbtable from nomtable; quit;
%do i=1 %to &nbtable.;
data _null_ ;set nomtable; if _N_=&i then call symput("memname",memname) ; run;
%suppr(&lib..&memname.);
%end;
%mend;
%VIDEr(WORK);
*/
