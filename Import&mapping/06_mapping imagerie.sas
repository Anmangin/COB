/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables cliniques

 Ce fichier permet de créer les tables mappées concernant le suivi clinique des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir été lancé;

*           - ---- -- - - - MACROS  - - - - - - ;

%macro suppr(table);
proc sql;
DROP TABLE &table.;
quit;
%MEND;

* Macro renommant les valeurs de la variable ESSAI;
/*
 %macro ETUDE(table,etude);
	data &table;
	LENGTH ESSAI $10.;
	set &table;
	ESSAI= "&etude.";
	run;
%mend;
*/

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


* ----------------- Fibroscopie -------------------;
data STU.CL_Fibroscopie;
set incl.Bilsante_nbexam;
/*CRFTITLE="Bilan santé";*/
where DFIBAV NE .;  /* PGU : à décommenter ? */
rename DFIBAV=DIMAG;
run;


* ----------------- Imagerie -------------------;

* Créer une table contenant les imageries non programmées de l'inclusion;

data CL_IMAGERIE_AU_Temp1;
set incl.Bilext_autre_imag1;
CRFTITLE="Bilan d'extension";
format ACTIV10 1.;
where ACTIV10= 1;
format EXAM IMAGSUIV.;
EXAM = 1;
res="Non demandé";
drop   ACTIV10 ;
run;


%DELETEformat(SUIV,Suivitvim_autr_1,AURESEXAM,AURESEXAMSUIV);

* Imageries non programmées des patients TVIM durant le suivi;
data CL_IMAGERIE_AU_Temp2;
set Suivitvim_autr_1;
format AUTPEXAM $100.;
ESSAI = "COBSUIVI";
rename AUTPEXAM=TPEXAM
AUTPEXAMP=TPEXAMP
AUDEXAM=DATEXAM
AURESEXAM=res;
format EXAM IMAGSUIV.;
EXAM = 1;
where ACTIV21=1;
drop    ACTIV21 ;
run;

* Imageries non programmées des patients TVNIM durant le suivi;
data CL_IMAGERIE_AU_Temp3;
set suiv.Suivitvnim_autr1;
ESSAI = "COBSUIVI";
rename IMAG=exam
TPIMAG=TPEXAM
TPIMAGP=TPEXAMP
DIMAG=DATEXAM;
res="Non demandé";
where TPIMAG NE "" and IMAG =1;
run;

* Fusionne les 3 tables d'imageries non programmées;
data STU.CL_IMAGERIE_AU;
retain &ordervar_g NUMPAGE EXAM TPEXAM TPEXAMP res DATEXAM;
length TPEXAMP $100.;
length TPEXAM $100.;
length ESSAI $10.;
length RES $100.;
set CL_IMAGERIE_AU_Temp1 CL_IMAGERIE_AU_Temp2 CL_IMAGERIE_AU_Temp3;
label EXAM="Examen réalisé"
tpexam="type d'examen"
tpexamp="autre type d'examen"
res="résultat"
DATEXAM="date éxamen";
run;
proc sort data=STU.CL_IMAGERIE_AU; by anumpat NBVISIT;run;

* Réordonne la table obtenue et supprime les tables intermédiaires;

%suppr(CL_IMAGERIE_AU_Temp1);
%suppr(CL_IMAGERIE_AU_Temp2);%suppr(CL_IMAGERIE_AU_Temp3);
%suppr(Suivitvim_autr_1);



proc contents data=Cl_imagerie_4 noprint out=aatest;run;
proc sort;by varnum;run;




* Table des imageries Echographie abdominale;
data CL_IMAGERIE_1;

retain &ordervar IMAG ECHOAV DECHOAV resultV resultHA	ECHOAVDF IDECHOAV IDECHOAVC;
length IDECHOAV $500.;

