/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables d'analyse biologiques

 Ce fichier permet de crï¿½er les tables mappï¿½es concernant les analyses biologiques des patients
V1 20/10/2020 -> Anthony M

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir ï¿½tï¿½ lancï¿½;

* PG : le code serait a revoir pour le simplifier;


%MACRO suppr(table);proc sql noprint; Drop Table &table;quit;%mend;




 * Creer le format de lecture de ces donnees;
 proc format lib=stu;
value t
0='T0'
1='Tx'
2='Tis'
3='Ta'
4= 'T1'
5='T1a'
6='T1b'
7='T2'
8='T2a'
9= 'T2b'
10='T3'
11='T3a'
12='T3b'
13='T4' 
14='T4a'
15='T4b'
;
value n
-1="Nx"
0="N0"
1="N+"
2="N1"
3="N2"
4="N3";

value m
-1="Mx"
0="M0"
1="M1";

value j
-1="GX"
1="G1"
2="G2"
3="G3";

value k
-1="GX"
1="FP"
2="BG"
3="HG";

value $t_N
'T0'=0
'TX'=1
'TIS'=2
'TA'=3
'T1'=4
'T1A'=5
'T1B'=6
'T2'=7
'T2A'=8
'T2B'=9
'T3'=10
'T3A'=11
'T3B'=12
'T4'=13
'T4A'=14
'T4B'=15
;
value $n_n
"NX"=-1
"N0"=0
"N+"=1
"N1"=2
"N2"=3
"N3"=4;
value $m_n
"MX"=-1
"M0"=0
"M1"=1;
run;
run;
/* --------------------------------------- partie anapath fiche cys ----------------------- /*

/* retrait des variable caché et dérivé inutile */
data cysanap;set anap.cysanap;
drop ANGANGL	ANBGANGL	ANJUXTDEC	ANCADEPRT	ANCADEPRN	ANCADEPRM	ANCMARTHEC	ANIMUNOCC CCCENT ASEXE AAGE CENT IDPAT DDONAVA
;run;

/* les loc sont en table répété, on va les convertir pour faire une seul table . 2 variable macro et micro , donc 2 transposes */

data Cysanap_loca_sieg;set anap.Cysanap_loca_sieg;anumpat=substr(anumpat,1,6); if visitcyclenumber NE . and anumpat NE "" and ANLOCASI NE "";run;
proc sort data=Cysanap_loca_sieg; by  anumpat visitcyclenumber;run;
proc transpose data=Cysanap_loca_sieg out=an_siege_1 prefix=MAC_;
BY anumpat visitcyclenumber;
var  ANEXINI;
 format ANEXINI ANEXINIANAP. ;
ID ANLOCASI;
run;

proc transpose data=Cysanap_loca_sieg out=an_siege_2 prefix=MIC_;
BY anumpat visitcyclenumber;
var   ANEXDEF;
  format ANEXDEF ANEXDEFANAP. ;
ID ANLOCASI;
run;

/* retrait des variable qui sert a rien */

data an_siege_1 ;set an_siege_1; drop _NAME_ _LABEL_;run;
data an_siege_2 ;set an_siege_2; drop _NAME_ _LABEL_;run;



/* on merge le tout ensemble  dans RAP il y a des infos importante (suivi/inclusion etc), a merger */


proc sql noprint NOWARN; create table stu.AN_CYSTEC  as select 
a.site,	substr(a.anumpat,1,6)
 as anumpat,	a.visitname,	a.visitcyclenumber,	b.crftitle,	a.crfpagecyclenumber,	b.CRFPAGESTATUS,TPRAP,MTDANAP,	T_INTER,V, b.*,c.*,d.*


from cysanap b left join anap.rap a on a.anumpat=b.anumpat and a.visitcyclenumber=b.visitcyclenumber
left join an_siege_1 c on  a.anumpat=c.anumpat and a.visitcyclenumber=c.visitcyclenumber
left join an_siege_2 d on  a.anumpat=d.anumpat and a.visitcyclenumber=d.visitcyclenumber

