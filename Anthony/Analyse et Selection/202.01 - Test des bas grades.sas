
/*
%macro get_table(table);
proc contents data=stu.&table noprint out=atest;run;
 proc sort;by VARNUM;
 data atest;set atest;keep NAME TYPE LABEL FORMAT; run;
 %mend;


%get_table(VARIANT); 


proc sql noprint; create table prog as 
select distinct b.anumpat,critinc, "Oui" as TVNIMprog
from stu.Cl_tvnim_suiv a
left join stu.resume b on a.anumpat=b.anumpat


where (PRDEVNT NE . or PRPROG=1 or PRGPELV=1 or PRGILIAC=1 or PRLAORT=1 or PROGMET=1 or PRGANGL=1 or PRFOIE=1 or PRPOUM=1 or PROGOS=1 or PRAUTRS=1) and (CRITINC=1 or CRITINC=2)

;quit;

proc sql noprint; create table atest as select a.anumpat,metaf,a.bra_incl, critinc
from stu.resume a left join stu.patmeta b on a.anumpat=b.anumpat
where  (critinc=1 or critinc=2) and metaf=2 and a.BRA_INCL=1;
quit;

*/

data patmeta;
set stu.Patmeta;
if anumpat in ('01-020', '01-190', '01-252', '01-329', '01-346', '01-382', '01-386', '01-401', '01-451', '01-471', '01-473', '01-492', '01-500', '01-505', '01-509', '01-554', '01-564', '01-579', '05-043', '05-060', '08-081', '12-152', '13-099', '13-114', '13-216', '16-090', '16-143', '16-147') then BMS=1;
else BMS=2;
format bms PATMETAINCL.;
run;


data diff;
set patmeta;
if BMS=2 and metaf=1;
run;


proc sql noprint; create table diff as select a.*,META_LOC,TF,NF,MF,grade04,
case 
when MF>0 or a.PATMETA=1 or TF>13 then "Confirmé" 
when grade04<3 or TF<4 then "Ta - Bas grade -> ERREUR POSSIBLE"
when NF>0 and meta_imag=1 then "N+ et imagerie positive"
when meta_imag=1 then "Confirmé juste par de l'imagerie"
else "N.A"
end

as COMMENT
from patmeta a
left join stu.an_tnm_incl b on a.anumpat=b.anumpat
left join incl.Descpat c on a.anumpat=c.anumpat
where BMS=2 and metaf=1;quit;






proc freq data=diff;
table metaf*BMS / norow nocol nopercent;
table COMMENT/list;
run;


proc freq data=diff;
table TF/list;
where comment="Ta - Bas grade -> ERREUR POSSIBLE";
run;



data check;
set diff;
if  comment="Ta - Bas grade -> ERREUR POSSIBLE" or comment="Confirmé juste par de l'imagerie";
run;

proc print data=check label noobs;run;