set incl.BILSANTE;
format CRFTITLE $20.;
IMAG = " Echographie abdominale";
resultV=put(VSECHOAV,VSECHOAVINCL.);
resultHA=put(HTECHOAV,HTECHOAVINCL.);
rename ECHOAV=IMFAIT DECHOAV=DIMAG ECHOAVDF=AUANO IDECHOAV=AUANOP IDECHOAVC=code;
label ECHOAV="imagerie faite" DECHOAV="date imagerie" VSECHOAV="resultat Vessie" HTECHOAV="resultat haute appareil" ECHOAVDF="autre anomalie" IDECHOAV="Anomalie precision" IDECHOAVC="code";
keep &&ordervar IMAG ECHOAV DECHOAV resultV resultHA ECHOAVDF IDECHOAV IDECHOAVC;
where anumpat NE "" and ECHOAV ne .;
run;


* Table des imageries TDM abdomino-pelvienne;
data CL_IMAGERIE_2;
retain &ordervar;

length IDBTDMDF $500.;
set incl.Bilext;
NUMVISIT = 0;
format CRFTITLE $20.;
IMAG = "TDM abdomino-pelvienne";
resultV=put(BTDMHAP,VSECHOAVINCL.);
resultHA=put(BTDMHAPU,HTECHOAVINCL.);
Adenop=put(BTDMADEN,BTDMADENINCL.);
label adenop="Adenopathie > 1cm";
rename TDMABD=IMFAIT BTDMD=DIMAG BTDMDF=AUANO IDBTDMDF=AUANOP IDBTDMDFC=code;
label TDMABD="imagerie faite" BTDMD = "date imagerie" BTDMHAP="resultat Vessie" BTDMHAPU="resultat haute appareil" 
BTDMDF="autre anomalie" IDBTDMDF="Anomalie precision" IDBTDMDFC="code";
keep &ordervar IMAG TDMABD BTDMD resultV resultHA	
Adenop BTDMILIO BTDMIPR	BTDMING	BTDMAORT BTDMDF	IDBTDMDF IDBTDMDFC;
where anumpat NE "" and TDMABD ne .;
run;

* Table des imageries TDM abdomino-pelvienne (2ème partie);
data CL_IMAGERIE_3;
retain &ordervar;
set incl.Bilext;
format CRFTITLE $20.;
IMAG = "TDM abdomino-pelvienne";
resultT=put(BTDMTRES,BTDMTRESINCL.);
rename TDMTHOR=IMFAIT  BTDMTD=DIMAG   BTDMTLES=Lesion   BTDMTLESC=Codelesion;
label TDMTHOR="imagerie faite" BTDMD="date imagerie" BTDMTLES="Lesion" BTDMTLESC="Code lesion";
keep ESSAI anumpat NUMVISIT visitname visitcyclenumber crfpagecyclenumber crftitle IMAG TDMTHOR BTDMTD resultT BTDMTLES BTDMTLES BTDMTLESC;
where anumpat NE "" and TDMABD ne .;
run;

* Table des imageries IRM abdomino-pelvienne;
data CL_IMAGERIE_4;

retain &ordervar IMAG IRMABD  BIRMD TDMTHOR resultV resultHA resultU BTDMTD BTDMTLES BTDMTLES BTDMTLESC;
length IDBIRMDF $500.;
set incl.Bilext;
IMAG = "IRM abdomino pelvienne";
resultV=put(BIRMVES,BIRMVESINCL.);
resultHA=put(BIRMHAP,BIRMHAPINCL.);
resultU=put(BIRMHAPU,BIRMHAPUINCL.);
Adenop=put(BIRMADEN,BIRMADENincl.);
rename IRMABD=IMFAIT BIRMD=DIMAG BIRMILIO=BTDMILIO BIRMIPR=BTDMIPR BIRMING=BTDMING BIRMAORT=BTDMAORT BIRMDF = AUANO IDBIRMDF=AUANOP IDBIRMDFC=Code;
label IRMABD="imagerie faite" BIRMD="date imagerie" BTDMHAP="resultat Vessie" BTDMHAPU="resultat haut appareil" resultU="resultat haut appareil Urothelial" 
BTDMDF="autre anomalie" IDBTDMDF="Anomalie precision" IDBTDMDFC="code";
keep &ordervar IMAG BIRMD IRMABD BIRMD resultV resultHA resultU 
Adenop BIRMILIO	BIRMIPR	BIRMING	BIRMAORT BIRMDF	IDBIRMDF IDBIRMDFC ;
where anumpat NE "" and IRMABD ne .;
run;