;quit;
%suppr(cysanap);%suppr(an_siege_1);%suppr(an_siege_2);
data stu.AN_CYSTEC; retain &ordervar; set  stu.AN_CYSTEC;run;

/* ----------------------------------------------TRAITEMENT DE LA PARTIE RTUV ----------------------------------- */

/* retrait des variable qui sert a rien */
data Rtuvanap1;set anap.Rtuvanap1;
drop  CCCENT ASEXE AAGE CENT IDPAT DDONAVA
;run;

/* on merge le tout ensemble . dans RAP il y a des infos importante (suivi/inclusion etc), a merger*/
proc sql noprint; create table stu.AN_RTUV  as select 
a.site,	substr(a.anumpat,1,6)
 as anumpat,	a.visitname,	a.visitcyclenumber,	b.crftitle,	a.crfpagecyclenumber,	b.CRFPAGESTATUS,TPRAP,MTDANAP,	T_INTER,V, b.*


from Rtuvanap1 b left join anap.rap a on a.anumpat=b.anumpat and a.visitcyclenumber=b.visitcyclenumber;quit;


%suppr(Rtuvanap1);


/* ----------------------------------------------TRAITEMENT DE LA PARTIE  META ----------------------------------- */

/* retrait des variable qui sert a rien */
data Anameta;set anap.Anameta;
drop  CCCENT ASEXE AAGE  DDONAVA
MTTHERAP
MTTHERAC
RL1NATURE
RL1ORGAN
RL1AUORGP
RL1THISTO
RL1STHISTO
RL1STHISTOP
RL1STHISTOC
RLIMMUN
RLIMMUNP
RLIMMUNC
RLMTHERA
RLMTHERAP
RLMTHERAPC
INAC
RL2NATURE2
RL2ORGAN
RL2AUORGP
RL2THISTO
MT2IMMUNO
MT2IMUNOAC
MT2THERA
MT2THERAP
MT2THERAC2
;run;

/* on merge le tout ensemble . dans RAP il y a des infos importante (suivi/inclusion etc), a merger*/
proc sql noprint; create table stu.AN_Anameta  as select 
a.site,	substr(a.anumpat,1,6)
 as anumpat,	a.visitname,	a.visitcyclenumber,	b.crftitle,	a.crfpagecyclenumber,	b.CRFPAGESTATUS,TPRAP,	T_INTER,V, b.*


from Anameta b left join anap.rap a on a.anumpat=b.anumpat and a.visitcyclenumber=b.visitcyclenumber;quit;
data stu.AN_Anameta ; retain &ordervar; set stu.AN_Anameta ;run;


%suppr(Anameta);


/* ya un tableau avec les type histologique de mestastase dans la fiche. pour l'instant c'est vide mais on sait jamais*/

data Anameta_his;set anap.Anameta_his;
;run;
proc sql noprint; create table AN_METAHISTO  as select 
a.site,	substr(a.anumpat,1,6) as anumpat,	a.visitname,	a.visitcyclenumber,	b.crftitle,	a.crfpagecyclenumber,	b.CRFPAGESTATUS,TPRAP,MTDANAP,	T_INTER , a.*


from Anameta_his a left join anap.rap b on a.anumpat=b.anumpat and a.visitcyclenumber=b.visitcyclenumber
where (RL2STHISTO NE . or RL2PRCT NE .) or repeatnumber=1 /* ici je fait en sort de garder au moins 1 ligne vide pour qu'on identifie bien les patients avec des données manquantes */;quit;


%suppr(Anameta_his);



/* table simple des echantillon congelé, a reprendre en l'état */

data stu.AN_TC;
set anap.Tiscong_frozlist;
run;

 /*  ------------------------------------------- TNM ALL ------------------------------------------------------- */
