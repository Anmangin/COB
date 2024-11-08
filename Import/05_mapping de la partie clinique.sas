/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables cliniques

 Ce fichier permet de cr�er les tables mapp�es concernant le suivi clinique des patients
V1 20/10/2020 -> Anthony M
V2 06/09/2023 -> Anthony M et Pierre G revu pour France Cohorte

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir �t� lanc�;


*           - ---- -- - - - PARTIE INCLUSION  - - - - - - ;

* Cr�er une table interm�diaire � partir de la table de caract�ristique des patients de l'inclusion;
data STU.CL_PARAM_CLIN_t;
retain &ordervar;
set incl.descpat;
label PSANGML ="Taux PSA"
DINCL="Date inclusion";
  if TART1 = 888 then tart1=.;
  drop  EUDRACTP3 EUDRACTP2 EUDRACTP1 EUDRACT  IDESSAI EUDRACTCAR ETCLIN PSA PSAUNIT PSAUNIT2 ;
run;

* R�ordonne les tables � merger et �limine les possibles doublons;
Proc sort data=STU.CL_PARAM_CLIN_t nodupkey; by anumpat;run;
Proc sort data=INCL.BILSANTE nodupkey;by anumpat;run;
data INCL.bilsante; set INCL.BILSANTE; ;run;
proc sort data=incl.bilext nodupkey;by anumpat;run;
data INCL.bilext; set INCL.bilext; ;run;

* Cr�er la table merg�e contenant toutes les caract�ristiques cliniques du patient � l'inclusion;
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

* Supprime la table interm�diaire;
%suppr(STU.CL_PARAM_CLIN_t);

* Cr�er une table contenant les caract�ristiques des patients TVNIM � l'inclusion;
data STU.CL_TVNIM;
retain &ordervar;
set incl.econim;
drop FORMU CCCENT  ASEXE	AAGE IDCOB CENT IDPAT MONAIS ANNAIS NIMCYS NIMCYSDB	NIMCYSFN NIMCYSIN NIMCYSV NIMCYSH NIMCYSCD 
NIMCYSGHM NIMCYSGDF NIMCYSCG NIMEXE NIMEXEP NIMURET NIMNEPH NIMTNEPH NIMEXTP NIMTEXTP NIMTEXTPP NIMEXTPR NIMDRV NIMDRVCT NIMNEO	
NIMNEODF NIMNEODFC NIMCYSOP	NIMCYSSG NIMCYSTF NIMCYSCL NIMCYSSI	NIMCYSCP NIMCYSCPT NIMCYSMD	NIMCYSMDP SNIMCYSCH	NIMCYSCH NIMCYSCHP;
run;


* Cr�er une table contenant les caract�ristiques des patients TVIM � l'inclusion;
PROC SORT DATA=INCL.ECOIMOP;by anumpat;run;
data INCL.ECOIMOP; set INCL.ECOIMOP;run;
PROC SORT DATA=INCL.ECOIMTR;by anumpat;run;
data INCL.ECOIMTR; set INCL.ECOIMTR;run;

data STU.CL_TVIM;
retain &ordervar;
merge INCL.ECOIMOP INCL.ECOIMTR;
by anumpat;
drop CCCENT		DINCL ASEXE DDONTIM	AAGE IDCOB CENT	IDPAT MONAIS ANNAIS IMCYS CYS_ND_REAS IMCYSDBH IMCYSFNH	IMCYSIN	IMCYSH 
IMCYSCD	IMCYSV IMCYSGHM	IMCYSGDF IMCYSCG IMEXE IMEXEP IMURET IMNEPH	IMTNEPH	IMEXTP IMEXCU IMEXCUR IMEXUD IMEXUDR IMEXUG	IMEXUGR	
IMEXUR IMEXURR IMEXDF IMEXDFP IMEXDFR IMDRV	IMNEO IMNEODF IMNEODFC IMDRVCT IMDRVCTC IMCYSOP	IMCYSSG	IMCYSTF	IMCYSCL	IMCYSSI	IMCYSCP	
IMCYSCOMP IMCYSMD IMCYSMDP SNIMCYSCH IMCYSCH IMCYSCHP IMCHM	IMCHMIN	IMCHMDB	IMCHMFN	IMCHMNB	IMCHMGC	IMCHMVI	IMCHMMV	IMCHMDF	IMCHMTL	
IMCHMTLP IMCHMTT IMCHM2	IMCHM2DB IMCHM2FN IMCHM2QG IMCHM2GC	IMCHM2MV IMCHM2VQ IMCHM2VI IMCHM2MQ	IMCHM2DF IMCHM2TL IMCHM2TT;
run;



*  - ---- -- - - - PARTIE SUIVI  - - - - - - ;

data SUIVITVNIM;set suiv.SUIVITVNIM;run;
proc sql noprint; create table stu.CL_TVNIM_SUIV as select 

