/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables cliniques

 Ce fichier permet de créer les tables mappées concernant le suivi clinique des patients
V1 20/10/2020 -> Anthony M
V2 06/09/2023 -> Anthony M et Pierre G revu pour France Cohorte

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir été lancé;


*           - ---- -- - - - PARTIE INCLUSION  - - - - - - ;

* Créer une table intermédiaire à partir de la table de caractéristique des patients de l'inclusion;
data STU.CL_PARAM_CLIN_t;
retain &ordervar;
set incl.descpat;
label PSANGML ="Taux PSA"
DINCL="Date inclusion";
  if TART1 = 888 then tart1=.;
  drop  EUDRACTP3 EUDRACTP2 EUDRACTP1 EUDRACT  IDESSAI EUDRACTCAR ETCLIN PSA PSAUNIT PSAUNIT2 ;
run;

* Réordonne les tables à merger et élimine les possibles doublons;
Proc sort data=STU.CL_PARAM_CLIN_t nodupkey; by anumpat;run;
Proc sort data=INCL.BILSANTE nodupkey;by anumpat;run;
data INCL.bilsante; set INCL.BILSANTE; ;run;
proc sort data=incl.bilext nodupkey;by anumpat;run;
data INCL.bilext; set INCL.bilext; ;run;

* Créer la table mergée contenant toutes les caractéristiques cliniques du patient à l'inclusion;
data STU.CL_PARAM_CLIN;
retain &ordervar;
merge STU.CL_PARAM_CLIN_t INCL.bilsante INCL.bilext ;
by anumpat;
run;

data STU.CL_PARAM_CLIN;
retain &ordervar;
set STU.CL_PARAM_CLIN;
ESSAI="COBINC";
drop MONAIS	ANNAIS DINCL FORMU CCCENT ASEXE	AAGE CENT IDPAT	IDCOB DDONAVA BIMAGT BIMAGN	BIMAGM;
run;

* Supprime la table intermédiaire;
%suppr(STU.CL_PARAM_CLIN_t);

* Créer une table contenant les caractéristiques des patients TVNIM à l'inclusion;
data STU.CL_TVNIM;
retain &ordervar;
set incl.econim;
drop FORMU CCCENT  ASEXE	AAGE IDCOB CENT IDPAT MONAIS ANNAIS  NIMCYSDB	NIMCYSFN NIMCYSIN NIMCYSV NIMCYSH NIMCYSCD 
NIMCYSGHM NIMCYSGDF NIMCYSCG NIMEXE NIMEXEP NIMURET NIMNEPH NIMTNEPH NIMEXTP NIMTEXTP NIMTEXTPP NIMEXTPR NIMDRV NIMDRVCT NIMNEO	
NIMNEODF NIMNEODFC NIMCYSOP	NIMCYSSG NIMCYSTF NIMCYSCL NIMCYSSI	NIMCYSCP NIMCYSCPT NIMCYSMD	NIMCYSMDP SNIMCYSCH	NIMCYSCH NIMCYSCHP;
run;


* Créer une table contenant les caractéristiques des patients TVIM à l'inclusion;
PROC SORT DATA=INCL.ECOIMOP;by anumpat;run;
data INCL.ECOIMOP; set INCL.ECOIMOP;run;
PROC SORT DATA=INCL.ECOIMTR;by anumpat;run;
data INCL.ECOIMTR; set INCL.ECOIMTR;run;