/* on s'attaque au plus dur, la table TNM ALL qui doit contenir TOUT LES TNM + grades connu */


proc sql noprint; create table TNM_ALL as
/* ----- premier UNION : on va chercher les infos de la table qu'on vient de créer dans stu : An_cystec*/

 
select anumpat,crfpagecyclenumber, crftitle,TPRAP,V,NUMANAP,
/* on simplifie les dates, en prenant du plus pres a chaque fois entre date de prélèvement, date de compte rendu, date de rapport, etc. */
case when ANDPRELP NE . then ANDPRELP  when ANDRECP NE . then ANDRECP else ANDCOMPP end as ANDPRELP "date de prélèvement" format DDMMYY10.,


/* ici on cherche le T MAX pour chaque fiche. il y a 6 T saisie par ligne, la fonction max(a,b,c) permet de selectionner directement le plus important 
plusieurs fonction s'enchaine, le but étant de convertir Chaque T pour avoir la meme tete a savoir celle du format T., pour cela je joue avec le PUT et INPUT
*/


max(input(put(upcase(put(T_INTER,T_INTERANAP.)),$t_N.),2.) /*as T_INTER "T interprété par Karine"*/,
input(put(upcase(put(ANCTNMT,ANCTNMTANAP.)),$t_N.),2.) /*as ANCTNMT " T 1ere saisie en haut de page"*/,
input(put(case when substr(ANCVSTAPT,1,1)="T" then ANCVSTAPT when ANCVSTAPT NE "" then cats('T',ANCVSTAPT) else "" end,$t_N.),2.) /*ANCVSTAPT "T vessie fin de page" */,
input(put(case when substr(ANCUSTAPT,1,1)="T" then ANCUSTAPT when ANCUSTAPT NE "" then cats('T',ANCUSTAPT) else "" end,$t_N.),2.) /* ANCUSTAPT "T uretre fin de page"*/ ,
input(put(upcase(put(TU1,TU1ANAP.)),$t_N.),2.) /*  TU1 "T uretre"*/ ,
 input(put(upcase(put(TU2,TU2ANAP.)),$t_N.),2./*  TU2 "T uretre"*/)
) as TF " T final par ligne" format=t.,

/* exactement le meme principe pour N */

case when max(
input(put(case when substr(ANCVSTAN,1,1)="N" then upcase(ANCVSTAN) when ANCVSTAN NE "" then cats('N',upcase(ANCVSTAN)) else "" end,$n_N.),2.)  /* ANCVSTAN "N vessie fin de page"*/,
input(put(upcase(put(NU1,NU1ANAP.)),$n_N.),2.),
input(put(upcase(put(NU2,NU2ANAP.)),$n_N.),2.)
)=. and ANCNBGTTE>0 then 1 else max(
input(put(case when substr(ANCVSTAN,1,1)="N" then upcase(ANCVSTAN) when ANCVSTAN NE "" then cats('N',upcase(ANCVSTAN)) else "" end,$n_N.),2.)  /* ANCVSTAN "N vessie fin de page"*/,
input(put(upcase(put(NU1,NU1ANAP.)),$n_N.),2.),
input(put(upcase(put(NU2,NU2ANAP.)),$n_N.),2.)) end as NF "N final par ligne" format=N.,
max( input(put(upcase(put(MU1,MU1ANAP.)),$m_N.),2.),input(put(upcase(put(MU2,MU2ANAP.)),$m_N.),2.) ) as MF "M final par ligne" format=m.,
ANCG73 as grade73 format=j.,

ANCG04 as grade04 format=k.,

case when ANCCIS=2 then 2 else ANCCISAS end as CASASS format=ANCCISASANAP.,
case when ANCCIS=2 then 2 else ANCCISEX  end as CASEXL format=ANCCISEXANAP.,
case when put(ANTPHISTO,ANTPHISTOANAP.)="Autre" then ANTPHISTOP else  put(ANTPHISTO,ANTPHISTOANAP.) end as histo

