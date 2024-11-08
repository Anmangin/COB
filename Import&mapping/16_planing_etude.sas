
*Créer une table du planning de suivi allégée;
/*
1- ajouter l'inclusion
2- ajouter les chir et les chimio 
3- ajouter les qlq ?
*/
data STU.ET_planing;
set suiv.Planing_planing1;
format VNF 1.;
drop VISITNAME  CCDROP DVSTTHEO CCBRAS CCVSTPRE;
run;
proc sort; by anumpat ESSAI nbvisit CRFTITLE repeatnumber;run;
