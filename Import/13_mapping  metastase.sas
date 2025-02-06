/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables d'analyse biologiques

 Ce fichier permet de créer les tables mappées concernant les analyses biologiques des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas 
		   et mapping anapath.sas doivent avoir été lancé;


* Macro;
%macro placement(table,var,num);
proc contents data=&table out=temp noprint;run;
data temp;set temp;
if VARNUM<= &num then VARNUM=VARNUM+1;
if UPCASE(NAME)=UPCASE("&var") then VARNUM=&num;run;
proc sort data=temp ;by VARNUM;run;
 %let retain =retain ;
proc sql noprint; select count(*) into:nbvar from temp;quit;
%do i=1 %to &nbvar;
data temp;set temp ; if _N_=&i then call symput("NAME",NAME);run;
%let retain= &retain &NAME ;
%end;
data &table;
&retain;set &table;
run;
%suppr(temp);
%MEND;


* Format des tables;
proc format lib=stu;
 value sexe 
	  1="Male"
      2="Female";

 value newt
1="Tx"
2="Tis"
3="Ta"
4="Ta + cis"
5="T1"
6="T1 + cis";

value curage
1 = "Local"
2 = "Etendu"
3 = "Supra Etendu"
-1 = "NA";

value grad
1 = "Not Available"
2 = "Low"
3 = "High";

 value Etude 
	  1="None or primary school"
      2-3="Technical/professional school"
       4= "Secondary school"
      5-6= "University degree"
      7-9= "Not specified";

 value sipro 
	  1="Employed"
      2="Employed"
	  8="Employed"
      3-4="Retired/ pre retired"
	  5-6="Unemployed"
      7= "Disabled/dependent"
      9= "Disabled/dependent";

 value Marie
	  1="Single"
      2-3="Married/Consensual union"
	  4-6="Divorced/Separated/Widowed"
    ;

 value Reve
	    1="< 600€"
	   21="< 600€"
       2 ="600€ to < 1100€"
       3 ="600€ to < 1100€"
       4 ="600€ to < 1100€"
      22="600€ to < 1100€"
      23="600€ to < 1100€"
      24="600€ to < 1100€"

      5 ="1100€ to < 1800€"
	  6 ="1100€ to < 1800€"
	  7 ="1100€ to < 1800€"
	 25 ="1100€ to < 1800€"
	 26 ="1100€ to < 1800€"
	 27="1100€ to < 1800€"

	  8 ="1800€ to < 2500€"
      9 ="1800€ to < 2500€"
	  28 ="1800€ to < 2500€"
	  29="1800€ to < 2500€"

      10 ="2500€ to < 3500€"
      11 ="2500€ to < 3500€"
	  30 ="2500€ to < 3500€"
	  31="2500€ to < 3500€"

      12 ="3500€ to < 4500€"
	  32 ="3500€ to < 4500€"
	  13 = "> 4500€"
      33 = "> 4500€";

  value secu
	  1="General scheme"
      2="MSA(Agricultural workers scheme)"
      3="RSI(self-employed workers scheme)"
	  4="EDF-GDF"
      5="Another foreign scheme"
      6="Others"
	  7="Unknown";

  value Fumeur
	  1="Current smoker(At least 1 type of cigarette per day for a period >= 6 months)"
      2="Never smoked" 
      3="Ex smoker" 
	  4="Missing" ;
	 
value FamilyCancer
	0="No Family History"
	1="Parents only"
	2="Siblings only"
	3="Children only"
	4= "Siblings and Parents"
	5= "Children and Parents"
	6 = "Children and Siblings"
	7= "Children, Parents and Siblings";

run;

* Creation table d'identification;
proc sql noprint;
create table Id_inc as select   b.anumpat,  DEXCL,b.DINCL , TPBRA as BRA_INCL format TPBRAincl.,d.CRITINC,NSDDC from incl.Idenbra b 
left join incl.Exlusion c on b.anumpat=c.anumpat 
left join incl.descpat d on b.anumpat=d.anumpat
left join suiv.planing e on b.anumpat=e.anumpat
ORDER BY b.anumpat;
quit; 

* Necessite d'avoir lancer mapping anapath.sas;
* PG : PK on modifie 01-093 ici et pas dans anapath. A revoir;

data tnm;set stu.AN_TNM_INCL ; keep anumpat MF AJCC;run;


