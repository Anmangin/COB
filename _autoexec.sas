%global git_macro_version git_macro_version_date;
%let git_macro_version = 1.0.0;
%let git_macro_version_date = 08/11/2024;

%if %symexist(path)= 0  or %symexist(local_folder)= 0  %then %do;
    %put ERROR: Macros SBE: la macrovariable "path" et "local_folder" doit être déclarée;
%end;
%else %do;
    %include "&path/Import/01_import des libname oracle.sas";
%end;


%macro Run_mapping(update=0);
%if %symexist(path)= 0  or %symexist(local_folder)= 0  %then %do;
    %put ERROR: Macros SBE: la macrovariable "path" et "local_folder" doit être déclarée;
%end;
%else %do;
%if &update %then %do;
%include "&path/Import/02_copie des tables et format_label.sas";
%include "&path/Import/03_ mapping des tables simple.sas";
%include "&path/Import/04_mapping demographie.sas";
%include "&path/Import/05_mapping de la partie clinique.sas";
%include "&path/Import/06_mapping imagerie.sas";
%include "&path/Import/07_mapping RTUV.sas";
%include "&path/Import/08_mapping cystectomie.sas";
%include "&path/Import/09_ mapping hospi.sas";
%include "&path/Import/10_mapping chimio.sas";
%include "&path/Import/11_mapping analyse biologique.sas";
%include "&path/Import/12_mapping anapath.sas";
%include "&path/Import/13_mapping  metastase.sas";
%include "&path/Import/14_Liste des chirurgies.sas";
%include "&path/Import/15_table resume.sas";
%include "&path/Import/16_planing_etude.sas";
%end;
%else %do;

OPTION FMTSEARCH =  ( stu   format LIBRARy) ; 


%Getlib(incl,&path/load/incl);			  
%Getlib(stu,&path/load/stu);		
%Getlib(suiv,&path/load/suiv);		
%Getlib(rel,&path/load/rel);		
%Getlib(anap,&path/load/anap);	

%end;
%end;
%mend;

