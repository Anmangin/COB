/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables simples 

 Ce fichier permet de mapper une partie des tables importées
V1 20/10/2020 -> Anthony M
V2 06/09/2023 -> Anthony M et Pierre G revu pour France Cohorte

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir été lancé;

/*--------------------------------------
				Macros
--------------------------------------*/
* Déplace et renomme la table;
%macro replace(oldtable,table);
	data &table;
	set &oldtable;
	run;
	%suppr(&oldtable);
%MEND;

* Supprime la table;
%macro suppr(table);
	proc sql;
	DROP TABLE &table.;
	quit;
%MEND;

%macro ETUDE(table,etude);
	data &table;
	LENGTH ESSAI $10.;
	set &table;
	run;
%mend;

* Macro de fusion des tables d'inclusion et suivi dans une table STU;
%macro mapping(table);

	/*%etude(incl.&table.,COBINC);
	%etude(suiv.&table.,COBSUIVI);*/

	data STU.&table.;
	set incl.&table. suiv.&table.;
	run;
%mend;
	
* placer les libname;
%macro suprvar(table,var);
data &table;set &table;drop &var;
run;
%MEND;


* Réorganise par type de tabac et place la variable dans une colonne précise du tableau;
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



/*--------------------------------------
				Mapping
--------------------------------------*/

/* Les questionnaires de vie */

*fusionne les fiches QLQ30 de l'inclusion et du suivi en une table;
%mapping(QLQ30);
%replace(STU.QLQ30,STU.QLQ_QLQ30);
data  STU.QLQ_QLQ30; retain &ordervar;
set STU.QLQ_QLQ30; drop aage CCCENT CENT IDCOB ASEXE IDPAT AAGE CCRECIPRO	ERRBRA	VFORM	FORMU	CCDSVPRE	NUMLIGN	TPVISIT	CCNEPASREM	CCDSUIVI	CCBRA	DESAC	DDONAVA	MODEREMPL;

  ;run;
proc sort; by anumpat NBVISIT;run;

* 5D5L;
%mapping(Eq_5d5l);
%replace(STU.Eq_5d5l,STU.QLQ_5d5l);

data  STU.QLQ_5d5l; retain &ordervar;
set STU.QLQ_5d5l; drop aage CCCENT   ASEXE  AAGE CCRECIPRO	ERRBRA	VFORM	FORMU	CCDSVPRE	NUMLIGN	TPVISIT	CCNEPASREM	CCDSUIVI	CCBRA	DESAC	DDONAVA	MODEREMPL
  ;run;
proc sort; by anumpat NBVISIT;run;

* blm30;
%mapping(blm30);
%replace(STU.blm30,STU.QLQ_blm30);

data  STU.QLQ_blm30; retain &ordervar;
set STU.QLQ_blm30; drop aage CCCENT   ASEXE  AAGE CCRECIPRO	ERRBRA	VFORM	FORMU	CCDSVPRE	NUMLIGN	TPVISIT	CCNEPASREM	CCDSUIVI	CCBRA	DESAC	DDONAVA	MODEREMPL
  ;run;
  proc sort; by anumpat NBVISIT;run;


* bls24;
%mapping(bls24);
%replace(STU.bls24,STU.QLQ_bls24);
data  STU.QLQ_bls24; retain &ordervar;
set STU.QLQ_bls24; drop aage CCCENT   ASEXE  AAGE CCRECIPRO	ERRBRA	VFORM	FORMU	CCDSVPRE	NUMLIGN	TPVISIT	CCNEPASREM	CCDSUIVI	CCBRA	DESAC	DDONAVA	MODEREMPL
  ;run;
  proc sort; by anumpat NBVISIT;run;


/* Tables divers */

data STU.DM_CONS_GRAS;
retain &ordervar;
set INCL.Consalim_cgrasqg;
run;
proc sort; by anumpat NBVISIT repeatnumber ;run;


* Modifie la table incl.exclusion pour n'avoir que les exclus et conserve la table initiale dans STU;
DATA STU.ET_EXCLUSION;
retain &ordervar;
set incl.EXLUSION;
 drop aage CCCENT   ASEXE  AAGE MONAIS ANNAIS IDPAT IDCOB CENT DINCL;
run;


* Crée une table des antécédents domiciles qui ne contient que les codes valides;
data STU.DM_ANTERESID;
retain &ordervar_g;
set incl.Demogr_resid_ant;
format ACTIV6 1.;
drop ACTIV6;
where ACTIV6 NE .;
run;

/* Les tables pour le TABAC */

