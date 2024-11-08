%global git_macro_version git_macro_version_date;
%let git_macro_version = 1.0.0;
%let git_macro_version_date = 08/11/2024;

%if %symexist(path)= 0  or %symexist(local_folder)= 0  %then %do;
    %put ERROR: Macros SBE: la macrovariable "path" et "local_folder" doit être déclarée;
%end;
%else %do;
    %include "&path/&local_folder./Import&mapping/01_import des libname oracle.sas";
%end;


%macro Run_mapping(update=0);
%if %symexist(path)= 0  or %symexist(local_folder)= 0  %then %do;
    %put ERROR: Macros SBE: la macrovariable "path" et "local_folder" doit être déclarée;
%end;
%else %do;
%if &update %then %do;
%include "&path/&local_folder./Import&mapping/02_copie des tables et format_label.sas";
%include "&path/&local_folder./Import&mapping/03_ mapping des tables simple.sas";
%include "&path/&local_folder./Import&mapping/04_mapping demographie.sas";
%include "&path/&local_folder./Import&mapping/05_mapping de la partie clinique.sas";
%include "&path/&local_folder./Import&mapping/06_mapping imagerie.sas";
%include "&path/&local_folder./Import&mapping/07_mapping RTUV.sas";
%include "&path/&local_folder./Import&mapping/08_mapping cystectomie.sas";
%include "&path/&local_folder./Import&mapping/09_ mapping hospi.sas";
%include "&path/&local_folder./Import&mapping/10_mapping chimio.sas";
%include "&path/&local_folder./Import&mapping/11_mapping analyse biologique.sas";
%include "&path/&local_folder./Import&mapping/12_mapping anapath.sas";
%include "&path/&local_folder./Import&mapping/13_mapping  metastase.sas";
%include "&path/&local_folder./Import&mapping/14_Liste des chirurgies.sas";
%include "&path/&local_folder./Import&mapping/15_table resume.sas";
%include "&path/&local_folder./Import&mapping/16_planing_etude.sas";
%end;
%else %do;

OPTION FMTSEARCH =  ( stu   format LIBRARy) ; 


%Getlib(incl,&path/DB/incl);			  
%Getlib(stu,&path/DB/stu);		
%Getlib(suiv,&path/DB/suiv);		
%Getlib(rel,&path/DB/rel);		
%Getlib(anap,&path/DB/anap);	

%end;
%end;
%mend;

