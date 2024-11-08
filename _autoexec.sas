%global git_macro_version git_macro_version_date;
%let git_macro_version = 0.0.0;
%let git_macro_version_date = 07/07/2020;

%if %symexist(dir_path)= 0  or %symexist(local_folder)= 0  %then %do;
    %put ERROR: Macros SBE: la macrovariable "dir_path" et "local_folder" doit être déclarée;
%end;
%else %do;
    %include "&dir_path/&local_folder./PROG/1 - Importation.sas";
    %include "&dir_path/&local_folder./PROG/2 - Relance.sas";
    %include "&dir_path/&local_folder./PROG/4 - imprimer relance.sas";
    %include "&dir_path/&local_folder./PROG/98 - ISO_Metrics.sas";
%end;