* Ajout de suivi TVNIM TDM abdominale à la table globale d'imagerie;
data CL_IMAGERIE_5;
retain &ordervar;
LENGTH TDNSPRE $500.;
set suiv.suivitvnim;
IMAG="TDM abdominale";
resultLC = put(TDNRESLR,TDNRESLRSUIV.);
resultU=put(TDNSRESHAU,TDNSRESHAUSUIV.);
resultHA=put(TDNSRESHA,TDNSRESHASUIV.);
Adenop=put(TDNSADENO,TDNSADENOSUIV.);
rename NBTDMABD = NBIMAG TDNSTDMABD=IMFAIT TDNSDTDM=DIMAG TDNSANOM=AUANO TDNSPRE=AUANOP TDNSPREC=code;
label TDMABDMULT = "DTM MULTIPLE";
if TDNSLOCA=1 then BTDMIPR=1;
if TDNSLOCA=2 then BTDMING=1;
if TDNSLOCA=6 then BTDMAORT=1;

run;
data CL_IMAGERIE_5;set CL_IMAGERIE_5;keep &ordervar IMAG	IMFAIT	DIMAG
/*resultV*/
resultLC
resultU
resultHA	resultU	AUANOP	/*BTDMILIO*/	BTDMIPR	BTDMING	BTDMAORT	AUANO	Code	Adenop
TDMABDMULT

;run;

* Ajout de suivi TVNIM IRM Abdomino pelvienne à la table globale d'imagerie;
data CL_IMAGERIE_6;
retain &ordervar;
length IRMNSPREP $500.;
set suiv.suivitvnim;
IMAG="IRM Abdomino pelvienne";
resultLC = put(IRMNRESLR,IRMNRESLRSUIV.);
resultU=put(IRMNSRESHAU,TDNSRESHAUSUIV.);
resultHA=put(IRMNSRESHA,TDNSRESHASUIV.);
Adenop=put(IRMNSADENO,IRMNSADENOSUIV.);
rename NSIRM=IMFAIT IRMNSDTDM=DIMAG NBIRM= NBIMAG IRMNSANOM=AUANO IRMNSPREP=AUANOP IRMNSPREC=code;
if IRMNSLOCA=1 then BTDMIPR=1;
if IRMNSLOCA=2 then BTDMING=1;
if IRMNSLOCA=6 then BTDMAORT=1;
keep &ordervar IMAG resultLC resultU resultHA CCBRA NSIRM NBIRM IRMNSDTDM Adenop IRMNSANOM IRMNSPREP IRMNSPREC;
where NSIRM NE .;
run;


* Ajout de suivi TVNIM IRM Abdomino pelvienne (2ème partie) à la table globale d'imagerie;
data CL_IMAGERIE_7;
retain &ordervar;
format resultLC $ 20.;
length resultLC $ 20.; 
set suiv.suivitvnim;
IMAG="IRM Abdomino pelvienne";
resultLC = put(IRMNRESLR,IRMNRESLRSUIV.);
resultU=put(IRMNSRESHAU,TDNSRESHAUSUIV.);
resultHA=put(IRMNSRESHA,TDNSRESHASUIV.);
Adenop=put(IRMNSADENO,IRMNSADENOSUIV.);
rename NSIRM=IMFAIT IRMNSDTDM=DIMAG NBIRM= NBIMAG IRMNSANOM=AUANO IRMNSPREP=AUANOP IRMNSPREC=code;
if IRMNSLOCA=1 then BTDMIPR=1;
if IRMNSLOCA=2 then BTDMING=1;
if IRMNSLOCA=6 then BTDMAORT=1;
keep &ordervar IMAG resultLC resultU resultHA CCBRA		
NSIRM NBIRM	IRMNSDTDM Adenop IRMNSANOM IRMNSPREP IRMNSPREC;
where NSIRM NE .;
run;


