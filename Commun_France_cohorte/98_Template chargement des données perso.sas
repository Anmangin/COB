option mprint=no;
%let daterep=%sysfunc(today(),date8.);
%let datetemp=%sysfunc(today(),yymmdd9.);
data _null_;test=strip("&datetemp");datefileL=tranwrd(test,"-",".");call symputx('datefile',datefileL);run;

%put &daterep;
%put &datefile;
%let serveur_path=\\nas-01;
%let path_prog=&serveur_path.\SBE_ETUDES\COBLANCE\11-DataBase\Mapping France Cohorte\Commun_France_cohorte;
%let pathRAW=C:\Users\a_mangin\Documents\DATABASE\RAW;
/* définit l'endroit de stockage de la base locale de travail. A personnaliser*/

%let date_chargement=&datefile;
%let path=C:\Users\a_mangin\Documents\DATABASE\COBLANCE;
option NOXWAIT;x mkdir "&path";


%MACRO suppr(table);proc sql noprint; Drop Table &table;quit;%mend;
%macro vider(lib);
data nomtable ;set sashelp.vstable;where libname=upcase("&lib.");
if memname='TIMEDOWN' or memname='timedown' or memname="nomtable"  or memname="META_comment" then delete;
run;

proc sql noprint;select distinct count(*) into: nbtable from nomtable; quit;
%do i=1 %to &nbtable.;
data _null_ ;set nomtable; if _N_=&i then call symput("memname",memname) ; run;
%suppr(&lib..&memname.);
%end;
%mend;

%vider(stu);
%include "&path_prog\01_import des libname oracle.sas";


/*  valide */
%include "&path_prog\02_copie des tables et format_label.sas";
%include "&path_prog\03_ mapping des tables simple.sas";
%include "&path_prog\04_mapping demographie.sas";
%include "&path_prog\05_mapping de la partie clinique.sas";
%include "&path_prog\06_mapping imagerie.sas";
%include "&path_prog\07_mapping RTUV.sas";
%include "&path_prog\08_mapping cystectomie.sas";
%include "&path_prog\09_ mapping hospi.sas";
%include "&path_prog\10_mapping chimio.sas";
%include "&path_prog\11_mapping analyse biologique.sas";
%include "&path_prog\12_mapping anapath.sas";
%include "&path_prog\13_mapping  metastase.sas";
%include "&path_prog\14_Liste des chirurgies.sas";
%include "&path_prog\15_table resume.sas";
%include "&path_prog\16_planing_etude.sas";
