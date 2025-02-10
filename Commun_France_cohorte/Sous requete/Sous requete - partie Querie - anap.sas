  proc format lib=stu;
value formatS
0="Vide"
1="- de 6mois"
2="Retard (absent dans le suivi)"
3="donnée Manquante"
4="incohérence"
5="Exploitable"
11="- de 1 an"
12="- de 2 an";
run;
proc format lib=stu;
value responsestatus
-30	=DUE
-12	=NA
-11	=Absent
-10	=Vierge
-8	=Inactivé
-5	=Not available
0	=Complete
10	=MIssing
25	=OKW
30	=WArning
31 =DCR
.   =inactivé;
value STATUT
-30	=DUE
-11	=Absent
-10	=Vierge
-8	=Inactivé
-5	=Not available
0	=Complete
10	=MIssing
25	=OKW
30	=WArning
31 =DCR
.   =inactivé;
run;
%let date=%sysfunc(today(),ddmmyy10.);
%put &date;

%let dateana=%sysfunc(today(),date9.);

%macro suppr(table);
proc sql;
DROP TABLE &table.;
QUit;
%MEND;

 %let stu=anap;
 %let ora=Ora_anap;

%macro relance(stu=stu,ora=ora);

proc sql noprint;
create table MESSAGE AS
SELECT MIMESSAGETYPE, MIMESSAGESTATUS ,MIMESSAGEpersonid as personid, MIMESSAGESITE as trialsite, MIMESSAGEVISITID as visitid,MIMESSAGECRFPAGEID as CRFPAGEID, MIMESSAGEVISITCYCLE as VISITCYCLEnumber,MIMESSAGECRFPAGECYCLE as CRFPAGECYCLEnumber,MIMESSAGEDATAITEMID as dataitemid, MIMESSAGE.MIMESSAGERESPONSECYCLE as repeatnumber,
MIMESSAGERESPONSEVALUE, MIMESSAGE.MIMESSAGETEXT, int(MIMESSAGECREATED)-21916 AS MIMESSAGECREATED format=ddmmyy10.
FROM &stu..MIMESSAGE
where MIMESSAGEHISTORY=0 and ((MIMESSAGETYPE=0 and MIMESSAGESTATUS=0 )or (MIMESSAGETYPE=3 and MIMESSAGESTATUS=1 ));
create table notes AS
SELECT MIMESSAGEpersonid as personid, MIMESSAGESITE as trialsite, MIMESSAGEVISITID as visitid,MIMESSAGECRFPAGEID as CRFPAGEID, MIMESSAGEVISITCYCLE as VISITCYCLEnumber,MIMESSAGECRFPAGECYCLE as CRFPAGECYCLEnumber,MIMESSAGEDATAITEMID as dataitemid, MIMESSAGE.MIMESSAGERESPONSECYCLE as repeatnumber,
MIMESSAGERESPONSEVALUE, MIMESSAGE.MIMESSAGETEXT, int(MIMESSAGECREATED)-21916 AS MIMESSAGECREATED format=ddmmyy10.
FROM &stu..MIMESSAGE
where MIMESSAGEHISTORY=0 and MIMESSAGETYPE=2 and MIMESSAGESTATUS=0;


create table temp_requete as select a.clinicaltrialid,a.trialsite,a.personid,a.visitid,a.crfpageid,a.crfpagecyclenumber,a.visitcyclenumber,a.dataitemid,a.repeatnumber,a.RESPONSEVALUE,a.RESPONSESTATUS,a.VALIDATIONMESSAGE,a.COMMENTS,a.LOCKSTATUS,a.DISCREPANCYSTATUS,a.SDVSTATUS,int(a.RESPONSETIMESTAMP)-21916 AS RESPONSETIMESTAMP format ddmmyy10.
from &ora..dataitemresponse a
where  (a.RESPONSESTATUS>0 AND a.RESPONSESTATUS ne 25 AND a.LOCKSTATUS=0 ) or a.DISCREPANCYSTATUS=30  or  a.SDVSTATUS=40;


create table temp_requete2 as select a.*, CRFPAGEINSTANCELABEL from temp_requete a left join &stu..crfpageinstance b on a.trialsite=b.trialsite and a.personid=b.personid and a.VISITID=b.visitid and
a.VISITCYCLENUMBER=b.VISITCYCLENUMBER and a.crfpagecyclenumber=b.crfpagecyclenumber and a.crfpageid=b.crfpageid;


proc sql noprint;create table temp_requete3 as select a.*, MIMESSAGETYPE,MIMESSAGESTATUS, MIMESSAGETEXT as QUERI_RESP "QUERI_RESP",MIMESSAGERESPONSEVALUE from  temp_requete2 a full join message b on a.trialsite=b.trialsite and a.personid=b.personid and a.VISITID=b.visitid and
a.VISITCYCLENUMBER=b.VISITCYCLENUMBER and a.crfpagecyclenumber=b.crfpagecyclenumber and a.crfpageid=b.crfpageid and a.dataitemid=b.dataitemid and a.repeatnumber=b.repeatnumber;

  data temp_requete3;set temp_requete3; if QUERI_RESP ne "" then  VALIDATIONMESSAGE=catx("/",VALIDATIONMESSAGE,QUERI_RESP); drop QUERI_RESP;run;

proc sql noprint; create table temp_requete4 as select  a.*,SITEDESCRIPTION from temp_requete3 a left join &stu..site  b on a.trialsite=b.site;