* Ajout de suivi TVIM TDM abdominale à la table globale d'imagerie;
data CL_IMAGERIE_8;
retain &ordervar;
format resultLC $ 20.;
length resultLC $ 20.; 
length IDBTDMDF $500.;
set suiv.suivitvim;
format ESSAI $10.;
ESSAI="COBSUIVI";
CRFTITLE="SUIVITVIM";
IMAG="TDM abdominale";
resultLC = put(BTDMLOC,BTDMLOCSUIV.);
resultU=put(BTDMHAPU,BTDMHAPUSUIV.);
adenop=put(BTDMADEN,BTDMADENsuiv.);
rename TDMABD=IMFAIT BTDMD=DIMAG BTDMDF=AUANO IDBTDMDF=AUANOP IDBTDMDFC=code NBTDMABD=nbimag;
keep &ordervar crftitle CRFPAGESTATUS IMAG resultLC resultU visitname	CCBRA
NBTDMABD TDMABD BTDMD adenop BTDMILIO BTDMIPR BTDMING BTDMAORT BTDMDF IDBTDMDF IDBTDMDFC;
run;


* Ajout de suivi TVIM IRM à la table globale d'imagerie;
data CL_IMAGERIE_9;
retain &ordervar;
format resultLC $ 20.;
length resultLC $ 20.; 
length IDBIRMDF $500.;
set suiv.suivitvim;
ESSAI="COBSUIVI";
CRFTITLE="SUIVITVIM";
IMAG="IRM";
resultLC = put(BIRMLOC,BIRMLOCSUIV.);
resultU=put(BIRMHAPU,BIRMHAPUSUIV.);
adenop=put(BIRMADEN,BIRMADENsuiv.);
rename IRM=IMFAIT BIRMD=DIMAG BIRMDF=AUANO IDBIRMDF=AUANOP IDBIRMDFC=code NBIRM=nbimag
BIRMILIO=BTDMILIO BIRMIPR=BTDMIPR BIRMING=BTDMING BIRMAORT=BTDMAORT;
keep &ordervar	 BIRMD resultLC resultU IRM BIRMD BIRMDF IDBIRMDF IDBIRMDFC BIRMILIO BIRMIPR BIRMING BIRMAORT adenop NBIRM;
run;


* Fusion des 4 tables et suppression des intermédiaires;
data STU.CL_IMAGERIE;
retain &ordervar IMAG IMFAIT DIMAG NBIMAG TDMABDMULT resultV resultLC resultHA resultU resultT;
set CL_IMAGERIE_1 CL_IMAGERIE_2 CL_IMAGERIE_3 CL_IMAGERIE_4 CL_IMAGERIE_5 CL_IMAGERIE_6 CL_IMAGERIE_7 CL_IMAGERIE_8 CL_IMAGERIE_9;
label NBIMAG = "nombre d'imagerie"
ResultLC = "Resultat Loco-régional"
ResultV= "Resultat Vessie"
ResultT = "Resultat Thorax"
ResultHA = "Resulat Haut Appareil"
Imag = "type d'imagerie"
visitname = "visitname"
FIBRONEO="Fibroscopie sur néovessie";
where IMFAIT=1;
drop VISITNAME visitcyclenumber VISITNAME;
run;


%suppr(CL_IMAGERIE_1);
%suppr(CL_IMAGERIE_2);
%suppr(CL_IMAGERIE_3);
%suppr(CL_IMAGERIE_4);
%suppr(CL_IMAGERIE_5);
%suppr(CL_IMAGERIE_6);
%suppr(CL_IMAGERIE_7);
%suppr(CL_IMAGERIE_8);
%suppr(CL_IMAGERIE_9);


%placement(STU.CL_IMAGERIE,AUANOP,13);


data CL_IMAGERIE;
set stu.CL_IMAGERIE_AU;
rename TPEXAM=IMAG TPEXAMP=IMAGP EXAM=IMFAIT DATEXAM=DIMAG;
run;

/*PGU: attention avec les tailles de formats, il semble y avoir un problème;*/
data temp;
format IMAG $20.;;
format  ANUMPAT $5.;
length IMAG $20.;;
length  ANUMPAT $5.;
run;

data stu.CL_IMAGERIE;
set stu.CL_IMAGERIE temp;
if IMFAIT=1;
run;
proc sort data=STU.CL_IMAGERIE;by anumpat nbvisit;run;



%suppr(temp);
%suppr(stu.CL_IMAGERIE_AU);