*Créer une table pour chaque type de tabac;
DATA DM_LISTABAC;
set incl.F_tabac_clope_qg;
drop  ACTIV1;
LENGTH type $30.;
type = "cigarette";
rename
MRQCLOPE=code
NOMCLOPE=nom
FLTCLOPE=filtre
NBCLOPE=NBSEM
CLOPEDB=AGEDB
CLOPEFN=AGEFN;
where ACTIV1 =1;
run;

DATA DM_LISTABAC_2;
set incl.F_tabac_cons_cigar;
LENGTH type $30.;
type=put(TYPCJGAR,TYPCJGARINCL.);
rename
MRQCIGAR=code
NOMCIGAR=nom
NBCIGAR=NBSEM
CIGARDB=AGEDB
CIGARFN=AGEFN;
where ACTIV2 =1;
drop  TYPCJGAR ACTIV2 ;
run;

DATA DM_LISTABAC_3;
set incl.F_tabac_cons_pipe;
drop ACTIV3;
LENGTH type $30.;
type="pipe";
rename
MRQTABAC=code
NOMTABAC=nom
NBPIPE=NBSEM
PIPEDB=AGEDB
PIPEFN=AGEFN;
where ACTIV3=1;
run;

* fusionne les 3 tables;
DATA STU.DM_TABAC;
retain &ordervar_g;
set DM_LISTABAC DM_LISTABAC_2 DM_LISTABAC_3;
label code="code tabac";
label type="type consommé";
label NBSEM="Nombre par semaine";
label nom= "nom tabac";
where type NE "";
run;
%placement(STU.DM_TABAC,type,7);
%suppr(DM_LISTABAC);
%suppr(DM_LISTABAC_2);
%suppr(DM_LISTABAC_3);




/* Table Boisson */

proc format lib=stu;
value boisson
1="oui";
run;

data STU.DM_Boisson;
retain &ordervar_g;
set incl.Consboi_boisson_qg;
where ACTIV4=1;
format BOIPDJ BOIMAT BOIDJ BOIAPM BOIDIN BOISOIR BOISOIRINCL.;
drop  ACTIV4;
run;


/* Tables d'Histologie */

data STU.DM_alim;
retain &ordervar_g;
set incl.Consalim_alimentfr;
where PRODUIT ne "";
run;


data STU.DM_Historique_Pro;
retain &ordervar_g;
set incl.Histoprof_profqg;
where ACTIV5=1;
drop ACTIV5;
run;


data STU.DM_TRAIT_meno;
retain &ordervar_g;
set incl.Gyneco_menopause;
where ACTIV13=1;
drop ACTIV13;
run;


data STU.DM_Histo_Maladie;
retain &ordervar_g;
set incl.Histosante2_ant_m1;
run;


data STU.DM_TRAIT_Cholest;
retain &ordervar_g;
set incl.Histosante3_ante_1;
where Activ8 =1;
drop ACTIV8;
run;


data STU.DM_TRAIT_Infl;
retain &ordervar_g;
set incl.Histosante3_med_i1;
where Activ9 =1;
drop ACTIV9;
run;


data A_temp;
retain essai site anumpat visitname visitcyclenumber crftitle crfpagecyclenumber repeatnumber CRFPAGESTATUS;
set incl.Hfamparnt_histo_fam;
format FAmi $15.;
FAmi = CCPARENT;
drop  CCPARENT PARENT       CC1 CC2 CC3 CC4;
where PVIE NE .;
run;

data A_temp_2;
set incl.Hfamparnt2_histo_1;
format FAmi $15.;
FAmi = put(PARENT,PARENTINCL.);
drop  CCPARENT PARENT      CC1 CC2 CC3 CC4;
where PVIE NE .;
run;

* Fusion des 2 tables;
 proc format lib=stu;
 value localisa	 
