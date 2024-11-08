/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables d'analyse biologiques

 Ce fichier permet de créer les tables mappées concernant les analyses biologiques des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas 
		      07_mapping RTUV.sas 
		   et 08_mapping cystectomie.sas doivent avoir été lancés;

* Necessite 07_mapping RTUV.sas;
data CL_RTUV;
set stu.CL_RTUV;
if TTIDBH NE . and 	DTTIRT = . then DTTIRT=TTIDBH;
zrzoju=TTIRMOT;
where TTIRTV=1;
run;
proc sql noprint;create table stu.List_chir as 

select  anumpat, nbvisit, "INCLUSION" as visitname, "INCLUSION" as EVENT "Evenement", 	   DINCL as DATEE "Date" format=DDMMYY10., catx("/" , put(BRA_INCL,TPBRAINCL.),put(CRITINC,CRITINCINCL.)) as comment, . as TTIGTTOT, "" as EXE from stu.RESUME	
;quit;



* Fusionne et met en forme plusieurs tables mappées;
proc sql noprint; create table stu.List_chir as 
select anumpat, nbvisit, "RTUV" as EVENT "Evenement", 	   DTTIRT as DATEE "Date" format=DDMMYY10., catx( "/",put(TTIRTNB,TTIRTNBINCL.), case WHEN TTIRMOT NE 4 THEN put(TTIRMOT,TTIR2MOTINCL.) ELSE TTIRTMOTP END ) as comment,TTIGTTOT, " " as EXE  from CL_RTUV 
UNION
select  anumpat, nbvisit, "CYSTECTOMIE" as EVENT "Evenement", 	   CYSDBH as DATEE "Date" format=DDMMYY10., CYSIN as comment, . as TTIGTTOT, case when EXEP NE "" then EXEP else put(EXE ,NIMEXEINCL.) end as EXE  from stu.CL_cystectomie  where CYS=1
UNION
select  anumpat, nbvisit, "INCLUSION" as EVENT "Evenement", 	   DINCL as DATEE "Date" format=DDMMYY10., catx("/" , put(BRA_INCL,TPBRAINCL.),put(CRITINC,CRITINCINCL.)) as comment, . as TTIGTTOT, "" as EXE from stu.RESUME	
UNION
select  anumpat, nbvisit, "TVNIM - PROGRESSION" as EVENT "Evenement", 	   PRDEVNT as DATEE "Date" format=DDMMYY10., " " as comment, . as TTIGTTOT,  "" as EXE from suiv.tvnimprog where PRDEVNT NE .	
UNION
select  anumpat, nbvisit, "TVIM - PROGRESSION" as EVENT "Evenement", 	   IMDEVNT as DATEE "Date" format=DDMMYY10., " " as comment, . as TTIGTTOT,  "" as EXE from suiv.TVIMREC where IMDEVNT NE .	
UNION
select  anumpat, nbvisit, "TVNIM - RECIDIVE" as EVENT "Evenement", 	   case when PRDEVNT NE . then PRDEVNT else DNVRES end as DATEE "Date" format=DDMMYY10., " " as comment, . as TTIGTTOT,  "" as EXE from suiv.TVNIMRECI where PRDEVNT NE . or DNVRES NE .	
 UNION
select  anumpat, 99 as nbvisit, "Sortie d'étude" as EVENT "Evenement", 	   DSORTETU as DATEE "Date" format=DDMMYY10., " " as comment, . as TTIGTTOT,  "" as EXE from suiv.planing	where DSORTETU NE .
  UNION
select  anumpat, 99 as nbvisit, "PERDUE DE VUE" as EVENT "Evenement", 	   PDVDATE as DATEE "Date" format=DDMMYY10., " " as comment, . as TTIGTTOT,  "" as EXE from suiv.planing	where PDVDATE NE .
  UNION
select  anumpat, 99 as nbvisit, "DECES" as EVENT "Evenement", 	   NSDDC as DATEE "Date" format=DDMMYY10., " " as comment, . as TTIGTTOT,  "" as EXE from suiv.planing	where NSDDC NE .

ORDER BY   anumpat,nbvisit, DATEE , EVENT;
;quit; 


%suppr(Cl_rtuv);


/*
ods excel file="\\nas-01\SBE_ETUDES\COBLANCE\11-DataBase\Nouvelle methode de travail\out\chir.xlsx";;

proc report data=stu.List_chir ;
run;

ods excel close;

*/
