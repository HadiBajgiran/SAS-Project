
	

%let path=C:\Users\Admin\OneDrive\Documents\Logiciel statistique\DATA_SAS;

libname stop "&path.";

data data;
	set stop.data_2021;
run;

*QUESTION-1;

data Temp;
set data;
keep STOP_ID STOP_FRISK_DATE STOP_FRISK_TIME STOP_DURATION_MINUTES FRISKED_FLAG 
SEARCHED_FLAG WEAPON_FOUND_FLAG SUSPECT_REPORTED_AGE SUSPECT_SEX SUSPECT_RACE_DESCRIPTION;
run;

/*Le type de chacune des variables contenues dans la table Temp*/

proc contents data=Temp ;
run;


*QUESTION-2;

/*question 2-A*/
data Temp2;
  set Temp;
  annee = input(substr(STOP_FRISK_DATE,1,4),8.);
  mois = input(substr(STOP_FRISK_DATE,6,2),8.);
  jour = input(substr(STOP_FRISK_DATE,9,2),8.);
  date_arret = mdy(mois, jour, annee);
  format date_arret yymmdd10.;
label date_arret="Date de l’arrestation";

/*question 2-B*/
heure_arret = input(substr(STOP_FRISK_TIME,1,2),8.);
label heure_arret="L’heure de l’arrestation";

/*question 2-C*/
if heure_arret<12 then Quart_jour="AM"; else Quart_jour="PM";

/*question 2-D*/
if FRISKED_FLAG="Y" then Frisked=1; else Frisked=0;
if SEARCHED_FLAG="Y" then Searched=1; else Searched=0;
if SEARCHED_FLAG="Y" and FRISKED_FLAG="Y" then FS=1; else FS=0;
if WEAPON_FOUND_FLAG="Y" then Arme=1; else Arme=0;

/*question 2-E*/
  age_car =substr(SUSPECT_REPORTED_AGE,1,2);/*choisir les deux premiers caractères de age*/
if age_car="(n" then age_car="0"; /*mettre les données manquantes egale a zero*/
age_num=input(age_car,3.); /*changer variable de caractère a numerique*/
if age_num= 0 then age_cat="Missing"; /*nous avons crée une catégorie missing*/
else if age_num<15 then age_cat="1"; 
else if age_num<25 then age_cat="2";
else if age_num<35 then age_cat="3";
else if age_num<45 then age_cat="4";
else if age_num<55 then age_cat="5";
else if age_num<65 then age_cat="6";
else age_cat="7";
drop age_car age_num;/*drop les deux variables supplémentaires en sortir*/

/*question 2-F*/
where SUSPECT_RACE_DESCRIPTION ^= "(null)";
run;


*QUESTION-3;

/*question 3-i*/
Title1 "Le nombre de femmes arrêtées en 2021";
proc means data=Temp2 N nway missing nonobs ;
class SUSPECT_SEX;
var STOP_ID;
output out=femme_arret (drop = _STAT_ _FREQ_ _TYPE_);
where SUSPECT_SEX="FEMALE";
run;
title;

/*question 3-ii*/
Title1 "Le nombre d’arrestations par race identifiée";
proc means data=Temp2 N nway missing nonobs ;
class SUSPECT_RACE_DESCRIPTION;
var STOP_ID;
output out=race_arret (drop = _STAT_ _FREQ_ _TYPE_);
where SUSPECT_RACE_DESCRIPTION ^= "(null)";
run;
title;

/*question 3-iii*/
Title1 "Le nombre total d’arrestations par mois";
data data5;
  set Temp2;
  mois = input(substr(STOP_FRISK_DATE,6,2),8.);
  run;
proc means data=data5 N nway missing nonobs ;
class mois;
var STOP_ID;
output out=mois_arret (drop = _STAT_ _FREQ_ _TYPE_);
run;
title;

/*question 3-iv*/
Title1 "La durée moyenne d’une arrestation (en minutes) par quart de jour";
data data5;
  set Temp2;
  heure_arret = input(substr(STOP_FRISK_TIME,1,2),8.);
if heure_arret<12 then Quart_jour="AM"; else Quart_jour="PM";
  run;
proc means data=data5 mean nway missing nonobs ;
class Quart_jour;
var STOP_DURATION_MINUTES;
output out=mean_arret (drop = _STAT_ _FREQ_ _TYPE_);
run;
title;


*QUESTION-4;

/* nommer les valeurs de variable arme comme "Aucune_arme" et "Arme_Found"*/
Data data4;
set Temp;
if WEAPON_FOUND_FLAG="Y" then Arme="Arme_Found"; else Arme="Aucune_Arme";
where SUSPECT_RACE_DESCRIPTION ^= "(null)";
run;

Proc freq data=data4; 
table SUSPECT_RACE_DESCRIPTION*Arme/norow nocol nopercent 
Out=TableB;
run;

/*question 4-vi   ----   Trier la TableB  */
proc sort data=TableB; by SUSPECT_RACE_DESCRIPTION; run;

/*question 4-vii      ----   Transposer la TableB */
Proc transpose data = TableB 
out =TableC (drop = _NAME_ _LABEL_);  
by SUSPECT_RACE_DESCRIPTION; 
id Arme; 
var count; 
run;


*QUESTION-5;
data dat;
	set stop.Full_adress_2021;
run;

data Temp3 (keep = STOP_ID Distric);
set dat;
position_deb=index(FULL_ADRESS, "(");
position_fin=index(FULL_ADRESS, ")");
Distric=substrn(FULL_ADRESS,position_deb+1, position_fin-position_deb-1);
run;

*QUESTION-6;
Proc freq data=Temp3 noprint; 
table Distric/norow nocol 
Out=FD;
run;
data Freq_district (drop = PERCENT);
set FD;
label COUNT="Nombre d’Arrestations";
a=PERCENT/100; format a PERCENT8.2;
label a="Pourcentage du Total";
run;


*QUESTION-7;
proc sort data=Temp2; by STOP_ID; run;
proc sort data=Temp3; by STOP_ID; run;

data All_2021;
    merge Temp2 (in=a)/*Table de gauche*/
          Temp3 (in=b) /*Table de droite*/;
    by STOP_ID;* La clé de jointure;
    if a and b then output All_2021; * jointure stricte ou jointure interne: intersection des éléments en commun;
run;

*QUESTION-8;
/*question 8-i*/
proc summary data= All_2021 nway missing;
class Distric mois;
var FS;
output out=AG_F (Drop= _TYPE_ _FREQ_)
	sum=;
run;

proc transpose data= AG_F out=Ag_Trans(Drop= _NAME_);
by Distric;
id mois;
var FS;
run;

data AG_FS;
set Ag_Trans;
label _1="JANVIER"; label _2="FEVRIER"; label _3="MARS"; 
label _4="AVRIL"; label _5="MAI"; label _6="JUIN"; 
label _7="JUILLET"; label _8="AOUT"; label _9="SEPTEMBRE";
label _10="OCTOBRE"; label _11="NOVEMBRE"; label _12="DECEMBRE";
run;

/*question 8-ii*/
proc means data= All_2021 nway missing noprint;
class mois Distric ;
var FS;
output out=AG_F2 (Drop= _TYPE_ _FREQ_)
	sum=;
run;

proc transpose data= AG_F2 out=Ag_FS2(Drop= _NAME_);
by mois;
id Distric;
var FS;
run;