proc sql noprint; create table temp_requete5 as select  a.*,localidentifier1 from temp_requete4 a left join &stu..trialsubject  b on a.personid=b.personid and a.trialsite=b.trialsite;

proc sql noprint; create table temp_requete6 as select  a.*,FIELDORDER,caption,OWNERQGROUPID from temp_requete5 a left join &stu..CRFELEMENT  b on  a.crfpageid=b.crfpageid and a.DATAITEMID=b.DATAITEMID;

proc sql noprint; create table temp_requete7 as select  a.*,crftitle,crfpageorder from temp_requete6 a left join &stu..crfpage  b on a.crfpageid=b.crfpageid;
proc sql noprint; create table temp_requete8 as select  a.*,VISITORDER,visitname,REPEATING from temp_requete7 a left join &stu..studyvisit  b on a.visitid=b.visitid;
proc sql noprint; create table temp_requete9 as select  a.*,dataitemname from temp_requete8 a left join &stu..dataitem  b on a.dataitemid=b.dataitemid;
create table temp_requete10 as select a.*, b.MIMESSAGETEXT as notes from  temp_requete9 a left join notes b on a.trialsite=b.trialsite and a.personid=b.personid and a.VISITID=b.visitid and
a.VISITCYCLENUMBER=b.VISITCYCLENUMBER and a.crfpagecyclenumber=b.crfpagecyclenumber and a.crfpageid=b.crfpageid and a.dataitemid=b.dataitemid and a.repeatnumber=b.repeatnumber;




data &stu..finalDCR;
retain SITEDESCRIPTION LOCALIDENTIFIER1 VISITNAME VISITCYCLENUMBER CRFTITLE CRFPAGEINSTANCELABEL;
set temp_requete10;
label SITEDESCRIPTION="Site"
LOCALIDENTIFIER1="N°pat"
VISITNAME="Visit"
VISITCYCLENUMBER="N°visite"
CRFTITLE="eForm"
CRFPAGECYCLENUMBER="N°eForm"
DATAITEMNAME="Question"
RESPONSEVALUE="Response"
VALIDATIONMESSAGE="Query"
responsestatusTXT="Status"
RESPONSETIMESTAMP="Date of query"
CRFPAGEINSTANCELABEL="label"
MIMESSAGERESPONSEVALUE="Reponse au moment de la DCR";
where CLINICALTRIALID NE .;
run;
proc sort data=&stu..finalDCR; by trialsite personid visitorder visitcyclenumber CRFPAGEORDER crfpagecyclenumber;run;

data &stu..finalDCR;
set &stu..finalDCR;
format responsestatusTXT $15.;
format RESPONSESTATUS statut.;
if DISCREPANCYSTATUS=30 then RESPONSESTATUS=31;
if MIMESSAGETEXT NE "" then VALIDATIONMESSAGE=MIMESSAGETEXT;
if REPEATING NE . then visitname=catx(' ',visitname,'( N°',VISITCYCLENUMBER,')');
if crfpagecyclenumber>1 then crftitle=catx(' ',crftitle,'( N°',crfpagecyclenumber,')');
if OWNERQGROUPID > 0 then dataitemname=catx(' ',dataitemname,'( N°',repeatnumber,')');

if  MIMESSAGETYPE=3 then responsestatusTXT="SDV-Raised";
else if  RESPONSESTATUS=31 then responsestatusTXT="DCR-Raised";else if RESPONSESTATUS=10 then responsestatusTXT="Missing";else if RESPONSESTATUS=30 then responsestatusTXT="Warning";
drop MIMESSAGETEXT LOCKSTATUS;
run;

%suppr(temp_requete);
%suppr(temp_requete2);
%suppr(temp_requete3);
%suppr(temp_requete4);
%suppr(temp_requete5);
%suppr(temp_requete6);
%suppr(temp_requete7);
%suppr(temp_requete8);
%suppr(temp_requete9);
%suppr(temp_requete10);
%suppr(Message);
%suppr(Notes);
%mend;

* PGU : (07/09/2021) : suppr Message et Notes;

%macro connexion(login,base,password,serveur,ora=ora);
libname &ora oracle user=&login. password = &password. path=&serveur schema=&base. DBMAX_TEXT=32767;
%MEND;

%connexion(cobinc,cobinc_ora,sbam01,macro4,ora=ora_stui);
%connexion(cobsuivi,cobsuivi_ora,sbam01,macro4,ora=ora_stus);


%relance(stu=anap,ora=ora_anap);

proc format lib=stu;;
value base
1="Inclusion"
2="Suivi";
run;


   /*

 Proc sql noprint;
create table temp_requete as select clinicaltrialid,trialsite,personid,visitid,crfpageid,crfpagecyclenumber,visitcyclenumber,dataitemid,repeatnumber,COMMENTS
from ora_stui.dataitemresponse
where COMMENTS NE " ";
proc sql noprint; create table temp_requete2 as select  a.*,crftitle,crfpageorder from temp_requete a left join ora_stui.crfpage  b on a.crfpageid=b.crfpageid;
proc sql noprint; create table temp_requete3 as select  a.*,localidentifier1 from temp_requete2 a left join ora_stui.trialsubject  b on a.personid=b.personid and a.trialsite=b.trialsite;

data temp_requete4;
set temp_requete3;
if find(UPCASE(CRFTITLE),"QLQ")>0 OR find(UPCASE(CRFTITLE),"5D5L")>0;

run;

*/
