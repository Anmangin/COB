data tnm_all_incl; set stu.an_tnm_all; where v ne 2 and v ne 5;run;
proc sql noprint; create table max_t as select distinct anumpat, max(TF) as max_TF format=t.  from tnm_all_incl  group by anumpat  ; quit;


%let patdiverge=none;
proc sql noprint;  select a.anumpat into:patdiverge SEPARATED BY '/'  from stu.an_tnm_incl a left join max_t b on a.anumpat=b.anumpat where max_TF NE TF;quit;
%let ListWrongTVNIM=none;
%let ListWrongTVIM=none;
proc sql noprint; select a.anumpat into:ListWrongTVIM SEPARATED BY '/'  from stu.resume a left join stu.an_tnm_incl b on a.anumpat=b.anumpat where BRA_INCL=1 and TF<6;quit;
proc sql noprint; select a.anumpat into:ListWrongTVNIM SEPARATED BY '/'  from stu.resume a left join stu.an_tnm_incl b on a.anumpat=b.anumpat where BRA_INCL>1 and TF>6;quit;

%put  NOTE:warning Nombre d erreur detecté dans les T : &patdiverge;
%put  NOTE:Liste des TVIM qui n ont pas un T concordant : &ListWrongTVIM;
%put  NOTE:Liste des TVNIM qui n ont pas un T concordant : &ListWrongTVNIM;

%macro check_exclu(table);
%let PATEXL=0;
proc sql noprint ;select distinct a.anumpat  into:PATEXL SEPARATED BY '/' from stu.Et_exclusion a left join &table b  on a.anumpat=b.anumpat where DEXCL NE . and b.anumpat NE "";quit;
%put NOTE:&PATEXL patient trouvé dans la table &table;
%mend;

%check_exclu(stu.Cl_tvnim);
%check_exclu(stu.dm_tabac);
%check_exclu(stu.An_rtuv);
%check_exclu(stu.Qlq_bls24);

%macro print_visits;
    %local i count;
    %let count = %sysfunc(countw(&VISITWRONG, '*'));

    %put NOTE: Liste des visites non récidive avec chimio : ;
    %do i = 1 %to &count;
        %put %scan(&VISITWRONG, &i, '*');
    %end;
%mend;

PROC SQL NOPRINT;
    SELECT DISTINCT cats(anumpat, "_bras:", put(bra, TPBRAINCL.), "_visite ", NBVISIT)  
    INTO :VISITWRONG SEPARATED BY '*'  
    FROM stu.cl_chimio_trt  
    WHERE v NE 9 AND essai = "COBSUIV";  
QUIT;

%print_visits;

%let ordervar= essai site  anumpat  NBVISIT    bra  vnf v vpla crftitle crfpagecyclenumber CRFPAGESTATUS;
%let ordervar_g= essai site  anumpat  NBVISIT    bra  vnf v vpla recidive crftitle crfpagecyclenumber repeatnumber CRFPAGESTATUS;
*01-042;