239 = "Tumeur de nature non précisée"
140 = "Tumeur maligne des lèvres"
141 = "Tumeur maligne de la langue"
142 = "Tumeur maligne des glandes salivaires principales"
143 = "Tumeur maligne des gencives"
144 = "Tumeur maligne du plancher de la bouche"
145 = "Tumeur maligne de parties autres ou non précisées de la bouche"
146 = "Tumeur maline de l'oropharynx"
147 = "Tumeur maligne du rhinopharynx"
148 = "Tumeur maligne de l'hypopharynx"
149 = "Tumeurs malignes de sièges autres et mal définis de la lèvre, de la cavité buccale et du pharynx"
150 = "Tumeur maligne de l'œsophage"
151 = "Tumeur maligne de l'estomac"
152 = "Tumeur maligne de l'intestin grêle"
153 = "Tumeur maligne du côlon"
154 = "Tumeur maligne du rectum, de la jonction rectosigmoïdienne et de l'anus"
155 = "Tumeur maligne du foie et des voies biliaires intrahépatiques"
156 = "Tumeur maligne de la vésicule biliaire et des voies biliaires extrahépatiques"
157 = "Tumeur maligne du pancréas"
158 = "Tumeur maligne du tissu rétropéritonéal et du péritoine"
159 = "Tumeurs malignes de sièges autres ou non précisés de l'appareil digestif et du péritoine"
160 = "Tumeur maligne des fosses nasales, de l'oreille moyenne et des sinus annexes"
161 = "Tumeur maligne du larynx"
162 = "Tumeur maligne de la trachée, des bronches et du poumon"
163 = "Tumeur maligne de la plèvre"
164 = "Tumeur maligne du thymus, du cœur et du médiastin"
165 = "Tumeurs malignes de sièges autres ou non précisés de l'appareil respiratoire et des organes thoraciques"
170 = "Tumeur maligne des os et du cartilage articulaire"
171 = "Tumeur maligne du tissu conjonctif et des autres tissus mous"
172 = "Mélanome malin de la peau"
173 = "Autres tumeurs malignes de la peau"
174 = "Tumeur maligne du sein, chez la femme"
175 = "Tumeur maligne du sein, chez l'homme"
179 = "Tumeur maligne de l'utérus, partie non précisée"
180 = "Tumeur maligne du col de l'utérus"
181 = "Tumeur maligne du placenta"
182 = "Tumeur maligne du corps de l'utérus"
183 = "Tumeur maligne de l'ovaire et des autres annexes de l'utérus"
184 = "Tumeur maligne d'organes génitaux autres ou non précisés de la femme"
185 = "Tumeur maligne de la prostate"
186 = "Tumeur maligne du testicule"
187 = "Tumeur maligne de la verge et des autres organes génitaux masculins"
188 = "Tumeur maligne de la vessie"
189 = "Tumeur maligne du rein et d'organes urinaires autres ou non précisés"
190 = "Tumeur maligne de l'œil"
191 = "Tumeur maligne de l'encéphale"
192 = "Tumeur maligne de parties autres ou non précisées du système nerveux"
193 = "Tumeur maligne du corps thyroïde"
194 = "Tumeur maligne d'autres glandes endocrines et structures apparentées"
195 = "Tumeur maligne de sièges autres et mal définis"
196 = "Tumeur maligne des ganglions lymphatiques, secondaire ou sans précision"
197 = "Tumeurs malignes secondaires des appareils respiratoire et digestif"
198 = "Tumeurs malignes secondaires d'autres sièges précisés"
199 = "Tumeur maligne de siège non précisé"
200 = "Lymphosarcome et réticulosarcome"
201 = "Maladie de Hodgkin"
202 = "Autres tumeurs malignes des tissus lymphoïde et histiocytaire"
203 = "Myélome multiple et tumeurs immunoprolifératives"
204 = "Leucémie lymphoïde"
205 = "Leucémie myéloide"
206 = "Leucémie monocytaire"
207 = "Autres leucémies précisées"
208 = "Leucémies à cellules non précisées"
210 = "Tumeur bénigne de la lèvre, de la cavité buccale et du pharynx"
211 = "Tumeurs bénignes d'autres parties de l'appareil digestif"
212 = "Tumeur bénigne de l'appareil respiratoire et des organes thoraciques"
213 = "Tumeur bénigne des os et du cartilage articulaire"
214 = "Lipome"
215 = "Autres tumeurs bénignes du tissu conjonctif et des autres tissus mous"
216 = "Tumeur bénigne de la peau"
217 = "Tumeur bénigne du sein"
218 = "Léiomyome utérin"
219 = "Autres tumeurs bénignes de l'utérus"
220 = "Tumeur bénigne de l'ovaire"
221 = "Tumeur bénigne des autres organes génitaux de la femme"
222 = "Tumeur bénigne des organes génitaux de l'homme"
223 = "Tumeur bénigne du rein et des autres organes urinaires"
224 = "Tumeur bénigne de l'œil"
225 = "Tumeur bénigne de l'encéphale et des autres parties du système nerveux"
226 = "Tumeur bénigne du corps thyroïde"
227 = "Tumeur bénigne d'autres glandes endocrines et structures apparentées"
228 = "Hémangiome et lymphangiome, tout siège"
229 = "Tumeurs bénignes de sièges autres et non précisés"
230 = "Carcinome in situ de l'appareil digestif"
231 = "Carcinome in situ de l'appareil respiratoire"
232 = "Carcinome in situ de la peau"
233 = "Carcinome in situ du sein et de l'appareil génito-urinaire"
234 = "Carcinome in situ de sièges autres ou non précisés"
235 = "Tumeurs à évolution imprévisible des appareils digestif et respiratoire"
236 = "Tumeurs à évolution imprévisible de l'appareil génito-urinaire"
237 = "Tumeurs à évolution imprévisible des glandes endocrines et du système nerveux"
238 = "Tumeurs à évolution imprévisible de sièges et tissus autres et non précisés"
;
run;