data STU.CL_TVIM;
retain &ordervar;
merge INCL.ECOIMOP INCL.ECOIMTR;
by anumpat;
drop CCCENT		DINCL ASEXE DDONTIM	AAGE IDCOB CENT	IDPAT MONAIS ANNAIS  CYS_ND_REAS IMCYSDBH IMCYSFNH	IMCYSIN	IMCYSH 
IMCYSCD	IMCYSV IMCYSGHM	IMCYSGDF IMCYSCG IMEXE IMEXEP IMURET IMNEPH	IMTNEPH	IMEXTP IMEXCU IMEXCUR IMEXUD IMEXUDR IMEXUG	IMEXUGR	
IMEXUR IMEXURR IMEXDF IMEXDFP IMEXDFR IMDRV	IMNEO IMNEODF IMNEODFC IMDRVCT IMDRVCTC IMCYSOP	IMCYSSG	IMCYSTF	IMCYSCL	IMCYSSI	IMCYSCP	
IMCYSCOMP IMCYSMD IMCYSMDP SNIMCYSCH IMCYSCH IMCYSCHP 	IMCHMIN	IMCHMDB	IMCHMFN	IMCHMNB	IMCHMGC	IMCHMVI	IMCHMMV	IMCHMDF	IMCHMTL	
IMCHMTLP IMCHMTT IMCHM2	IMCHM2DB IMCHM2FN IMCHM2QG IMCHM2GC	IMCHM2MV IMCHM2VQ IMCHM2VI IMCHM2MQ	IMCHM2DF IMCHM2TL IMCHM2TT;
run;



*  - ---- -- - - - PARTIE SUIVI  - - - - - - ;

data SUIVITVNIM;set suiv.SUIVITVNIM;run;
proc sql noprint; create table stu.CL_TVNIM_SUIV as select 

a.essai,	a.site,	a.anumpat,	a.NBVISIT,	a.bra,	a.vnf,	a.v,	a.vpla,	a.recidive,	a.crftitle,	a.crfpagecyclenumber,
a.CRFPAGESTATUS as CRFPAGESTATUS1 "TVNIM SUIVI" ,
Tvnimreci.CRFPAGESTATUS as CRFPAGESTATUS2 "TVNIM recidive" ,
Tvnimprog.CRFPAGESTATUS as CRFPAGESTATUS3 "TVNIM prog" ,
Tvnimprogcys.CRFPAGESTATUS as CRFPAGESTATUS4 "TVNIM cys" ,
Tvnimprogchim.CRFPAGESTATUS as CRFPAGESTATUS5 "TVNIM chim" ,

a.VESICONS,	a.NSCYTO,	a.NSCYTORES,	a.NSCREATRES,	a.NSCREAT,	a.NSECBU,	a.FIBRONEO,	a.NSFIBRO,	a.NSDFIBRO,	a.NSANESGEN,	a.NSBIOPS,	a.NSASPEN,	a.TDNSTDMABD,	a.TDMABDMULT,	a.NBTDMABD,	a.TDNSDTDM,	a.TDNRESLR,	a.TDNSRESHA,	a.TDNSRESHAU,	a.TDNSADENO,	a.TDNSLOCA,	a.TDNSANOM,	a.TDNSPRE,	a.TDNSPREC,	a.NSIRM,	a.MULTIRM,	a.NBIRM,	a.IRMNSDTDM,	a.IRMNRESLR,	a.IRMNSRESHA,	a.IRMNSRESHAU,	a.IRMNSADENO,	a.IRMNSLOCA,	a.IRMNSANOM,	a.IRMNSPREP,	a.IRMNSPREC,	a.AUTREIMAG,	a.BIMAGT,	a.BIMAGN,	a.BIMAGM,	a.SANG,	a.MARSANG,	a.MARSANGC,	a.URINE,	a.MARURI,	a.MARURIC,	a.TUMEUR,	a.MARTUME,	a.MARTUMEC

,b.DESAC as desacB,	b.PRDEVNT as BPRDEVNT,	DNVRES,	NVUSCOP,nvcys,	b.RECINTR,	b.RECIVUS,	b.RECIURE,	b.NF1,	b.NVBCG,	b.NVBCGDB,	b.NVBCGFN,	b.NVBCGPRT,	b.NVBCGPRTP,	b.NVBCGSVI,	b.NVBCGSVIP,	b.NVAE,	b.NVDAEBD,	b.NVDAEFN,	b.NVAEINS,	b.NVAESVI,	b.NVAEsVIP,	b.NVAUTE,	b.NVAUTENOM,	b.NVAUTENB,

