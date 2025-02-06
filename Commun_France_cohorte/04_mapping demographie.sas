/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                  Fichier De mapping des tables de demographie

 Ce fichier permet de créer les tables mappées concernant la demographie des patients
V1 20/10/2020 -> Anthony M
V2 06/09/2023 -> Anthony M et Pierre G revu pour France Cohorte

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

* PRE-REQUIS: 02_copie des tables et format_label.sas doit avoir été lancé;

* Table resumant les critères principaux des patients de l'étude;

/* calcul de la première chir */

* Table de fusion de toutes les tables de démographie des patients non exclus;


proc sql nowarn noprint;
create  table STU.demographie as
select * from INCL.DEMOGR 
LEFT JOIN incl.Idenbra ON DEMOGR.anumpat=Idenbra.anumpat
LEFT JOIN INCL.F_tabac ON DEMOGR.anumpat=F_tabac.anumpat 
LEFT JOIN INCL.CONSALIM ON DEMOGR.anumpat=CONSALIM.anumpat 
LEFT JOIN INCL.ACTIPHYS ON DEMOGR.anumpat=ACTIPHYS.anumpat
LEFT JOIN INCL.GYNECO ON DEMOGR.anumpat=GYNECO.anumpat 
LEFT JOIN INCL.HISTOSANTE ON DEMOGR.anumpat=HISTOSANTE.anumpat  
LEFT JOIN INCL.HISTOSANTE3 ON DEMOGR.anumpat=HISTOSANTE3.anumpat
LEFT JOIN INCL.HFAMPARNT2 ON DEMOGR.anumpat=HFAMPARNT2.anumpat 
LEFT JOIN INCL.Qalqest ON DEMOGR.anumpat=Qalqest.anumpat
left join SUIV.planing  on DEMOGR.anumpat= planing.anumpat
WHERE DEMOGR.anumpat NE "" and DEMOGR.anumpat NE "personne non identifiee"
ORDER BY anumpat;
quit;
proc sort nodupkey;by anumpat;run;

* Créer une autre version de la table demographie avec moins de variables;
data STU.DM_demographie;
retain &ordervar;
set STU.demographie;
drop PRVROUGE HTBCENFP HTBCADP ANTBCADP HTBPROP ANTBCPROP DDONTIM FORMU CCMORTNE CCFC CCEXUT CCIVG CCIMG HINTRWDB AGE IDCENT 
REVAN REVMENS MONAIS ANNAIS CENTRE REVB CCCENT IDCOB CENT IDPAT	ASEXE AAGE COBCALC;
run;
%suppr(STU.demographie);