from stu.An_cystec 
where anumpat NE "" and V NE 2


UNION

/* ----- second UNION : on va mettre a la suite les données de RTUV issue de la table qu'on a crée stu.An_rtuv sur le meme principe */


select anumpat,crfpagecyclenumber, crftitle,TPRAP,V,NUMANAP,
case when ARDPREL NE . then ARDPREL  when ARDRECP NE . then ARDRECP else ARDANA end as ANDPRELP "date de prélèvement" format DDMMYY10.,

max(input(put(upcase(put(T_INTER,T_INTERANAP.)),$t_N.),2.) /*as T_INTER "T interprété par Karine"*/,
input(put(upcase(put(ARCLASTNM,ARCLASTNMANAP.)),$t_N.),2.) /*as ANCTNMT " T 1ere saisie en haut de page"*/,
input(put(upcase(put(TU1,TU1ANAP.)),$t_N.),2.) /*  TU1 "T uretre"*/ ,
 input(put(upcase(put(TU2,TU2ANAP.)),$t_N.),2./*  TU2 "T uretre"*/)
) as TF " T final par ligne" format=t.,

max(
input(put(upcase(put(NU1,NU1ANAP.)),$n_N.),3.),
input(put(upcase(put(NU2,NU2ANAP.)),$n_N.),3.)) as NF "N final par ligne" format=N.,

max(
input(put(upcase(put(mU1,mU1ANAP.)),$m_N.),3.),
input(put(upcase(put(mU2,mU2ANAP.)),$m_N.),3.)) as MF "M final par ligne" format=m.,
ARDRAD73 as grade73 format=j.,
ARGRAD04 as grade04 format=k.,

case when ARCIS1=2 then 2 else ARCISASS end as CASASS format=ANCCISASANAP.,
case when ARCIS1=2 then 2 else ARCISEX  end as CASEXL format=ANCCISEXANAP.,
case when put(ARTPHISTO,ARTPHISTOANAP.)="Autre" then ARTPHISTOP else  put(ARTPHISTO,ANTPHISTOANAP.) end as histo

from stu.An_rtuv

where anumpat NE ""

UNION
/* ----- 3eme UNION : on va mettre a la suite les données de metastase issue de la table qu'on a crée stu.An_anameta sur le meme principe, sauf que bon la on a pas de T,N,grade73 ou grade04  */
select 
anumpat,crfpagecyclenumber, crftitle,TPRAP,V,NUMANAP,
case when MTDPREL NE . then MTDPREL  when MTDREP NE . then MTDREP else MTDANAP end as ANDPRELP "date de prélèvement" format DDMMYY10.,
. as TF " T final par ligne" format=t.,
. as NF "N final par ligne" format=N.,
case when MTBIOPSI=1 and MTHISTOP NE "PAF DE TUMEUR" then 1 else . end as MF "M final par ligne" format=m.,
. as grade73 format=j.,
. as grade04 format=k.
/*
case when  MTAUORG NE "" then MTAUORG else put(MTORG,MTORGANAP.)  end as MLOG format=$50.
*/
from stu.An_anameta

;
;quit;


data tnm_all;
set tnm_all;
if not (TF=. and NF=. and MF=. and grade73 = . and grade04 = .) ;

run;
proc sql noprint; create table tnm_all2 as select a.* from tnm_all a left join stu.Et_exclusion b on a.anumpat=b.anumpat and DEXCL =.;quit;
data tnm_all; set tnm_all2;run;


/* Filtrer les réponses MTAUORG pour V=1 */
data loc_meta;
    set stu.An_anameta;
    where V NE 2 and V NE 5;
run;
proc sort; by anumpat;run;