c.DESAC,	c.PRDEVNT,	c.PRPROG,	c.PRGPELV,	c.PRGILIAC,	c.PRLAORT,	c.PROGMET,	c.PRGANGL,	c.PRFOIE,	c.PRPOUM,	c.PROGOS,	c.PRAUTRS,	c.PRAUTRSP,	c.PRAUTRE,	c.PRAUTREP,	c.PRTRAITE,	c.PRRTUV,	c.PRHEX,	c.PRNBI
,d.IMCYS,
e.IMCHM,e.IMCHM2,e.IMRDP,
IMRDPIN,
IMRDPDB,
IMRDPNB,
IMRDPDS,
IMRDPCHP,
IMRDPDF,
IMRDPDFP,
IMRDPTL,
IMRDPEFS
,e.IMTTDF,
e.IMTTDFP

from SUIVITVNIM a
FULL join suiv.Tvnimreci b on a.anumpat= b.anumpat and a.nbvisit=b.nbvisit
FULL join suiv.Tvnimprog c on a.anumpat= c.anumpat and a.nbvisit=c.nbvisit 
FULL join suiv.Tvnimprogcys d on a.anumpat= d.anumpat and a.nbvisit=d.nbvisit 
FULL join suiv.Tvnimprogchim e on a.anumpat= e.anumpat and a.nbvisit=e.nbvisit
where   not (CRFPAGESTATUS1<0 and CRFPAGESTATUS2<0 and CRFPAGESTATUS3<0 and CRFPAGESTATUS4<0 and CRFPAGESTATUS5<0) and not (a.desac=1 and b.desac=1 and c.desac=1 and d.desac=1 and e.desac=1 )
ORDER BY a.anumpat,	a.NBVISIT;
quit;



DATA stu.CL_TVNIM_SUIV;
    SET stu.CL_TVNIM_SUIV;
    /* Vérification de toutes les variables */
    ALL_EMPTY = 1; /* 1 = toutes vides, 0 = au moins une remplie */

    ARRAY num_vars VESICONS	NSCYTO	NSCYTORES	NSCREATRES	NSCREAT	NSECBU	FIBRONEO	NSFIBRO	NSDFIBRO	NSANESGEN	NSBIOPS	NSASPEN	TDNSTDMABD	TDMABDMULT	NBTDMABD	TDNSDTDM	TDNRESLR	TDNSRESHA	TDNSRESHAU	TDNSADENO	TDNSLOCA	TDNSANOM	TDNSPREC	NSIRM	MULTIRM	NBIRM	IRMNSDTDM	IRMNRESLR	IRMNSRESHA	IRMNSRESHAU	IRMNSADENO	IRMNSLOCA	IRMNSANOM	IRMNSPREC	AUTREIMAG	BIMAGT	BIMAGN	BIMAGM	SANG	MARSANGC	URINE	MARURIC	TUMEUR	MARTUMEC	desacB	BPRDEVNT	DNVRES	NVUSCOP	NVCYS	RECINTR	RECIVUS	RECIURE	NF1	NVBCG	NVBCGDB	NVBCGFN	NVBCGPRT	NVBCGSVI	NVAE	NVDAEBD	NVDAEFN	NVAEINS	NVAESVI	NVAUTE	NVAUTENB	DESAC	PRDEVNT	PRPROG	PRGPELV	PRGILIAC	PRLAORT	PROGMET	PRGANGL	PRFOIE	PRPOUM	PROGOS	PRAUTRS	PRAUTRE	PRTRAITE	PRRTUV	PRHEX	PRNBI	IMCYS	IMCHM	IMCHM2	IMRDP	IMRDPIN	IMRDPDB	IMRDPNB	IMRDPDS	IMRDPCHP	IMRDPDF	IMRDPTL	IMTTDF;

    /* Vérification des variables numériques */
    DO i = 1 TO DIM(num_vars);
        IF num_vars[i] NE . THEN ALL_EMPTY = 0;
    END;

    /* Vérification des variables caractères */
     ARRAY char_vars TDNSPRE	IRMNSPREP	MARSANG	MARURI	MARTUME	NVBCGPRTP	NVBCGSVIP	NVAEsVIP	NVAUTENOM	PRAUTRSP	PRAUTREP	IMRDPDFP	IMRDPEFS	IMTTDFP;
 
    DO i = 1 TO DIM(char_vars);
        IF char_vars[i] NE "" THEN ALL_EMPTY = 0;
    END;
    
    
	if ALL_EMPTY = 0;
	DROP i ALL_EMPTY;