* Merge les 2 tables;
proc sort data=tnm; by anumpat;run;
DATA Meta_final;
MERGE tnm Id_inc(IN = incl);
BY anumpat;
IF incl;
IF AJCC = "IV" THEN metaf = 1;
ELSE metaf = 0;
RUN;
data Cl_imagerie;set stu.Cl_imagerie;run;
* Fusionne Cl_imagerie avec la table d'identification;
proc sort data=Cl_imagerie ; by anumpat;run;
proc sort data=Id_inc ; by anumpat;run;

DATA Imagerie;
MERGE Cl_imagerie Id_inc(IN = incl);
BY anumpat;
if ESSAI="COBINC" and imfait = 1  and (resultT NE "" or  adenop NE "") and ( resultT = "Lesion tumorale d'origine indeterminee" or (adenop not in("","Non",".","Non","          ."))) ;
/*( resultT = "Lesion tumorale d'origine indeterminee" or (strip(adenop) not in("Non",".","Non","          .")) ) ;*/
keep anumpat  imfait resultT Adenop ;
RUN;

proc sql noprint; create table meta_image as select distinct anumpat, 1 as  meta_imag from Imagerie;quit;
DATA Meta_descpat;
SET incl.Descpat;
KEEP anumpat metast PATMETA D_META META_LOC;
IF metast = 1 or patmeta = 1;
RUN;

PROC SORT DATA = Meta_descpat; BY anumpat; RUN;

DATA Meta_final;
MERGE Meta_descpat(IN = desc) Meta_final(IN = incl) meta_image (in=image);
BY anumpat;
IF incl;
IF desc   THEN metaf = 1;
/*drop meta_imag;*/
RUN;

* Recupere le statut de chimio du patient et l'ajoute a meta finale;
data Cl_chimiotherapie ;
set stu.Cl_chimio_trt;
run;

DATA Chimio;
MERGE Cl_chimiotherapie Id_inc(IN = incl);
BY anumpat;
IF incl;
IF NBVISIT=0 and TPTR NE "CHIMIO LIGNE 2";
RUN;
DATA chimerge;
SET Chimio;
KEEP imchm imchmin anumpat;
RUN;

PROC SORT DATA = chimerge; BY anumpat; RUN;

DATA Meta_final;
MERGE chimerge(IN = desc) Meta_final(IN = incl);
BY anumpat;
IF not desc THEN imchm = 2;
IF imchmin = 6 THEN metaf = 1;
IF imchmin = 6 then METACHIM=1;

RUN;
proc sort nodupkey; by anumpat;run;

proc format;
value meta_chim
-1="Oui, meta non précisé"
1="Oui, ligne meta"
2="Non";
run;


data anameta;
set stu.An_anameta;
if v=1 and NUMANAP ne "P15.7583";
keep anumpat MTDPREL MTORG MTAUORG;
run;
proc sort nodupkey;by anumpat;run;
proc sql noprint; create table Meta_final2 as select * from Meta_final a left join anameta b on a.anumpat=b.anumpat;quit;
data Meta_final;
retain  anumpat DINCL bra_incl CRITINC NSDDC META_chm METAST PATMETA D_META META_LOC MTDPREL MTORG MTAUORG  meta_imag  AJCC MF IMCHM metaf;
set Meta_final2;
format META_chm meta_chim.;
label META_chm="Ligne metastastique";
if METACHIM=1 then META_chm=1;
else if IMCHM=1  then META_chm=-1;
else if IMCHM=2 then META_chm=2;
label bra_incl = "Bras à l'inclusion "
METAST= "metastase symptomatique ( inclusion)"
PATMETA=" patient metastatique déclaré dans le CRF à l'inclusion"
meta_imag="Patient metastatique trouvé via l'imagerie"
metaf="Patient metastatique Final";
if metaf=0 then metaf=2;
format metaf meta_imag PATMETAINCL.;
drop IMCHM METACHIM IMCHMIN DEXCL;
run;
data stu.PATMETA;
set  Meta_final;
run;
%suppr(tnm);%suppr(meta_image);%suppr(print_meta);%suppr(meta_descpat);%suppr(chimio); %suppr(Cl_chimiotherapie);%suppr(meta_final);%suppr(Cl_imagerie);
%suppr(Chimerge);%suppr(imagerie);
