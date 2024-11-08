/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables d'analyse biologiques

 Ce fichier permet de cr�er les tables mapp�es concernant les analyses biologiques des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir �t� lanc�;

* Table interm�diaire contenant les examens de cytologie du diagnostic � l'inclusion;
data STU.CL_EX1;
retain &ordervar EXAMEN;
LENGTH CRFTITLE visitname $20.;
*set STU.CL_PARAM_CLIN;
set incl.bilsante;
EXAMEN = "Cytologie urinaire lors du diagnostic";
ResultatC = put(RSCYTOAV,RSCYTOAVINCL.);
rename CYTOAV=EXAMFAIT NBCYTOAV=NBEXAM DRCYTOAV=Dexam;
label CYTOAV="Examen fait" NBCYTOAV="Nombre d'examen fait dans l'ann�e";
keep &ordervar EXAMEN CYTOAV	NBCYTOAV	DRCYTOAV ResultatC;
run;

* Table interm�diaire contenant les examens cytobacteriologique de l'inclusion;
data STU.CL_EX2;
retain &ordervar EXAMEN;
LENGTH CRFTITLE visitname $20.;
set incl.bilsante;
EXAMEN = "Examen cytobacteriologique des urines";
rename BACTAV=EXAMFAIT NBBACTAV=NBEXAM DRBACTAV=Dexam;
REsultatC="Non r�colt�";
label BACTAV="Examen fait" NBBACTAV="Nombre d'examen fait dans l'ann�e";
CRFTITLE='BILSANTE';
visitname='inclusion';
keep &ordervar EXAMEN  BACTAV NBBACTAV DRBACTAV  RESULTATC;
run;

* Table interm�diaire contenant les examens de cr�atin�mie � l'inclusion;
data STU.CL_EX3;
retain &ordervar EXAMEN;
LENGTH CRFTITLE visitname $20.;
set incl.descpat;
EXAMEN = "Cr�atin�mie � l'inclusion";
rename creat=REsultatN;
label creat="ResultatN";
if creat NE . and creat NE 888 then EXAMFAIT=1;
keep &ordervar EXAMEN  creat EXAMFAIT;

run;

* Table interm�diaire contenant les examens de cr�atin�mie lors du diagnostique;
data STU.CL_EX4;
retain  &ordervar EXAMEN;
LENGTH CRFTITLE visitname $20.;
set incl.bilsante;
EXAMEN = "Cr�atin�mie Lors du diagnostique";
rename CREATAV=EXAMFAIT
VCREATAV=REsultatN;
keep  &ordervar EXAMEN VCREATAV CREATAV;
run;

* Table interm�diaire contenant les examens de cr�atin�mie pendant le suivi TVIM;
data STU.CL_EX5;
retain &ordervar EXAMEN;
LENGTH CRFTITLE visitname $20.;
set suiv.Suivitvim;
EXAMEN = "Cr�atin�mie";
rename NSCREAT=EXAMFAIT
NSCREATRES=REsultatN;
keep &ordervar EXAMEN  NSCREAT NSCREATRES;
run;

* Table interm�diaire contenant les examens de cr�atin�mie pendant le suivi TVNIM;
data STU.CL_EX6;
retain &ordervar EXAMEN;
set suiv.Suivitvnim;
EXAMEN = "Cr�atin�mie";
rename NSCREAT=EXAMFAIT
NSCREATRES=REsultatN;
keep &ordervar  NSCREAT NSCREATRES;
run;

* Table interm�diaire contenant les examens cytobact�riologiquess pendant le suivi TVIM;
data STU.CL_EX7;
retain &ordervar EXAMEN;
set suiv.Suivitvim;;
EXAMEN = "Examen cytobacteriologique des urines";
rename NSECBU=EXAMFAIT NSECBUNB=NBEXAM;
REsultatC="Non r�colt�";
label NSECBU="Examen fait" NSECBUNB="Nombre d'examen fait dans l'ann�e";

keep &ordervar EXAMEN  RESULTATC NSECBU NSECBUNB;
run;

* Table interm�diaire contenant les examens cytobact�riologiquess pendant le suivi TVNIM;
data STU.CL_EX8;
retain &ordervar EXAMEN;
set suiv.Suivitvnim;
EXAMEN = "Examen cytobacteriologique des urines";
rename NSECBU=EXAMFAIT;
REsultatC="Non r�colt�";
label NSECBU="Examen fait";
keep &ordervar EXAMEN  RESULTATC NSECBU;
run;

* Table interm�diaire contenant les examens de cytologie du diagnostic au suivi TVNIM;
data STU.CL_EX9;
retain &ordervar EXAMEN;
set suiv.Suivitvnim;
EXAMEN = "Cytologie urinaire";
ResultatC = put(NSCYTORES,RSCYTOAVINCL.);
rename NSCYTO=EXAMFAIT;
label NSCYTO="Examen fait" ;
keep  &ordervar EXAMEN NSCYTO	 ResultatC;
run;

* Table interm�diaire contenant les examens de cytologie du diagnostic au suivi TVIM;
data STU.CL_EX10;
retain &ordervar EXAMEN;
set suiv.Suivitvim;
EXAMEN = "Cytologie urinaire";
ResultatC = put(NSCYTORES,RSCYTOAVINCL.);
rename NSCYTO=EXAMFAIT;
label NSCYTO="Examen fait" ;
keep  &ordervar EXAMEN NSCYTO	 ResultatC;
run;

* Fusionne toutes les tables interm�diaires en une table CL_BIOLOGIE; 
data  STU.CL_BIOLOGIE;
set  STU.CL_EX1 STU.CL_EX2 STU.CL_EX3 STU.CL_EX4 STU.CL_EX5 STU.CL_EX6 STU.CL_EX7 STU.CL_EX8 STU.CL_EX9 STU.CL_EX10;
run;

* Supprime les tables interm�diaires;
%suppr(STU.CL_EX1);
%suppr(STU.CL_EX2);
%suppr(STU.CL_EX3);
%suppr(STU.CL_EX4);
%suppr(STU.CL_EX5);
%suppr(STU.CL_EX6);
%suppr(STU.CL_EX7);
%suppr(STU.CL_EX8);
%suppr(STU.CL_EX9);
%suppr(STU.CL_EX10);

proc sort data=STU.CL_BIOLOGIE;by anumpat nbvisit EXAMEN;run;

* Retire tous les cas o� les examens n'ont pas �t� fait;
 data STU.CL_BIOLOGIE;
 set STU.CL_BIOLOGIE;
 where EXAMFAIT=1;
 run;