data loc_meta;
set loc_meta;
format metaloc $50.
retain meta;
by anumpat;
if First.anumpat then do;
if MTAUORG NE "" then metaloc= MTAUORG;
else metaloc=put(MTORG,MTORGanap.);
end;
else do;
if MTAUORG NE "" then metaloc= cats(metaloc,"/",MTAUORG);
else metaloc=cats(metaloc,"/",put(MTORG,MTORGanap.)); ;
end;
if last.anumpat;
keep anumpat metaloc;
run;

proc sql noprint; create table tnm_all_1 as select a.*,metaloc from tnm_all a left join loc_meta b on a.anumpat=b.anumpat
and find(crftitle,"Meta");quit;





/* table temporaire ou on vire le suivi */
data temp_N0; set TNM_ALL; where  V NE 2 and V NE 5 and TF NE .;run; 

proc sort;by anumpat descending TF ;run;
/* on commence par creer une table temporaire de TNM_incl, ou on chope les infos du T qui colle bien. on vire le reste car bien qu'on ai eu le Tmax,
on a pas nécéssairement N max, etc. va falloir faire des sous table pour les creer */
data TNM_incl;
set temp_N0;
by anumpat;
if First.anumpat;
label TF="T final inclusion";
drop  NF MF grade73 grade04;
run;


/* on reccupere le max de chaque item a placer dans la table */
proc sql noprint; create table temp_N as select distinct anumpat, max(NF) as NF  from temp_N0 group by anumpat ;quit;
proc sql noprint; create table temp_M as select distinct a.anumpat, max(MF) as MF  from temp_N0 a left join loc_meta b on a.anumpat=b.anumpat group by a.anumpat ;quit;
proc sql noprint; create table temp_G1 as select distinct anumpat, max(grade73) as grade73  from temp_N0 group by anumpat ;quit;
proc sql noprint; create table temp_G2 as select distinct anumpat, max(grade04) as grade04  from temp_N0 group by anumpat ;quit;

/* on merge le tout ensemble */
proc sql noprint; create table temp_final as select a.* ,NF  "N final inclusion" format=N. ,MF "M final inclusion" format=m.,grade73 format=j.,grade04 format=k.
from TNM_incl a left join temp_N b on a.anumpat=b.anumpat left join temp_M c on a.anumpat=c.anumpat 
left join temp_G1 d on a.anumpat=d.anumpat left join temp_G2 e on a.anumpat=e.anumpat 
;quit;

/* on replace au bon endroit */
data stu.AN_TNM_ALL;set TNM_ALL;run;

/* déplacement de code : traitement aldéric pour meta, je met ça ici direct */
DATA An_tnm_incl;
SET temp_final;
IF (grade73=3) or (grade04=3) THEN Grade = 3;
ELSE IF (grade73>0) or (grade04>0) THEN Grade = 2;
ELSE Grade = 1;
if Grade=1 and TF=2 then Grade=3;
/*IF anumpat = "01-093" THEN t = 5; retrait le 31/05/2023 */
/*FORMAT Grade grad.;*/
label Grade=" Grade final";
LENGTH AJCC $ 5;
IF MF>0 THEN AJCC = "IV";
ELSE IF TF = 15 THEN AJCC = "IV";
ELSE IF NF > 1 and TF > 3 THEN AJCC = "IIIb";
ELSE IF (NF>0 and TF>3) or TF>9 THEN AJCC = "IIIa";
ELSE AJCC = "<II";
RUN;


/* 05.2024 -> patch correctif des incohérences ! */
DATA An_tnm_incl;
set An_tnm_incl;
if Grade=1 and TF=2 then Grade=3;
run;

proc sql noprint; create table stu.An_tnm_incl as select a.anumpat,b.* from stu.resume a left join An_tnm_incl b on a.anumpat=b.anumpat;quit;

proc sort nodupkey;by anumpat;run;




/* on supprime les tables temporaires */ 
%suppr(temp_N); %suppr(temp_M); %suppr(temp_final);%suppr(TNM_incl);%suppr(TNM_all);%suppr(temp_G1);%suppr(temp_G2);%suppr(temp_N0);