a.essai,	a.site,	a.anumpat,	a.NBVISIT,	a.bra,	a.vnf,	a.v,	a.vpla,	a.recidive,	a.crftitle,	a.crfpagecyclenumber,
a.CRFPAGESTATUS as CRFPAGESTATUS1 "TVNIM SUIVI" ,
Tvnimreci.CRFPAGESTATUS as CRFPAGESTATUS2 "TVNIM recidive" ,
Tvnimprog.CRFPAGESTATUS as CRFPAGESTATUS3 "TVNIM prog" ,
Tvnimprogcys.CRFPAGESTATUS as CRFPAGESTATUS5 "TVNIM cys" ,
Tvnimprogchim.CRFPAGESTATUS as CRFPAGESTATUS6 "TVNIM chim" ,

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

ORDER BY a.anumpat,	a.NBVISIT;
quit;
%suppr(SUIVITVNIM);

proc contents data=SUIV.Tvnimprogchim out=stu.atemp noprint;run;
proc sort;by varnum;run;


proc sql noprint ; create table stu.CL_TVIM_SUIV as select a.essai,	a.site,	a.anumpat,	a.NBVISIT,	a.bra,	a.vnf,	a.v,	a.vpla,	a.recidive,	a.crftitle,	a.crfpagecyclenumber,
a.CRFPAGESTATUS as CRFPAGESTATUS1 "TVIM SUIVI" ,
TVIMREC.CRFPAGESTATUS as CRFPAGESTATUS2 "TVIM recidive" ,
a.VESICONS,	a.NSCYTO,	a.NSCYTONB,	a.NSCYTORES,	a.NSECBU,	a.NSECBUNB,	a.NSCREAT,	a.NSCREATRES,	a.FIBRONEO,	a.NSFIBRO,	a.NSDFIBRO,	a.NSANESGEN,	a.NSASPEN,	a.NSLOCRECIP,	a.NSLOCRECIC,	a.TDMABD,	a.TDMABDMULT,	a.NBTDMABD,	a.BTDMD,	a.BTDMLOC,	a.BTDMHAPU,	a.BTDMADEN,	a.BTDMILIO,	a.BTDMIPR,	a.BTDMING,	a.BTDMAORT,	a.BTDMDF,	a.IDBTDMDF,	a.IDBTDMDFC,	a.IRM,	a.MULTIRM,	a.NBIRM,	a.BIRMD,	a.BIRMLOC,	a.BIRMHAPU,	a.BIRMADEN,	a.BIRMILIO,	a.BIRMIPR,	a.BIRMING,	a.BIRMAORT,	a.BIRMDF,	a.IDBIRMDF,	a.IDBIRMDFC,	a.TEP,	a.MULTITEP,	a.NBTEP,	a.BTEPD,	a.BTEPLOCO,	a.BTEPHAU,	a.BTEPADEN,	a.BTEPILIO,	a.BTEPIPR,	a.BTEPING,	a.BTEPAORT,	a.BTEPDF,	a.IDTEPDF,	a.IDTEPDFC,	a.AUTREIMAG,	a.BILM,	a.BILN,	a.SANG,	a.MARSANG,	a.MARSANGC,	a.URINE,	a.MARURI,	a.MARURIC,	a.TUMEUR,	a.MARTUME,	a.MARTUMEC,

b.IMDEVNT,	b.DESAC,	b.IMRECLOC,	b.IMRECVES,	b.IMRECUTR,	b.IMRECHAP,	b.IMRECPELV,	b.IMREDREC,	b.IMREDOTH,	b.IMREDOTHS,	b.IMREDREG,	b.IMGPELV,	b.IMGILIAC,	b.IMOGMET,	b.IMLAORT,	b.IMMETGAN,	b.IMFOIE,	b.IMPOUM,	b.IMOS,	b.IMPERI,	b.IMRCERE,	b.IMSURR,	b.IMPSOAS,	b.IMAUTRS,	b.IMAUTRSP,	b.IMAEVTMET,	b.IMAUTREP,	b.IMPRLHIST,	b.IMDPREL,	b.IMTPPREL,	b.IMSITPREL,	b.IMRD,	b.IMRDDB,	b.IMRDFN,	b.IMRDSI,	b.IMRDDR,	b.IMRDCI,	b.IMRDES,	b.IMRDTL,	b.IMTFTFOC,	b.IMTFRFRQ,	b.IMTFCRYO,	b.IMTFATPP

from SUIV.Suivitvim a
FULL join SUIV.TVIMREC b on a.anumpat=b.anumpat and a.nbvisit=b.nbvisit and a.anumpat NE "" and b.anumpat NE ""

WHERE a.anumpat ne "" and not(a.bra = 2 and a.CRFPAGESTATUS<0 and a.CRFPAGESTATUS<0)
ORDER BY a.anumpat,	a.NBVISIT;
;
;
quit;


/* PGU : Xnumpat et Xvisitname n'existe plus donc je ne suis pas sur que cette partie soit encore utile*/

* Cr�er une table contenant les actes de chirugie des patients TVIM;  
data stu.CL_OTH_CHIR;
retain &ordervar;
set suiv.Tvimrec;
keep &ordervar
IMCH IMCHDB	IMCHFN IMCHHSP IMCHCD IMCHEXE IMCHEXEP IMCHVESI	IMCHDVESI IMCHJJ IMCHDJJ IMCHNEPH IMCHDNEPH	IMCHDER	IMCHDDER IMCHAINT IMCHAINTD;
if not(bra = 2 and CRFPAGESTATUS<0);
run;
