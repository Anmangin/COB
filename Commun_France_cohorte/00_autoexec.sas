 %include "&pathprog/01_import des libname oracle.sas";


%macro Run_mapping(update=0);
%if &update %then %do;

%include "&pathprog/02_copie des tables et format_label.sas";
%include "&pathprog/15_table resume.sas";
%include "&pathprog/03_ mapping des tables simple.sas";
%include "&pathprog/04_mapping demographie.sas";
%include "&pathprog/05_mapping de la partie clinique.sas";
%include "&pathprog/06_mapping imagerie.sas";
%include "&pathprog/07_mapping RTUV.sas";
%include "&pathprog/08_mapping cystectomie.sas";
%include "&pathprog/09_ mapping hospi.sas";
%include "&pathprog/10_mapping chimio.sas";
%include "&pathprog/11_mapping analyse biologique.sas";
%include "&pathprog/12_mapping anapath.sas";
%include "&pathprog/13_mapping  metastase.sas";
%include "&pathprog/14_Liste des chirurgies.sas";

%include "&pathprog/16_planing_etude.sas";
%end;
%else %do;

OPTION FMTSEARCH =  ( stu   format LIBRARy) ; 


%Getlib(incl,&path/load/incl);			  
%Getlib(stu,&path/load/stu);		
%Getlib(suiv,&path/load/suiv);		
%Getlib(rel,&path/load/rel);		
%Getlib(anap,&path/load/anap);	


%end;
%mend;