data STU.DM_HISTO_FAMILIAL;
retain &ordervar_g;
set A_temp A_temp_2;
format ZNPCANC  ZNPCANC2 localisa.;
run;

%suppr(A_temp);
%suppr(A_temp_2);


data STU.DM_QUALQUEST;
retain &ordervar;
set incl.Qalqest_evalquest;
run;


/* Tables de Curage */

data curage1;
set INCL.Ecoimop_cur_gangli;
format CUZNIM $50.;
rename CUZNIM=zone
CUIMDROIT=CUdroit
CUIMGCH=CUGAUCHE;
where CUZNIM NE ""; /* PGU : à decommenter pe ? AM : fait*/
run;

data curage2;
set INCL.Econim_curage_gan1;
format CURZON $50.;
rename CURZON=zone
CURDROIT=CUdroit
CURGCH=CUGAUCHE;
where CURZON NE "";
run;


data curage3;
set suiv.Tvnimreci_nvcur1;
format NVCYSZNCUR $50.;
rename NVCYSZNCUR=zone
NVCYSCURDR=CUdroit
NVCYSCURGH=CUGAUCHE;
where NVCYSZNCUR NE "";
run;


data curage4;
set SUIV.Tvnimprogcys_cu1;
format CUZNIM $50.;
rename CUZNIM=zone
CUIMDROIT=CUdroit
CUIMGCH=CUGAUCHE;
where CUZNIM NE "";
run;


* CURAGE GANGLIONAIRE: Fusion des 4 tables de CURAGE;
data STU.CL_CURAGE;
retain &ordervar_g;
length zone $50.;
format CUdroit CUGAUCHE CURDROITINCL.;
set curage1 curage2 curage3 curage4;
if ESSAI="COBINC" then visitname="inclusion";
format  CUDROIT CUGAUCHE CUIMDROITINCL.;
run;
proc sort; by anumpat ESSAI nbvisit CRFTITLE repeatnumber;run;
%suppr(curage1);
%suppr(curage2);
%suppr(curage3);
%suppr(curage4);


/* Planning de suivi */


/* Tables diverses */

* Créer des versions allégées de plusieurs tables de suivi dans STU;

data STU.dm_TABAC_SUIVI;
retain &ordervar;
set SUIV.Qproftabac;
drop SITPRO SITPROP REVBRUT REVB FORMU ERRBRA VFORM	NUMLIGN	CCDSVPRE TPVISIT CCNEPASREM CCDSUIVI CCBRA AAGE CCCENT ASEXE DESAC DDONAVA;
if MODEREMPL=. and DJFUME=. and REVMENS=. and REVAN=. then delete;
run;
proc sort; by anumpat ESSAI nbvisit CRFTITLE ;run;


data STU.dm_PROFESSION_SUIVI;
retain &ordervar;
set SUIV.Qproftabac;
keep essai site anumpat visitname visitcyclenumber crftitle crfpagecyclenumber CRFPAGESTATUS nbvisit BRA SITPRO SITPROP REVBRUT;
if SITPRO=. and REVBRUT=. then delete;
run;


data STU.dm_ARET_SUIVI;
retain &ordervar_g;
set SUIV.Qproftabac_aret1;
if DARETRAV=. and DDEBTRAV=. then delete;
drop ACTIV20;
run;



data atest ;
retain &ordervar;
length IDESSAI $50.;
set incl.descpat;
keep essai site anumpat visitname visitcyclenumber crftitle crfpagecyclenumber  CRFPAGESTATUS  nbvisit BRA ETCLIN IDESSAI EUDRACTCAR;
run;


DATA stu.ST_AUTRE_ETUDE;
retain &ordervar;
length IDESSAI $50.;
set suiv.Acsuiviact atest;
essai="COBSUIVI";
keep essai site anumpat visitname visitcyclenumber crftitle crfpagecyclenumber CRFPAGESTATUS nbvisit BRA DACTSUIVI ETCLIN IDESSAI EUDRACTCAR EUDRACTP1 EUDRACTP2 EUDRACTP3;
run;
proc sort; by anumpat nbvisit;run;

%suppr(atest);
