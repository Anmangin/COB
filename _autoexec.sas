%global git_macro_version git_macro_version_date;
%let git_macro_version = 1.0.0;
%let git_macro_version_date = 08/11/2024;

%if %symexist(dir_path)= 0  or %symexist(local_folder)= 0  %then %do;
    %put ERROR: Macros SBE: la macrovariable "dir_path" et "local_folder" doit être déclarée;
%end;
%else %do;
    %include "&dir_path/&local_folder./Import&mapping/01_import des libname oracle.sas";
%end;
