*Liste des macrovariables a paramétrer : path;
* Nom du fichier pour trouver le path;
%let path=\\Nas-01\sbe_etudes\COBLANCE\11-DataBase\Nouvelle methode de travail;

* Getlib : crée un dossier et le place en libname;
%macro Getlib(nom,dossier);option NOXWAIT;x mkdir "&dossier.";libname &nom "&dossier.";%mend;


OPTION FMTSEARCH =  ( stu   format LIBRARy) ; 

%Getlib(incl,&path\DB\incl);
%Getlib(suiv,&path\DB\suiv);
%Getlib(anap,&path\DB\anap);
%Getlib(stu,&path\DB\stu);			  