RUN;



proc contents data=stu.CL_TVNIM_SUIV noprint out=atest;run;
proc sort;by varnum;run;








%suppr(SUIVITVNIM);

proc contents data=SUIV.Tvnimprogchim out=stu.atemp noprint;run;
proc sort;by varnum;run;


proc sql noprint ; create table stu.CL_TVIM_SUIV as select a.essai,	a.site,	a.anumpat,	a.NBVISIT,	a.bra,	a.vnf,	a.v,	a.vpla,	a.recidive,	a.crftitle,	a.crfpagecyclenumber,
a.CRFPAGESTATUS as CRFPAGESTATUS1 "TVIM SUIVI" ,
TVIMREC.CRFPAGESTATUS as CRFPAGESTATUS2 "TVIM recidive" ,
a.VESICONS,	a.NSCYTO,	a.NSCYTONB,	a.NSCYTORES,	a.NSECBU,	a.NSECBUNB,	a.NSCREAT,	a.NSCREATRES,	a.FIBRONEO,	a.NSFIBRO,	a.NSDFIBRO,	a.NSANESGEN,	a.NSASPEN,	a.NSLOCRECIP,	a.NSLOCRECIC,	a.TDMABD,	a.TDMABDMULT,	a.NBTDMABD,	a.BTDMD,	a.BTDMLOC,	a.BTDMHAPU,	a.BTDMADEN,	a.BTDMILIO,	a.BTDMIPR,	a.BTDMING,	a.BTDMAORT,	a.BTDMDF,	a.IDBTDMDF,	a.IDBTDMDFC,	a.IRM,	a.MULTIRM,	a.NBIRM,	a.BIRMD,	a.BIRMLOC,	a.BIRMHAPU,	a.BIRMADEN,	a.BIRMILIO,	a.BIRMIPR,	a.BIRMING,	a.BIRMAORT,	a.BIRMDF,	a.IDBIRMDF,	a.IDBIRMDFC,	a.TEP,	a.MULTITEP,	a.NBTEP,	a.BTEPD,	a.BTEPLOCO,	a.BTEPHAU,	a.BTEPADEN,	a.BTEPILIO,	a.BTEPIPR,	a.BTEPING,	a.BTEPAORT,	a.BTEPDF,	a.IDTEPDF,	a.IDTEPDFC,	a.AUTREIMAG,	a.BILM,	a.BILN,	a.SANG,	a.MARSANG,	a.MARSANGC,	a.URINE,	a.MARURI,	a.MARURIC,	a.TUMEUR,	a.MARTUME,	a.MARTUMEC,

b.IMDEVNT,	b.DESAC,	b.IMRECLOC,	b.IMRECVES,	b.IMRECUTR,	b.IMRECHAP,	b.IMRECPELV,	b.IMREDREC,	b.IMREDOTH,	b.IMREDOTHS,	b.IMREDREG,	b.IMGPELV,	b.IMGILIAC,	b.IMOGMET,	b.IMLAORT,	b.IMMETGAN,	b.IMFOIE,	b.IMPOUM,	b.IMOS,	b.IMPERI,	b.IMRCERE,	b.IMSURR,	b.IMPSOAS,	b.IMAUTRS,	b.IMAUTRSP,	b.IMAEVTMET,	b.IMAUTREP,	b.IMPRLHIST,	b.IMDPREL,	b.IMTPPREL,	b.IMSITPREL,	b.IMRD,	b.IMRDDB,	b.IMRDFN,	b.IMRDSI,	b.IMRDDR,	b.IMRDCI,	b.IMRDES,	b.IMRDTL,	b.IMTFTFOC,	b.IMTFRFRQ,	b.IMTFCRYO,	b.IMTFATPP
,b.IMCHIMIO
from SUIV.Suivitvim a
FULL join SUIV.TVIMREC b on a.anumpat=b.anumpat and a.nbvisit=b.nbvisit and a.anumpat NE "" and b.anumpat NE ""

