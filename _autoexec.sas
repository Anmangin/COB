%global git_macro_version git_macro_version_date;
%let git_macro_version = 1.0.0;
%let git_macro_version_date = 08/11/2024;

%if %symexist(dir_path)= 0  or %symexist(local_folder)= 0  %then %do;
    %put ERROR: Macros SBE: la macrovariable "dir_path" et "local_folder" doit être déclarée;
%end;
%else %do;
    %include "&dir_path/&local_folder./Import&mapping/01_import des libname oracle.sas";
%end;


%macro Run_mapping;
%include "&dir_path/&local_folder./Import&mapping/02_copie des tables et format_label.sas";
%include "&dir_path/&local_folder./Import&mapping/03_ mapping des tables simple.sas";
%include "&dir_path/&local_folder./Import&mapping/04_mapping demographie.sas";
%include "&dir_path/&local_folder./Import&mapping/05_mapping de la partie clinique.sas";
%include "&dir_path/&local_folder./Import&mapping/06_mapping imagerie.sas";
%include "&dir_path/&local_folder./Import&mapping/07_mapping RTUV.sas";
%include "&dir_path/&local_folder./Import&mapping/08_mapping cystectomie.sas";
%include "&dir_path/&local_folder./Import&mapping/09_ mapping hospi.sas";
%include "&dir_path/&local_folder./Import&mapping/10_mapping chimio.sas";
%include "&dir_path/&local_folder./Import&mapping/11_mapping analyse biologique.sas";
%include "&dir_path/&local_folder./Import&mapping/12_mapping anapath.sas";
%include "&dir_path/&local_folder./Import&mapping/13_mapping  metastase.sas";
%include "&dir_path/&local_folder./Import&mapping/14_Liste des chirurgies.sas";
%include "&dir_path/&local_folder./Import&mapping/15_table resume.sas";
%include "&dir_path/&local_folder./Import&mapping/16_planing_etude.sas";
%mend;
