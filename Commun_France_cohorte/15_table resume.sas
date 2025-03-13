

/*------------------------ etape 3 début de la mapping de stu ------------------------------	 ;
  */
%macro DELETEformat(LIBNAME,table,var,format);
data &table;
set &LIBNAME..&table;
var2=put(&var,&format..);
drop &var;
run;
data &table;
set &table;
format &var $100.;
&var=var2;
drop var2;
run;
%mend;




Proc sql noprint;
create table stu.resume as
select a.anumpat,a.nbvisit,a.centre,a.SITE AS trialsite,a.SEXE,a.DNAIS,DINTRW, TPBRA as BRA_INCL, IDENBRA.DINCL as DINCL,FUME,CRITINC , NSDDC
,CAUSDC,SORTETU,DSORTETU,MOTIFSORTI,MOTIFP,PDV,PDVDATE,PDVCOMMENT,DNN,DDN_C
FROM INCL.DEMOGR a
left join INCL.Idenbra b on a.anumpat=b.anumpat 
left join INCL.Descpat c on a.anumpat=c.anumpat 
left join INCL.Econim  d on a.anumpat=d.anumpat 
left join INCL.Ecoimop e on a.anumpat=e.anumpat 
left join INCL.F_tabac f on a.anumpat=f.anumpat 
left join INCL.TRAITINC g on a.anumpat=g.anumpat 
left join INCL.Ecoimtr h on a.anumpat=h.anumpat 
left join SUIV.planing  on DEMOGR.anumpat= planing.anumpat
where demogr.anumpat NE "" and demogr.anumpat NE "personne non identifiee"
ORDER BY anumpat;
quit;