WHERE a.anumpat ne "" and not(a.bra = 2 and a.CRFPAGESTATUS<0 and a.CRFPAGESTATUS<0) and not (CRFPAGESTATUS1<0 and CRFPAGESTATUS2<0) and  not (a.DESAC = 1 and a.DESAC = 1 )
ORDER BY a.anumpat,	a.NBVISIT;
;
;
quit;


DATA stu.cl_tvim_suiv;
    SET stu.cl_tvim_suiv;
    /* Vérification de toutes les variables */
    ALL_EMPTY = 1; /* 1 = toutes vides, 0 = au moins une remplie */

    ARRAY num_vars VESICONS	NSCYTO	NSCYTONB	NSCYTORES	NSECBU	NSECBUNB	NSCREAT	NSCREATRES	FIBRONEO	NSFIBRO	NSDFIBRO	NSANESGEN	NSASPEN	NSLOCRECIC	TDMABD	TDMABDMULT	NBTDMABD	BTDMD	BTDMLOC	BTDMHAPU	BTDMADEN	BTDMILIO	BTDMIPR	BTDMING	BTDMAORT	BTDMDF	IDBTDMDFC	IRM	MULTIRM	NBIRM	BIRMD	BIRMLOC	BIRMHAPU	BIRMADEN	BIRMILIO	BIRMIPR	BIRMING	BIRMAORT	BIRMDF	IDBIRMDFC	TEP	MULTITEP	NBTEP	BTEPD	BTEPLOCO	BTEPHAU	BTEPADEN	BTEPILIO	BTEPIPR	BTEPING	BTEPAORT	BTEPDF	IDTEPDFC	AUTREIMAG	BILM	BILN	SANG	MARSANGC	URINE	MARURIC	TUMEUR	MARTUMEC	IMDEVNT	DESAC	IMRECLOC	IMRECVES	IMRECUTR	IMRECHAP	IMRECPELV	IMREDREC	IMREDOTH	IMREDREG	IMGPELV	IMGILIAC	IMOGMET	IMLAORT	IMMETGAN	IMFOIE	IMPOUM	IMOS	IMPERI	IMRCERE	IMSURR	IMPSOAS	IMAUTRS	IMAEVTMET	IMPRLHIST	IMDPREL	IMTPPREL	IMRD	IMRDDB	IMRDFN	IMRDSI	IMRDDR	IMRDCI	IMRDTL	IMTFTFOC	IMTFRFRQ	IMTFCRYO	IMCHIMIO;
  
    /* Vérification des variables numériques */
    DO i = 1 TO DIM(num_vars);
        IF num_vars[i] NE . THEN ALL_EMPTY = 0;
    END;

    /* Vérification des variables caractères */
     ARRAY char_vars NSLOCRECIP	IDBTDMDF	IDBIRMDF	IDTEPDF	MARSANG	MARURI	MARTUME	IMREDOTHS	IMAUTRSP	IMAUTREP	IMSITPREL	IMRDES	IMTFATPP;
 
    DO i = 1 TO DIM(char_vars);
        IF char_vars[i] NE "" THEN ALL_EMPTY = 0;
    END;
    
    
	if ALL_EMPTY = 0;
	DROP i ALL_EMPTY;
RUN;



/* PGU : Xnumpat et Xvisitname n'existe plus donc je ne suis pas sur que cette partie soit encore utile*/

* Créer une table contenant les actes de chirugie des patients TVIM;  
data stu.CL_OTH_CHIR;
retain &ordervar;
set suiv.Tvimrec;
keep &ordervar
IMCH IMCHDB	IMCHFN IMCHHSP IMCHCD IMCHEXE IMCHEXEP IMCHVESI	IMCHDVESI IMCHJJ IMCHDJJ IMCHNEPH IMCHDNEPH	IMCHDER	IMCHDDER IMCHAINT IMCHAINTD;
if not(bra = 2 and CRFPAGESTATUS<0);
run;

