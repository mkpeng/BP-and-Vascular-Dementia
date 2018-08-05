----------------------
---This study use THIN database to examine the effect of midlife and latelife blood pressure
---on the development of dementia including Alzheimer disease (AD) and Vascular dementia (VD)
----------------------

----------- Define the study population
-- This analysis extract all the BP measurement within the age range of 45 to 75.
-- then create the variable of bp_status to determine the blood pressure status at two age groups: 40 to 65, 66 to 75.
-- then study the impact of blood pressure on the dementia: all type, AD, VD.

-----------	Get all the BP measurement for patients with the age range of 40 to 65;
--- Extract the BP measurement
---- Identify all the patient with valid records, such as regdate > yobyear,...
Create table temp_all_cases as select combid, cast(yobyear as int) as yobyear, sex,
  regstat,cast(concat_ws('-', regdateyear,regdatemonth, regdateday)as date) as regdate,
  cast(concat_ws('-',deathdateyear,deathdatemonth,deathdateday)as date) as deathdate,
  cast(concat_ws('-',xferdateyear,xferdatemonth,xferdateday) as date) as xferdate
  from thin1205.patient where patflag in ('A','C');
Create table temp_1 as select combid,yobyear,sex,regstat,regdate,
  case when deathdate is null then cast('2012-05-14' as date) else deathdate end as deathdate,
  case when xferdate is null then cast('2012-05-14' as date) else xferdate end as xferdate
  from temp_all_cases where regstat in ('02','05','99');
Create table temp_2 as select combid, yobyear,sex,regstat, regdate, deathdate,xferdate
  from temp_1 where year(regdate) >= yobyear and deathdate> regdate and xferdate > regdate
  and sex in ('1','2');
Create table temp_3 as select combid, yobyear,sex,regstat,regdate,deathdate, xferdate,
  case when deathdate >=xferdate then xferdate else deathdate end as exitdate from temp_2;

----- Find all the blood pressure measurement
Create table temp_8 as select combid,
  cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as ahd_date,
  cast(data1 as int) as diastolic,cast(data2 as int) as systolic
  from thin1205.ahd where ahdcode='1005010500';
-- Set the valid range of blood pressure measurement
Create table temp_9 as select * from temp_8 where
ahd_date is not null and systolic is not null and diastolic is not null
and systolic > diastolic and diastolic >30 and diastolic <200 and systolic >50 and systolic <300;

--- Take the average of BP measurement recorded on the same day
Create table temp_9_1 as select combid, ahd_date, avg(diastolic) as diastolic,
  avg(systolic) as systolic from temp_9 group by combid, ahd_date;

Create table temp_9_2 as select a.combid, a.yobyear,a.regdate, b.ahd_date,
  b.diastolic, b.systolic from  temp_3 a left outer join temp_9_1 b
  on a.combid=b.combid;

-------------- Create the midife and latelife cohort
drop table temp_9_2_40to65
drop table temp_9_2_40to65_1

create table temp_9_2_40to65 as select *,year(ahd_date)-yobyear as age_measurement
  from temp_9_2 where year(ahd_date)-yobyear > 39 and year(ahd_date) - yobyear < 76;
create table temp_9_2_40to65_1 as select *, year(ahd_date) as year_measurement,
  case when age_measurement > 39 and age_measurement < 66 then "midlife"
   when age_measurement > 65 and age_measurement < 76 then "latelife" end as life_age
   from temp_9_2_40to65;

drop table midlife_1;
drop table midlife_1_1;
drop table midlife_1_3;
drop table midlife_1_4;


--- Create the index date of follow-up,
--- calculate the yearly average blood pressure, average of pulse_bp

----- Midlife
create table midlife_1 as select combid,life_age,yobyear,year_measurement,
  count(distinct year_measurement) as count, max(ahd_date) as ahd_date,
  round(avg(diastolic),1) as diastolic,round(avg(systolic),1) as systolic,
  round(avg(systolic - diastolic),1) as pulse_bp
  from temp_9_2_40to65_1 where life_age="midlife" and yobyear < 1938
  group by combid,life_age,yobyear,year_measurement;

create table midlife_1_1 as select combid, count(distinct year_measurement) as count,
  min(ahd_date) as ahd_date_min, max(ahd_date) as ahd_date,
round(avg(diastolic),1) as diastolic,round(avg(systolic),1) as systolic,
round(avg(pulse_bp),1) as pulse_bp,count(distinct year(ahd_date)) as year_count
from midlife_1 group by combid;

-------------------------------	years of bp measurement, years with BP measurement
create table midlife_1_3 as select *,year(ahd_date)- year(ahd_date_min) +1 as Year_measurements
  from midlife_1_1;
create table midlife_1_4 as select *,year_count/year_measurements as rate_m from midlife_1_3;

------------------------------- latelife
drop table latelife_1;
drop table latelife_1_1;
drop table latelife_1_3;
drop table latelife_1_4;


------------	Create the index date of follow-up, calculate the yearly average blood pressure, average of pulse_bp

create table latelife_1 as select combid,life_age,yobyear,year_measurement,
  count(distinct year_measurement) as count, max(ahd_date) as ahd_date,
  round(avg(diastolic),1) as diastolic,round(avg(systolic),1) as systolic,
  round (avg(systolic - diastolic),1) as pulse_bp
  from temp_9_2_40to65_1 where life_age="latelife" and yobyear < 1928
  group by combid,life_age,yobyear,year_measurement;

create table latelife_1_1 as select combid, count(distinct year_measurement) as count,
  min(ahd_date) as ahd_date_min, max(ahd_date) as ahd_date,
  round(avg(diastolic),1) as diastolic,round(avg(systolic),1) as systolic,
  round(avg(pulse_bp),1) as pulse_bp,count(distinct year(ahd_date)) as year_count
  from latelife_1 group by combid;

-------------------------------	years of bp measurement, years with BP measurement, Pluse BP
create table latelife_1_3 as select *,year(ahd_date)- year(ahd_date_min) +1 as Year_measurements
  from latelife_1_1;
create table latelife_1_4 as select *,year_count/year_measurements as rate_m from latelife_1_3;
-------------------------------



--------------------------	Extract the outcome and morbidities using the READ codes
drop table midlife_2_1;
drop table midlife_2_2;
drop table midlife_2_3;
drop table midlife_2_4;
drop table midlife_2_5;
drop table midlife_2_6;
drop table midlife_2_7;
drop table midlife_2_8;
drop table midlife_2_9;
drop table midlife_2_10;

drop table latelife_2_1;
drop table latelife_2_2;
drop table latelife_2_3;
drop table latelife_2_4;
drop table latelife_2_5;
drop table latelife_2_6;
drop table latelife_2_7;
drop table latelife_2_8;
drop table latelife_2_9;
drop table latelife_2_10;

-- Identify the dementia cases in THIN
Create table temp_dm as select combid, cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as medicaldate,
medcode from thin1205.medical where medcode like 'E00%' or medcode like 'Eu00%'
or medcode like 'Eu01%' or medcode like 'Eu02%'  or medcode like 'E02y1%' or medcode like 'E012%'
or medcode like  'Eu041%' or medcode like  'E041%' or medcode like  'F110%'
or medcode like  'F111%' or medcode like  'F112%' or medcode like 'F116%';

Create table temp_dm_1 as select * from temp_dm where medicaldate is not null;

-------------	Alzheimer disease
create table AD as select combid, medicaldate from temp_dm_1
  where medcode like 'F110%' or medcode like 'Eu00%';
create table AD_1 as select combid, min(medicaldate) as AD_indexdate,1 as AD from AD group by combid;

create table midlife_2_1 as select a.*,b.AD_indexdate,b.AD from midlife_1_4 a
  left outer join AD_1 b on a.combid=b.combid;
create table latelife_2_1 as select a.*,b.AD_indexdate,b.AD from latelife_1_4 a
  left outer join AD_1 b on a.combid=b.combid;

--------	Vascular dementia
create table VD as select combid, medicaldate from temp_dm_1 where medcode like 'Eu01%';
create table VD_1 as select combid, min(medicaldate) as VD_indexdate,1 as VD from VD group by combid;

create table midlife_2_2 as select a.*,b.VD_indexdate,b.VD
  from midlife_2_1  a  left outer join VD_1 b
  on a.combid=b.combid;

create table latelife_2_2 as select a.*,b.VD_indexdate,b.VD
  from latelife_2_1  a left outer join VD_1 b
  on a.combid=b.combid;

------------	All type of dementia
create table dementia as select combid, min(medicaldate) as dementia_indexdate,1 as dementia
  from temp_dm_1 where medicaldate is not null group by combid;

create table midlife_2_3 as select a.*,b.dementia_indexdate,b.dementia
  from midlife_2_2  a left outer join dementia b
  on a.combid=b.combid;

create table latelife_2_3 as select a.*,b.dementia_indexdate,b.dementia
  from latelife_2_2  a left outer join dementia b on a.combid=b.combid;
-----------		Stroke

Create table temp_stroke as select combid,
  cast(concat_ws(‘-’,eventyear,eventmonth,eventday) as date) as medicaldate, medcode
  from thin1205.medical
  where medcode like 'G61%' or medcode like 'G63y%' or medcode like 'G64%' or medcode like 'G66%' or
  medcode like 'G676%' or medcode like 'G6W%' or medcode like 'G6X%' or medcode like 'Gyu6';

Create table stroke_1 as select combid, min(medicaldate) as stroke_indexdate, 1 as stroke
from temp_stroke where medicaldate is not null group by combid;

create table midlife_2_4 as select a.*, b.stroke_indexdate,b.stroke
  from midlife_2_3 a left outer join stroke_1 b
  on a.combid=b.combid;
create table latelife_2_4 as select a.*, b.stroke_indexdate,b.stroke
  from latelife_2_3 a left outer join stroke_1 b
  on a.combid=b.combid;
-----------		Myocardial infarction
Create table temp_MI as select combid, cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as medicaldate, medcode
  from thin1205.medical where medcode like 'G30%' or medcode like 'G32%';
Create table MI_1 as select combid, min(medicaldate) as MI_indexdate, 1 as MI
from temp_MI where medicaldate is not null group by combid;

create table midlife_2_5 as select a.*, b.MI_indexdate,b.MI
  from midlife_2_4 a left outer join MI_1 b
  on a.combid=b.combid;

create table latelife_2_5 as select a.*, b.MI_indexdate,b.MI
  from latelife_2_4 a left outer join MI_1 b
  on a.combid=b.combid;
------------- diabetes
Create table temp_diabete as select combid,
cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as medicaldate, medcode
from thin1205.medical where medcode like 'C10%' or medcode like 'PKyP';

Create table diabete as select combid,min(medicaldate) as diabete_indexdate,1 as diabete
from temp_diabete where medicaldate is not null group by combid;

create table midlife_2_6 as select a.*, b.diabete_indexdate,b.diabete
  from midlife_2_5 a left outer join diabete b
  on a.combid=b.combid ;
create table latelife_2_6 as select a.*, b.diabete_indexdate,b.diabete
  from latelife_2_5 a left outer join diabete b
  on a.combid=b.combid ;

------------	Chronic kidney disease
Create table midlife_2_7 as select a.*, b. ckd_indexdate, b.ckd
  from midlife_2_6 a left outer join dm_temp_7_2 b
  on a.combid=b.combid;
Create table latelife_2_7 as select a.*, b. ckd_indexdate, b.ckd from latelife_2_6 a left outer join dm_temp_7_2 b on a.combid=b.combid;
------------	Head injury
Create table temp_head as select combid, cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as medicaldate, medcode
  from thin1205.medical where medcode like 'S0%' or medcode like 'S6%';

Create table dm_temp_8 as select combid,min(b.medicaldate) as head_indexdate, 1 as head
from temp_head where medicaldate is not null group by combid;

Create table midlife_2_8 as select a.*, b.head_indexdate, b.head
  from midlife_2_7  a left outer join dm_temp_8 b
  on a.combid=b.combid;
Create table latelife_2_8 as select a.*, b.head_indexdate, b.head
  from latelife_2_7  a left outer join dm_temp_8 b
  on a.combid=b.combid;
------------	Depression
Create table temp_depression as select combid, cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as medicaldate, medcode
from thin1205.medical where medcode like 'E112%' or medcode like 'E113%' or medcode like 'E118%' or medcode like 'E11y2%' or
medcode like 'E11z2%' or medcode like 'E130%' or medcode like 'E135%' or medcode like 'E2003%' or medcode like 'E291%' or
medcode like 'E2B%' or medcode like  'Eu204%' or medcode like  'Eu251%' or medcode like 'Eu32%' or medcode like 'Eu33%' or
 medcode like 'Eu341%' or medcode like 'Eu412%';

Create table dm_temp_5 as select combid,min(b.medicaldate) as depression_indexdate, 1 as depression
from temp_depression where medicaldate is not null group by combid;

Create table midlife_2_9 as select a.*, b.depression_indexdate, b.depression
  from midlife_2_8 a left outer join dm_temp_5 b
  on a.combid=b.combid;
Create table latelife_2_9 as select a.*,b.depression_indexdate, b.depression
  from latelife_2_8 a left outer join dm_temp_5 b
  on a.combid=b.combid;
-----------	Parkinson’s disease
Create table temp_parkinson as select combid,
  cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as medicaldate, medcode
  from thin1205.medical where medcode like 'F12%';

Create table dm_temp_6 as select combid,min(b.medicaldate) as parkinson_indexdate, 1 as parkinson
  from temp_depression where medicaldate is not null group by combid;


Create table midlife_2_10 as select a.*, b. parkinson_indexdate, b.parkinson
  from midlife_2_9 a left outer join dm_temp_6 b
  on a.combid=b.combid;
Create table latelife_2_10 as select a.*, b. parkinson_indexdate, b.parkinson
  from latelife_2_9 a left outer join dm_temp_6 b
  on a.combid=b.combid;

--------------------------------	Create the index date of followup,
drop table midlife_3;
drop table midlife_3_1;
drop table midlife_3_2;
drop table midlife_3_3;
drop table midlife_3_4;

drop table latelife_3;
drop table latelife_3_1;
drop table latelife_3_2;
drop table latelife_3_3;
drop table latelife_3_4;

----------------- extract the variable of date of birth, registration date, exit date, and sex
create table midlife_3 as select a.*,b.yobyear,b.regdate,b.exitdate,b.sex
  from midlife_2_10 a join temp_3 b on a.combid=b.combid;
create table latelife_3 as select a.*,b.yobyear,b.regdate,b.exitdate,b.sex
  from latelife_2_10 a join temp_3 b on a.combid=b.combid;

-------------	Create the variable of BP status, year_followup: the number of year before the follow_up.
create table midlife_3_2 as select combid, sex,yobyear, regdate,
  exitdate,diastolic,systolic,pulse_bp, yobyear-year(ahd_date) as year_followup,
  ahd_date_min,ahd_date, count,
  case when diastolic >=110 or systolic  >= 180 then "HTN_crisis"
  when diastolic  >=100 and diastolic  < 110 then "HTN_S2"
  when systolic  >= 160 and systolic  < 180 then "HTN_S2"
  when diastolic   >= 90 and diastolic  < 100 then "HTN_S1"
  when systolic  >= 140 and systolic  < 160 then "HTN_S1"
  when diastolic   >= 80 and diastolic  < 90 then "HTN_pre"
  when systolic  >= 130 and systolic  < 140 then "HTN_pre"
  when systolic  < 90 or diastolic  <60 then "Hypotension" else "Normal" end as BP_status,
  case when ad_indexdate is null then exitdate else ad_indexdate end as ad_indexdate,
  case when ad is null then 0 else ad end as ad,
  case when vd_indexdate is null then exitdate else vd_indexdate end as vd_indexdate,
  case when vd is null then 0 else vd end as vd,
  case when dementia is null then 0 else dementia end as dementia,
  case when dementia_indexdate is null then exitdate else dementia_indexdate end as dementia_indexdate,
  case when stroke is null then 0 else stroke end as stroke,
  case when stroke_indexdate is null then exitdate else stroke_indexdate end as stroke_indexdate,
  case when MI is null then 0 else MI end as MI,
  case when MI_indexdate is null then exitdate else MI_indexdate end as MI_indexdate,
  case when diabete is null then 0 else diabete end as diabete,
  case when diabete_indexdate is null then exitdate else diabete_indexdate end as diabete_indexdate,
  case when ckd is null then 0 else ckd end as ckd,
  case when ckd_indexdate is null then exitdate else ckd_indexdate end as ckd_indexdate,
  case when head is null then 0 else head end as head,
  case when head_indexdate is null then exitdate else head_indexdate end as head_indexdate,
  case when depression is null then 0 else depression end as depression,
  case when depression_indexdate is null then exitdate else depression_indexdate end as depression_indexdate,
  case when parkinson is null then 0 else parkinson end as parkinson,
  case when parkinson_indexdate is null then exitdate else parkinson_indexdate end as parkinson_indexdate
  from midlife_3;


create table latelife_3_2 as select combid,sex, yobyear, regdate, exitdate,diastolic,
  systolic,pulse_bp, yobyear-year(ahd_date) as year_followup,ahd_date_min,ahd_date,count,
  case when diastolic >=110 or systolic  >= 180 then "HTN_crisis"
  when diastolic  >=100 and diastolic  < 110 then "HTN_S2"
  when systolic  >= 160 and systolic  < 180 then "HTN_S2"
  when diastolic   >= 90 and diastolic  < 100 then "HTN_S1"
  when systolic  >= 140 and systolic  < 160 then "HTN_S1"
  when diastolic   >= 80 and diastolic  < 90 then "HTN_pre"
  when systolic  >= 130 and systolic  < 140 then "HTN_pre"
  when systolic  < 90 or diastolic  <60 then "Hypotension" else "Normal" end as BP_status,
  case when ad_indexdate is null then exitdate else ad_indexdate end as ad_indexdate,
  case when ad is null then 0 else ad end as ad,
  case when vd_indexdate is null then exitdate else vd_indexdate end as vd_indexdate,
  case when vd is null then 0 else vd end as vd,
  case when dementia is null then 0 else dementia end as dementia,
  case when dementia_indexdate is null then exitdate else dementia_indexdate end as dementia_indexdate,
  case when stroke is null then 0 else stroke end as stroke,
  case when stroke_indexdate is null then exitdate else stroke_indexdate end as stroke_indexdate,
  case when MI is null then 0 else MI end as MI,
  case when MI_indexdate is null then exitdate else MI_indexdate end as MI_indexdate,
  case when diabete is null then 0 else diabete end as diabete,
  case when diabete_indexdate is null then exitdate else diabete_indexdate end as diabete_indexdate,
  case when ckd is null then 0 else ckd end as ckd,
  case when ckd_indexdate is null then exitdate else ckd_indexdate end as ckd_indexdate,
  case when head is null then 0 else head end as head,
  case when head_indexdate is null then exitdate else head_indexdate end as head_indexdate,
  case when depression is null then 0 else depression end as depression,
  case when depression_indexdate is null then exitdate else depression_indexdate end as depression_indexdate,
  case when parkinson is null then 0 else parkinson end as parkinson,
  case when parkinson_indexdate is null then exitdate else parkinson_indexdate end as parkinson_indexdate
  from latelife_3;

--------------- to exclude the cases with the index date of dementia including ad and vd, within the first year of registration, or diagnosed before the date of follow-up.
create table midlife_3_3 as select * from midlife_3_2
  where datediff(ad_indexdate,ahd_date) >0  and
  datediff(vd_indexdate,ahd_date) > 0 and datediff(dementia_indexdate,ahd_date) > 0 and
  datediff(ad_indexdate,regdate) > 365 and datediff(vd_indexdate,regdate) > 365 and
  datediff(dementia_indexdate,regdate) > 365 and datediff(stroke_indexdate,regdate) >0 and
  datediff(MI_indexdate,regdate) >0 and datediff(diabete_indexdate,regdate) >0 and
  datediff(ckd_indexdate,regdate) >0 and datediff(head_indexdate,regdate) >0 and
  datediff(depression_indexdate,regdate) >0 and datediff(parkinson_indexdate,regdate) >0;

create table latelife_3_3 as select * from latelife_3_2
  where datediff(ad_indexdate,ahd_date) >0  and
  datediff(vd_indexdate,ahd_date) > 0 and datediff(dementia_indexdate,ahd_date) > 0 and
  datediff(ad_indexdate,regdate) > 365 and datediff(vd_indexdate,regdate) > 365 and
  datediff(dementia_indexdate,regdate) > 365 and datediff(stroke_indexdate,regdate) >0 and
  datediff(MI_indexdate,regdate) >0 and datediff(diabete_indexdate,regdate) >0 and
  datediff(ckd_indexdate,regdate) >0 and datediff(head_indexdate,regdate) >0 and
  datediff(depression_indexdate,regdate) >0 and datediff(parkinson_indexdate,regdate) >0;

------------------		Create the binary variable for comorbidities, if the comorbidities is diagnosed before the date of follow-up.
create table midlife_3_4 as select combid, sex,yobyear, regdate, exitdate,
  diastolic,systolic,pulse_bp, year(ahd_date)-yobyear as year_followup,count,ahd_date_min,
  ahd_date,bp_status,ad_indexdate,ad,vd_indexdate,vd,
  dementia,dementia_indexdate,stroke,stroke_indexdate,MI,MI_indexdate,
  case when datediff(diabete_indexdate,ahd_date) >0 then 0 else 1 end as diabete,
  case when datediff(MI_indexdate,ahd_date) >0 then 0 else 1 end as MI_new,
  case when datediff(stroke_indexdate,ahd_date) >0 then 0 else 1 end as stroke_new,
  case when datediff(ckd_indexdate,ahd_date) >0 then 0 else 1 end as ckd,
  case when datediff(head_indexdate,ahd_date) >0 then 0 else 1 end as head,
  case when datediff(depression_indexdate,ahd_date) >0 then 0 else 1 end as depression,
  case when datediff(parkinson_indexdate,ahd_date) >0 then 0 else 1 end as parkinson,
  round(datediff(ad_indexdate,ahd_date)/365.25,2) as ad_years,
  round(datediff(vd_indexdate,ahd_date)/365.25,2) as vd_years,
  round(datediff(dementia_indexdate,ahd_date)/365.25,2) as dementia_years,
  round(datediff(stroke_indexdate,ahd_date)/365.25,2) as stroke_years,
  round(datediff(MI_indexdate,ahd_date)/365.25,2) as MI_years
  from midlife_3_3;


create table latelife_3_4 as select combid,sex, yobyear, regdate, exitdate,diastolic,
  systolic,pulse_bp, year(ahd_date)-yobyear as year_followup,count,ahd_date_min,
  ahd_date,bp_status,ad_indexdate,ad,vd_indexdate,vd,
  dementia,dementia_indexdate,stroke,stroke_indexdate,MI,MI_indexdate,
  case when datediff(diabete_indexdate,ahd_date) >0 then 0 else 1 end as diabete,
  case when datediff(MI_indexdate,ahd_date) >0 then 0 else 1 end as MI_new,
  case when datediff(stroke_indexdate,ahd_date) >0 then 0 else 1 end as stroke_new,
  case when datediff(ckd_indexdate,ahd_date) >0 then 0 else 1 end as ckd,
  case when datediff(head_indexdate,ahd_date) >0 then 0 else 1 end as head,
  case when datediff(depression_indexdate,ahd_date) >0 then 0 else 1 end as depression,
  case when datediff(parkinson_indexdate,ahd_date) >0 then 0 else 1 end as parkinson,
  round(datediff(ad_indexdate,ahd_date)/365.25,2) as ad_years,
  round(datediff(vd_indexdate,ahd_date)/365.25,2) as vd_years,
  round(datediff(dementia_indexdate,ahd_date)/365.25,2) as dementia_years,
  round(datediff(stroke_indexdate,ahd_date)/365.25,2) as stroke_years,
  round(datediff(MI_indexdate,ahd_date)/365.25,2) as MI_years
  from latelife_3_3;



------------------------	Combine the variable of smoking, alcohol_status, and BMI
---Extraction of BMI, Alcohol and Smoking for midlife and latelife cohort.
-------------	Drop tables before restart
drop table alcohol_1;
drop table alcohol_1_1;
drop table alcohol_1_2;
drop table alcohol_1_3;
drop table alcohol_1_3_1;
drop table alcohol_1_3_2;
drop table alcohol_1_4;
drop table alcohol_1_4_1;
drop table alcohol_1_4_2;
drop table alcohol_1_4_3;
drop table alcohol_1_4_4;
drop table alcohol_1_5;

drop table weight_1;
drop table weight_1_1;
drop table weight_1_2;
drop table weight_1_3;
drop table weight_1_4;
drop table weight_1_4_3;
drop table weight_1_4_4;
drop table weight_1_5;
drop table weight_1_6;
drop table weight_1_6_1;

drop table smoking_1;
drop table smoking_1_1;
drop table smoking_1_2;
drop table smoking_1_3;
drop table smoking_1_3_1;
drop table smoking_1_3_2;
drop table smoking_1_4;
drop table smoking_1_4_1;
drop table smoking_1_4_2;
drop table smoking_1_4_3;
drop table smoking_1_4_4;
drop table smoking_1_5;


--- Baseline variables
---	Smoking
Create table temp_smoking as select combid,
  cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as ahd_date,
  data1 as smoking_status from thin1205.ahd
  where ahdcode='1003040000' and ahdflag='Y';

Create table baseline_1 as select * from temp_smoking
  where ahd_date is not null and smoking_status in ('D','N','Y');

Create table smoking_1 as select a.combid, a.bp_status, a.ahd_date, b.ahd_date as smoking_date,
  b.smoking_status, datediff(b.ahd_date,a.ahd_date) as time_diff
  from  midlife_3_4 a join baseline_1 b on a.combid =b.combid;

----------	before the follow up
---- Find the most recent recording on smoking status before the follow-up
create table smoking_1_1 as select combid, max(time_diff) as time_diff
  from smoking_1 where time_diff <1 group by combid;
---- Find the smoking status for the most recent recording
---- Very few cases with more than 1 records on the same date, random find one of them
create table smoking_1_3 as select a.combid, a.smoking_status, rand(10) as rand_num
  from smoking_1 a join smoking_1_1 b on a.combid=b.combid and a.time_diff=b.time_diff;
create table smoking_1_3_1 as select combid, min(rand_num) as rand_num
  from smoking_1_3 group by combid;
create table smoking_1_3_2 as select a.combid, a.smoking_status
  from smoking_1_3 a join smoking_1_3_1 b on a.combid=b.combid and a.rand_num=b.rand_num;

----- Check whether there are duplicatesof smoking status for the same records
select count(combid),count(distinct combid) from smoking_1_3_2;

-----	After the follow up
---- Find the most recent recording on smoking status after the followup
----- The smoking status is relative stable.
create table smoking_1_2 as select combid, min(time_diff) as time_diff
  from smoking_1 where time_diff >0 group by combid;
create table smoking_1_4 as select a.combid,a.smoking_status,rand(10) as rand_num
  from smoking_1 a join smoking_1_2 b on a.combid=b.combid and a.time_diff=b.time_diff;

create table smoking_1_4_1 as select combid, min(rand_num) as rand_num
  from smoking_1_4 group by combid;
create table smoking_1_4_2 as select a.combid, a.smoking_status
  from smoking_1_4 a join smoking_1_4_1 b on a.combid=b.combid and a.rand_num=b.rand_num;

select count(combid),count(distinct combid) from smoking_1_4_2;

---- Combine the smoking status recording before or after the index date of follow-up
--- use the smoking status recorded after the index date if there is no smoking status being recorded
create table smoking_1_4_3 as select a.*,b.smoking_status as sm_indicator
  from smoking_1_4_2 a left outer join smoking_1_3_2 b on a.combid=b.combid;
create table smoking_1_4_4 as select combid, smoking_status
  from smoking_1_4_3 where sm_indicator is null;

create table smoking_1_5 as select * from
  (select * from smoking_1_4_4 union all select * from smoking_1_3_2) combined;

create table midlife_4_1 as select a.*,b.smoking_status
  from midlife_3_4 a left outer join smoking_1_5 b on a.combid=b.combid;

---	Alcohol use
Create table temp_alcohol as select combid,
  cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as ahd_date,
  data1 as alcohol_status, data2 as unit from thin1205.ahd
  where ahdcode='1003050000' and ahdflag='Y';
Create table baseline_2 as select * from temp_alcohol
  where ahd_date is not null and alcohol_status in ('D','N','Y');


Create table alcohol_1 as select a.combid, a.bp_status, a.ahd_date, b.ahd_date as alcohol_date,
  b.alcohol_status, datediff(b.ahd_date,a.ahd_date) as time_diff
  from  midlife_3_4 a join baseline_2 b on a.combid =b.combid;

create table alcohol_1_1 as select combid, max(time_diff) as time_diff
  from alcohol_1 where time_diff <1 group by combid;
create table alcohol_1_3 as select a.combid, a.alcohol_status, rand(10) as rand_num
  from alcohol_1 a join alcohol_1_1 b on a.combid=b.combid and a.time_diff=b.time_diff;
create table alcohol_1_3_1 as select combid, min(rand_num) as rand_num
  from alcohol_1_3 group by combid;
create table alcohol_1_3_2 as select a.combid, a.alcohol_status
  from alcohol_1_3 a join alcohol_1_3_1 b on a.combid=b.combid and a.rand_num=b.rand_num;

select count(combid),count(distinct combid) from alcohol_1_3_2;

-----	After the follow up
create table alcohol_1_2 as select combid, min(time_diff) as time_diff
  from alcohol_1 where time_diff >0 group by combid;
create table alcohol_1_4 as select a.combid,a.alcohol_status,rand(10) as rand_num
  from alcohol_1 a join alcohol_1_2 b
  on a.combid=b.combid and a.time_diff=b.time_diff;

create table alcohol_1_4_1 as select combid, min(rand_num) as rand_num
  from alcohol_1_4 group by combid;
create table alcohol_1_4_2 as select a.combid, a.alcohol_status
  from alcohol_1_4 a join alcohol_1_4_1 b on a.combid=b.combid and a.rand_num=b.rand_num;
select count(combid),count(distinct combid) from alcohol_1_4_2;

--------- combine the alcohol status
create table alcohol_1_4_3 as select a.*,b.alcohol_status as sm_indicator
  from alcohol_1_4_2 a left outer join alcohol_1_3_2 b on a.combid=b.combid;
create table alcohol_1_4_4 as select combid, alcohol_status
  from alcohol_1_4_3 where sm_indicator is null;

create table alcohol_1_5 as select * from
  (select * from alcohol_1_4_4 union all select * from alcohol_1_3_2) combined;
select count(combid),count(distinct combid) from alcohol_1_5;

create table midlife_4_2 as select a.*,b.alcohol_status
  from midlife_4_1 a left outer join alcohol_1_5 b
  on a.combid=b.combid;

----------------	BMI
--  weight and height to Calculate BMI
Create table temp_weight as select combid,
  cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as ahd_date,
  cast(data1 as double) as weight from thin1205.ahd
  where ahdcode='1005010200' and ahdflag='Y' and data1 is not null;

Create table temp_height as select combid,
  cast(concat_ws('-',eventyear,eventmonth,eventday) as date) as ahd_date,
  cast(data1 as bigint) as height from thin1205.ahd
  where ahdcode='1005010100' and ahdflag='Y' and data1 is not null;

Create table temp_weight_1 as select combid, ahd_date, avg(weight) as weight
from temp_weight where ahd_date is not null and weight < 240 and
weight > 20 group by combid, ahd_date;


Create table weight_1 as select a.combid, a.bp_status, a.ahd_date,
  b.ahd_date as weight_date, b.weight, datediff(b.ahd_date,a.ahd_date) as time_diff
  from  midlife_3_4 a join temp_weight_1 b
  on a.combid =b.combid;

create table weight_1_1 as select combid, max(time_diff) as time_diff
  from weight_1 where time_diff <1  and time_diff > -1826
  group by combid;
create table weight_1_3 as select a.combid, a.weight
  from weight_1 a join weight_1_1 b
  on a.combid=b.combid and a.time_diff=b.time_diff;

select count(combid),count(distinct combid) from weight_1_3;


-----	After the index of follow up
create table weight_1_2 as select combid, min(time_diff) as time_diff
  from weight_1 where time_diff >0 and time_diff < 1826
  group by combid;
create table weight_1_4 as select a.combid,a.weight
  from weight_1 a join weight_1_2 b
  on a.combid=b.combid and a.time_diff=b.time_diff;
select count(combid),count(distinct combid) from weight_1_4;
--------- Combine the date
create table weight_1_4_3 as select a.*,b.weight as sm_indicator
  from weight_1_4 a left outer join weight_1_3 b
  on a.combid=b.combid;

create table weight_1_4_4 as select combid, weight from weight_1_4_3 where sm_indicator is null;

create table weight_1_5 as select *
  from (select * from weight_1_4_4 union all select * from weight_1_3) combined;


---	Use the median values of height as the reference height after 25 year old;
Create table temp_height_1 as select *
  from temp_height where ahd_date is not null;
Create table ht_1 as select a.combid, a.ahd_date, a.yobyear, b.ahd_date as ht_date, b.height
  from midlife_3_4 a join temp_height_1 b on a.combid=b.combid;
Create table ht_2 as select combid, percentile_approx(height, 0.5) as height
  from ht_1 where year(ht_date) > (yobyear+25) and height > 1 and height < 2.1 group by combid;


create table weight_1_6 as select a.combid, b.height, a.weight/b.height/b.height as BMI
  from weight_1_5 a join ht_2 b on a.combid=b.combid;
create table weight_1_6_1 as select combid,
  case when BMI <25 then 'Normal' when BMI >30 then 'Obesity' else 'Overweight' end as BMI_cat
  from weight_1_6;

-------------categorize the BMI
create table midlife_4_3 as select a.*,b.BMI_cat
  from midlife_4_2 a left outer join weight_1_6_1 b
  on a.combid=b.combid;

------------	After combine the information of smoking, alcohol, and BMI;
drop table midlife_4_4;
-------
create table midlife_4_4 as select a.*, b.smoking_status,b.alcohol_status,b.bmi_cat from midlife_3_4 a join midlife_4_3 b on a.combid=b.combid;

----------	Latelife
drop table latelife_4_4;
-------------
create table latelife_4_4 as select a.*, b.smoking_status,b.alcohol_status,b.bmi_cat from latelife_3_4 a join latelife_4_3 b on a.combid=b.combid;

------------  Exclude the case exited before the index date of follow-up
--- Create the variable to indicate the cases died before the index of dementia,
---  count the number of drug taken between the first and last date of BP measurement
------------------
drop table midlife_4_5_1;
drop table midlife_4_5_2;
drop table midlife_4_5_3;
drop table midlife_4_5_4;
drop table midlife_4_5_4_1;
drop table midlife_4_5_5;
drop table midlife_4_5_5_1;
---------------- extract the variable of death date;
create table midlife_4_5_1 as select a.*,b.deathdate
  from midlife_4_4 a join temp_all_cases b on a.combid=b.combid;
create table midlife_4_5_2 as select *,
  case when deathdate is null then exitdate else deathdate end as deathdate_new,
  case when deathdate is null then 0 else 1 end as death_status
  from midlife_4_5_1;

----	the date of follow-up must be before the date of exit:
--  the earliest date of death, exit, or end of followup: 2012-5-14.

create table midlife_4_5_3 as select *,
  case when datediff(deathdate_new,dementia_indexdate) < 0 then 1 else 0 end as death_dementia
  from midlife_4_5_2 where datediff(exitdate,ahd_date) > 0;

select bp_status, count(combid) from midlife_4_5_3 group by bp_status;

--------Count the number of drugs: the drug must be taken within the ahd_date and ahd_date_min;
create table midlife_4_5_4 as select b.*
  from midlife_4_5_3 a join temp_19 b on a.combid=b.combid
  where datediff(b.prsc_date,a.ahd_date_min) >= -60 and datediff(a.ahd_date,b.prsc_date) >= -60;

create table midlife_4_5_4_1 as select combid, count(prsc_date) as drug_count
  from midlife_4_5_4 group by combid;

create table midlife_4_5_5 as select a.*,datediff(a.ahd_date,a.ahd_date_min)/365.25 as ahd_years,
  b.drug_count from midlife_4_5_3 a left outer join midlife_4_5_4_1 b on a.combid=b.combid;
create table midlife_4_5_5_1 as select *,
  case when drug_count is null then 0 else drug_count end as drug_use
  from midlife_4_5_5;

------------------------------	Late life
---------exclude the cases exit before the index date of follow-up;
---------Create the variable to indicate the cases died before the index of dementia,
---------count the number of drug taken between the first and last date of BP measurement

drop table latelife_4_5_1;
drop table latelife_4_5_2;
drop table latelife_4_5_3;
drop table latelife_4_5_4;
drop table latelife_4_5_4_1;
drop table latelife_4_5_5;
drop table latelife_4_5_5_1;


create table latelife_4_5_1 as select a.*,b.deathdate
  from latelife_4_4 a join temp_all_cases b
  on a.combid=b.combid;
create table latelife_4_5_2 as select *,
  case when deathdate is null then exitdate else deathdate end as deathdate_new,
  case when deathdate is null then 0 else 1 end as death_status
  from latelife_4_5_1;
------ the date of follow-up must be before the date of exit: the earliest date of death, exit, or end of followup: 2012-5-14.

create table latelife_4_5_3 as select *,
  case when datediff(deathdate_new,dementia_indexdate) < 0 then 1 else 0 end as death_dementia
  from latelife_4_5_2 where datediff(exitdate,ahd_date) > 0;

select bp_status, count(combid) from latelife_4_5_3 group by bp_status;

----------------	Count the number of drugs: the drug must be taken within the ahd_date and ahd_date_min;
create table latelife_4_5_4 as select b.* from latelife_4_5_3 a join temp_19 b
  on a.combid=b.combid
where datediff(b.prsc_date,a.ahd_date_min) >= -60 and datediff(a.ahd_date,b.prsc_date) >= -60;
create table latelife_4_5_4_1 as select combid, count(prsc_date) as drug_count
  from latelife_4_5_4 group by combid;


create table latelife_4_5_5 as select a.*,
  datediff(a.ahd_date,a.ahd_date_min)/365.25 as ahd_years,b.drug_count
  from latelife_4_5_3 a left outer join latelife_4_5_4_1 b
  on a.combid=b.combid;
create table latelife_4_5_5_1 as select *,
  case when drug_count is null then 0 else drug_count end as drug_use
  from latelife_4_5_5;


---------   	year of hypertension starting from index date of hypertension;
------------	Create the index date for hypertension

drop table midlife_4_6;
drop table midlife_4_6_1;
drop table midlife_4_6_2;
drop table midlife_4_6_3;


create table midlife_4_6 as select a.*, b.indexdate
  from midlife_4_5_5_1 a left outer join temp_23_2 b
  on a.combid=b.combid;
create table midlife_4_6_1 as select  *,
  case when indexdate is null then 0 else 1 end as HTN,
  case when indexdate is null then ahd_date else indexdate end as indexdate_new
  from midlife_4_6;

create table midlife_4_6_2 as select *, round(datediff(ahd_date,indexdate_new)/365.25,2) as years_htn
  from midlife_4_6_1;
create table midlife_4_6_3 as select *, year(ahd_date) as ahdyear from midlife_4_6_2;


------------------	final output for data analysis in R
drop table midlife_output_htn;
CREATE TABLE midlife_output_htn ROW FORMAT DELIMITED FIELDS TERMINATED BY "," AS
SELECT combid, sex, yobyear, regdate, exitdate,diastolic, systolic,pulse_bp, year_followup, count,
  ahd_date_min, ahd_date, bp_status, ad_indexdate, ad,
  vd_indexdate, vd, dementia, dementia_indexdate, stroke,
  stroke_indexdate, mi, mi_indexdate,diabete,mi_new,
  stroke_new, ckd, head, depression,
  parkinson, ad_years, vd_years, dementia_years,
  stroke_years,mi_years,smoking_status,alcohol_status, bmi_cat,
  deathdate_new,death_status,death_dementia,ahd_years,
  drug_use,htn,indexdate_new,years_htn,ahdyear
  from midlife_4_6_3;


---------------------	index date for hypertension;
drop table latelife_4_6;
drop table latelife_4_6_1;
drop table latelife_4_6_2;
drop table latelife_4_6_3;


create table latelife_4_6 as select a.*, b.indexdate
  from latelife_4_5_5_1 a left outer join temp_23_2 b
  on a.combid=b.combid;
create table latelife_4_6_1 as select  *,
  case when indexdate is null then 0 else 1 end as HTN,
  case when indexdate is null then ahd_date else indexdate end as indexdate_new
  from latelife_4_6;
create table latelife_4_6_2 as select *, round(datediff(ahd_date,indexdate_new)/365.25,2) as years_htn
  from latelife_4_6_1;
create table latelife_4_6_3 as select *, year(ahd_date) as ahdyear from latelife_4_6_2;


-------------- Final output for data analysis in R
drop table latelife_output_htn;
CREATE TABLE latelife_output_htn ROW FORMAT DELIMITED FIELDS TERMINATED BY "," AS
SELECT combid, sex, yobyear, regdate, exitdate,
diastolic, systolic, pulse_bp,year_followup, count,
ahd_date_min, ahd_date, bp_status, ad_indexdate, ad,
vd_indexdate, vd, dementia, dementia_indexdate, stroke,
stroke_indexdate, mi, mi_indexdate,diabete,mi_new,
stroke_new, ckd, head, depression,
parkinson, ad_years, vd_years, dementia_years,
stroke_years,mi_years,smoking_status,alcohol_status, bmi_cat,
deathdate_new,death_status,death_dementia,ahd_years,
drug_use,htn,indexdate_new,years_htn,ahdyear from latelife_4_6_3;

---------------	Copy the file from hive to unix

rm -rf /home/mpeng/midlife_output_htn
mkdir -p /home/mpeng/midlife_output_htn
hadoop fs -copyToLocal /apps/hive/warehouse/hypertension.db/midlife_output_htn/* /home/mpeng/midlife_output_htn

cd /home/mpeng/midlife_output_htn
cat $(ls -t) > midlife_final

rm -rf /home/mpeng/latelife_output_htn
mkdir -p /home/mpeng/latelife_output_htn
hadoop fs -copyToLocal /apps/hive/warehouse/hypertension.db/latelife_output_htn/* /home/mpeng/latelife_output_htn


cd /home/mpeng/latelife_output_htn
cat $(ls -t) > latelife_final






----------------------- R code for analysis--cox regression
-----The data file with indexdate of hypertension to examine the number of years with hypertension

--- midlife
dementia <- read.csv("/home/mpeng/midlife_output/midlife_final",header=F);

--- late life
dementia <- read.csv("/home/mpeng/latelife_output/latelife_final",header=F);


colnames(dementia) <- c("combid", " sex", " yobyear", " regdate", " exitdate", "diastolic", " systolic", " year_followup", " count",
"ahd_date_min", " ahd_date", " bp_status", " ad_indexdate", " ad",
"vd_indexdate", " vd", " dementia", " dementia_indexdate", " stroke",
"stroke_indexdate", " mi", " mi_indexdate", "diabete", "mi_new",
"stroke_new", " ckd", " head", " depression",
"parkinson", " ad_years", " vd_years", " dementia_years",
"stroke_years", "mi_years", "smoking_status", "alcohol_status", " bmi_cat",
"deathdate_new", "death_status", "death_dementia", "ahd_years",
"drug_use", "htn", "indexdate_new", "years_htn")



dementia <- read.csv("/home/mpeng/midlife_output_htn/midlife_final",header=F);
dementia <- read.csv("/home/mpeng/latelife_output_htn/latelife_final",header=F);
colnames(dementia) <- c("combid","sex","yobyear","regdate","exitdate", "diastolic","systolic","age_followup","count","ahd_date_min","ahd_date","bp_status",
"ad_indexdate","ad","vd_indexdate","vd", "dementia","dementia_indexdate","stroke","stroke_indexdate","mi","mi_indexdate",
"diabete","MI_new","stroke_new","ckd","head","depression","parkinson",
"ad_years","vd_years","dementia_years","stroke_years","mi_years","smoking_status","alcohol_status","BMI_cat",
"ahdyear","deathdate","death","death_ad","death_vd","death_dementia","ahd_years","drug_count","drug_use","indexdate","HTN","HTN_new","indexdate_new","years_htn",
"year_count","pulse_bp","year_measurements","rate_m")



dementia$drug_rate <- dementia$drug_use/(dementia$ahd_years+120/365.25)

dementia$alcohol_status[dementia$alcohol_status=="\\N"] <- NA
dementia$alcohol_status <- as.character(dementia$alcohol_status)
dementia$alcohol_status <- as.factor(dementia$alcohol_status)

dementia$smoking_status[dementia$smoking_status=="\\N"] <- NA
dementia$smoking_status <- as.character(dementia$smoking_status)
dementia$smoking_status <- as.factor(dementia$smoking_status)

dementia$BMI_cat[dementia$BMI_cat=="\\N"] <- NA
dementia$BMI_cat <- as.character(dementia$BMI_cat)
dementia$BMI_cat <- as.factor(dementia$BMI_cat)

dementia$bp_status[dementia$bp_status=="Hypotension"] <- "Normal"

dementia$bp_status[dementia$bp_status=="HTN_crisis"] <- "HTN_S2"
dementia$bp_status <- as.character(dementia$bp_status)
dementia$bp_status <- as.factor(dementia$bp_status)
dementia <- within(dementia, bp_status <- relevel(bp_status, ref = "Normal"))

dementia$bp_status[dementia$bp_status=="HTN_pre"] <- "Normal"

###############	subset
Analysis is conducted on the cases meeting the following conditions: dementia_years >=1 & ahdyear > 1989
##########

########	mid-life subset
###########	Control the number of years with BP measurements, age starting follow-up.
dementia	<- subset(dementia,dementia_years >=1 & ahdyear > 1989)
table(dementia$bp_status,dementia$vd)


dementia$count_cat <- ifelse(dementia$count > 3,1,0)
dementia$age_cat <- ifelse(dementia$age_followup > 55,1,0)

dementia	<- subset(dementia,count_cat==1&age_cat==1 & dementia_years >=1 &ahdyear > 1989)


########	Subset on the number of BP

dementia	<- subset(dementia,count_cat==1&age_cat==1 & dementia_years >=1 &ahdyear > 1989 & rate_m >=0.5)


dementia$quartile_pulse <- with(dementia, cut(pulse_bp,
                                breaks=quantile(pulse_bp, probs=seq(0,1, by=0.25)),
                                include.lowest=TRUE))


######### only for alive patients not censored due to death
dementia	<- subset(dementia,death==0)


#########	late life subset
dementia	<- subset(dementia,dementia_years >=1 & ahdyear > 1989)
-- only for alive patients not censored due to death
dementia	<- subset(dementia,death==0)

####################################	Table 1- clinical characteristics
table1 <-  matrix(0,19,5)

t1_sex <- table(dementia$sex,dementia$bp_status,useNA ="ifany")
t1_sex
table1[1,5] <- round(chisq.test(t1_sex,simulate.p.value = T)$p.value,3)
t1_sex <- round(prop.table(t1_sex, 2)*100,1)
t1_sex <- data.frame(t1_sex)
t1_sex<- matrix(t1_sex$Freq,2,4)
table1[1,1:4] <- t1_sex[1,]


t1_smoking<- table(dementia$smoking_status,dementia$bp_status,useNA="ifany")
table1[3,5] <- round(chisq.test(t1_smoking,simulate.p.value = T)$p.value,3)
t1_smoking <- round(prop.table(t1_smoking, 2)*100,1)
t1_smoking <- data.frame(t1_smoking)
t1_smoking <- matrix(t1_smoking$Freq,4,4)
table1[3:6,1:4] <- t1_smoking[c(2,1,3,4),]

t1_alcohol<- table(dementia$alcohol_status,dementia$bp_status,useNA="ifany")
table1[8,5] <- round(chisq.test(t1_alcohol,simulate.p.value = T)$p.value,3)
t1_alcohol <- round(prop.table(t1_alcohol, 2)*100,1)
t1_alcohol <- data.frame(t1_alcohol)
t1_alcohol <- matrix(t1_alcohol$Freq,4,4)
table1[8:11,1:4] <- t1_alcohol[c(2,1,3,4),]

t1_BMI_cat<- table(dementia$BMI_cat,dementia$bp_status,useNA="ifany")
table1[13,5] <- round(chisq.test(t1_BMI_cat,simulate.p.value = T)$p.value,3)
t1_BMI_cat <- round(prop.table(t1_BMI_cat, 2)*100,1)
t1_BMI_cat <- data.frame(t1_BMI_cat)
t1_BMI_cat <- matrix(t1_BMI_cat$Freq,4,4)
table1[13:16,1:4] <- t1_BMI_cat[c(1,3,2,4),]

t1_diabete <- table(dementia$diabete,dementia$bp_status,useNA ="ifany")
t1_diabete
table1[17,5] <- round(chisq.test(t1_diabete,simulate.p.value = T)$p.value,3)
t1_diabete <- round(prop.table(t1_diabete, 2)*100,1)
t1_diabete <- data.frame(t1_diabete)
t1_diabete<- matrix(t1_diabete$Freq,2,4)
table1[17,1:4] <- t1_diabete[2,]

t1_stroke_new <- table(dementia$stroke_new,dementia$bp_status,useNA ="ifany")
t1_stroke_new
table1[18,5] <- round(chisq.test(t1_stroke_new,simulate.p.value = T)$p.value,3)
t1_stroke_new <- round(prop.table(t1_stroke_new, 2)*100,1)
t1_stroke_new <- data.frame(t1_stroke_new)
t1_stroke_new<- matrix(t1_stroke_new$Freq,2,4)
table1[18,1:4] <- t1_stroke_new[2,]

t1_MI_new <- table(dementia$MI_new,dementia$bp_status,useNA ="ifany")
t1_MI_new
table1[19,5] <- round(chisq.test(t1_MI_new,simulate.p.value = T)$p.value,3)
t1_MI_new <- round(prop.table(t1_MI_new, 2)*100,1)
t1_MI_new <- data.frame(t1_MI_new)
t1_MI_new<- matrix(t1_MI_new$Freq,2,4)
table1[19,1:4] <- t1_MI_new[2,]

library(dplyr)

by_bp <- group_by(dementia, bp_status)
age_bp <- summarise(by_bp,
  age_mean = round(mean(age_followup),1),
  age_sd = round(sd(age_followup),1))

 aov(age_followup ~ bp_status, data = dementia)


------------	summary
library(dplyr)

by_bp <- group_by(dementia, bp_status)
  dementia_bp <- summarise(by_bp,
  cases_sum = sum(dementia),
  years_sum = sum(dementia_years),rate=cases_sum/years_sum*1000)
dementia_bp
  ad_bp <- summarise(by_bp,
  cases_sum = sum(ad),
  years_sum = sum(ad_years),rate=cases_sum/years_sum*1000)
ad_bp
  vd_bp <- summarise(by_bp,
  cases_sum = sum(vd),
  years_sum = sum(vd_years),rate=cases_sum/years_sum*1000)
vd_bp

----------	Drug rate
  vd_bp <- summarise(by_bp,
  cases_sum = mean(drug_rate),
  years_sum = sd(drug_rate))

--------------	Table 1
table1 <- matrix(0,10,5)
-----	No of patients
t1 <- table(dementia$bp_status,useNA ="ifany")
table1[1,1:4] <- as.vector(t1)

-----	Starting age of follow-up
library(dplyr)

by_bp <- group_by(dementia, bp_status)
age_bp <- summarise(by_bp,
  age_mean = round(mean(age_followup),1),
  age_sd = round(sd(age_followup),1))

aov(age_followup ~ bp_status, data = dementia)

paste(age_bp[,2],age_bp[,3])




t2 <- table(dementia$bp_status_3level,dementia$age,useNA ="ifany")
t2
table1[2,7] <- round(chisq.test(t2,simulate.p.value = T)$p.value,3)

t2_1 <- data.frame(round(t2/rowSums(t2)*100,1))
t2_1 <- t2_1[with(t2_1, order(Var1, Var2)), ]

table1[2:5,c(2,4,6)] <- matrix(t2_1$Freq,4,3)
t2_2 <- data.frame(t2)
t2_2 <- t2_2[with(t2_2, order(Var1, Var2)), ]
table1[2:5,c(1,3,5)] <- matrix(t2_2$Freq,4,3)




table1[1,7] <- round(chisq.test(t1,simulate.p.value = T)$p.value,3)
t1_1 <- data.frame(round(t1/rowSums(t1)*100,1))
t1_1 <- t1_1[with(t1_1, order(Var2, Var1)), ]
table1[1,c(2,4,6)] <- matrix(t1_1$Freq,2,3,byrow=T)[1,]
t1_2 <- data.frame(t1)
table1[1,c(1,3,5)] <- matrix(t1_2$Freq,2,3,byrow=T)[1,]









-----------------	MI imputation
##########	Adjusted for all covariates, incomplete dataset
###		Multiple imputation to fill in the missing value
###		Genearte new full dataset
index <- c("sex","diastolic","systolic","age_followup","count","bp_status","ad","dementia",
"diabete","MI_new","stroke_new","ckd","head","depression","parkinson","ad_years","vd_years",
"dementia_years","stroke_years","mi_years","smoking_status","alcohol_status","BMI_cat","drug_rate","death")

dementia_MI <- dementia[,index]
library(mi);

----------------	How to use the MI package
Step 1: missing_data.frame  - define the data.frame with missing
Step 2: change



---------------------------------

D_mi <- missing_data.frame(dementia_MI)
IMP_MI <- mi(D_mi)

data.frames_mi <- complete(IMP_MI, 10)


dementia <- data.frames_mi[[1]]
---------- analysis

dementia$count_cat <- ifelse(dementia$count > 3,1,0)
dementia$age_cat <- ifelse(dementia$age_followup > 55,1,0)

library(rms)
dementia_1	<- subset(dementia,age_cat==1)




 & count > 3)
dementia_1	<- subset(dementia,count_cat==1)


coxph.ad <- cph(formula = Surv(ad_years, ad) ~ sex + age_followup+bp_status+diabete+stroke_new+MI_new,data=dementia)
coxph.ad


coxph.vd <- cph(formula = Surv(vd_years, vd) ~ sex + age_followup+bp_status+diabete+stroke_new+MI_new ,data=dementia)
coxph.vd

coxph.vd <- cph(formula = Surv(vd_years, vd) ~ sex +years_htn*bp_status+diabete+stroke_new+MI_new ,data=dementia)
coxph.vd


coxph.vd <- cph(formula = Surv(vd_years, vd) ~ sex +quartile_pulse+diabete+stroke_new+MI_new ,data=dementia)
coxph.vd


coxph.dementia <- cph(formula = Surv(dementia_years, dementia) ~ sex + age_followup+bp_status+diabete+stroke_new+MI_new ,data=dementia)
coxph.dementia



dementia_1	<- subset(dementia,age_cat==1)
dementia_1	<- subset(dementia,age_cat==1  & count > 2)


coxph.vd <- cph(formula = Surv(vd_years, vd) ~ sex + age_followup+bp_status+diabete,data=dementia_1)
coxph.vd <- cph(formula = Surv(vd_years, vd) ~ sex + age_followup+bp_status,data=dementia_1)

coxph.vd <- coxph(formula = Surv(vd_years, vd) ~ sex + age_followup+bp_status+diabete+smoking_status+alcohol_status+BMI_cat,data=dementia_1)

coxph.ad <- coxph(formula = Surv(ad_years, ad) ~ sex + age_followup+bp_status+diabete+smoking_status+alcohol_status+BMI_cat,data=dementia)


coxph.vd

coxph.dementia <- cph(formula = Surv(dementia_years, dementia) ~ sex + rcs(age_followup,4)+bp_status+diabete+stroke_new+MI_new,data=dementia)
coxph.dementia


#########	output for table 2
table(dementia$bp_status,dementia$ad)


library(rms)
table2 <- matrix(0,9,2)
-------------	Model: age and sex adjusted
coxph.model <- coxph(formula = Surv(dementia_years, dementia) ~ sex + age_followup+bp_status,data=dementia)
coef_model <- summary(coxph.model)$coefficients
table2[1:3,2]<- round(coef_model[,5],2)[3:5]

CI_95<- summary(coxph.model)$conf.int
CI_95 <- round(CI_95,2)

for(i in 1:3){
table2[i,1] <- paste(CI_95[i+2,1],"(",CI_95[i+2,3]," to ",CI_95[i+2,4],")",sep="")
}

coxph.model <- coxph(formula = Surv(vd_years, vd) ~ sex + age_followup+bp_status,data=dementia)
coef_model <- summary(coxph.model)$coefficients
table2[4:6,2]<- round(coef_model[,5],2)[3:5]

CI_95<- summary(coxph.model)$conf.int
CI_95 <- round(CI_95,2)

for(i in 1:3){
table2[i+3,1] <- paste(CI_95[i+2,1],"(",CI_95[i+2,3]," to ",CI_95[i+2,4],")",sep="")
}

coxph.model <- coxph(formula = Surv(ad_years, ad) ~ sex + age_followup+bp_status,data=dementia)
coef_model <- summary(coxph.model)$coefficients
table2[7:9,2]<- round(coef_model[,5],2)[3:5]

CI_95<- summary(coxph.model)$conf.int
CI_95 <- round(CI_95,2)

for(i in 1:3){
table2[i+6,1] <- paste(CI_95[i+2,1],"(",CI_95[i+2,3]," to ",CI_95[i+2,4],")",sep="")
}

data.frame(table2)

##############	Model with all the multivariables but exclude missing part
table2 <- matrix(0,9,2)
###############	Model: age and sex adjusted
coxph.model <- coxph(formula = Surv(dementia_years, dementia) ~ sex + age_followup+bp_status+diabete+smoking_status+alcohol_status+BMI_cat+stroke_new+MI_new+sqrt(drug_rate),data=dementia)
coef_model <- summary(coxph.model)$coefficients
table2[1:3,2]<- round(coef_model[,5],2)[3:5]

CI_95<- summary(coxph.model)$conf.int
CI_95 <- round(CI_95,2)

for(i in 1:3){
table2[i,1] <- paste(CI_95[i+2,1],"(",CI_95[i+2,3]," to ",CI_95[i+2,4],")",sep="")
}

coxph.model <- coxph(formula = Surv(vd_years, vd) ~ sex + age_followup+bp_status+diabete+smoking_status+alcohol_status+BMI_cat+stroke_new+MI_new,data=dementia)
coef_model <- summary(coxph.model)$coefficients
table2[4:6,2]<- round(coef_model[,5],2)[3:5]

CI_95<- summary(coxph.model)$conf.int
CI_95 <- round(CI_95,2)

for(i in 1:3){
table2[i+3,1] <- paste(CI_95[i+2,1],"(",CI_95[i+2,3]," to ",CI_95[i+2,4],")",sep="")
}

coxph.model <- coxph(formula = Surv(ad_years, ad) ~ sex + age_followup+bp_status+diabete+smoking_status+alcohol_status+BMI_cat+stroke_new+MI_new,data=dementia)
coef_model <- summary(coxph.model)$coefficients
table2[7:9,2]<- round(coef_model[,5],2)[3:5]

CI_95<- summary(coxph.model)$conf.int
CI_95 <- round(CI_95,2)

for(i in 1:3){
table2[i+6,1] <- paste(CI_95[i+2,1],"(",CI_95[i+2,3]," to ",CI_95[i+2,4],")",sep="")
}

data.frame(table2)





----------------------- Multiple imputation and model with all the variables
library(mi)
index <- c("sex","diastolic","systolic","age_followup","count","bp_status","ad","vd","dementia",
"diabete","MI_new","stroke_new","ckd","head","depression","parkinson","ad_years","vd_years",
"dementia_years","smoking_status","alcohol_status","BMI_cat","ahd_years","death","drug_rate")


dementia_MI <- dementia[,index]

D_mi <- missing_data.frame(dementia_MI)
show(D_mi)

IMP_MI <- mi(D_mi,n.iter = 40)
-----------------
Values closer to 1.0 indicate little is to be gained by running the
chains longer, and in general, values greater than 1.1 indicate that the chains should be run longer.
-----------------
Rhats(IMP_MI)
mi2BUGS(IMP_MI)



data.frames_mi <- complete(IMP_MI, 10)
dementia <- data.frames_mi[[1]]
write.csv(dementia,"/home/mpeng/midlife_output/midlife_mi_1.csv")

-------------	pool together the results
data_mi <- subset(data_mi,death==0)


vd_mi <- matrix(0,10,6)
ad_mi <- matrix(0,10,6)
dementia_mi <- matrix(0,10,6)


for (i in 1:10){
data_mi <- data.frames_mi[[i]]


data_mi$ad <- as.numeric(data_mi$ad)

cox_model_3 <- coxph( Surv(ad_years, ad) ~ bp_status+sex + age_followup+diabete+smoking_status+alcohol_status+BMI_cat+stroke_new+MI_new,data=data_mi)
ad_mi[i,1:2] <- summary(cox_model_3)$coef[1,c(1,3)]
ad_mi[i,3:4] <- summary(cox_model_3)$coef[2,c(1,3)]
ad_mi[i,5:6] <- summary(cox_model_3)$coef[3,c(1,3)]

data_mi$dementia <- as.numeric(data_mi$dementia)
cox_model_4 <- coxph(Surv(dementia_years,dementia) ~ bp_status+sex + age_followup+diabete+smoking_status+alcohol_status+BMI_cat+stroke_new+MI_new,data=data_mi)
dementia_mi[i,1:2] <- summary(cox_model_4)$coef[1,c(1,3)]
dementia_mi[i,3:4] <- summary(cox_model_4)$coef[2,c(1,3)]
dementia_mi[i,5:6] <- summary(cox_model_4)$coef[3,c(1,3)]

data_mi$vd <- as.numeric(data_mi$vd)
cox_model_2 <- coxph(Surv(vd_years, vd) ~ bp_status+ sex + age_followup+diabete+smoking_status+alcohol_status+BMI_cat+stroke_new+MI_new ,data=data_mi)
vd_mi[i,1:2] <- summary(cox_model_2)$coef[1,c(1,3)]
vd_mi[i,3:4] <- summary(cox_model_2)$coef[2,c(1,3)]
vd_mi[i,5:6] <- summary(cox_model_2)$coef[3,c(1,3)]
}



round(MI_pooled(dementia_mi,3,10),2)
round(MI_pooled(vd_mi,3,10),2)
round(MI_pooled(ad_mi,3,10),2)




###########	pooled together

MI_pooled <- function(data,Number_p,number_mi){
output <- matrix(0,Number_p,4)
data_mean <- colMeans(data)

for (i in 1:Number_p){
B <- sum((data[,2*i-1]-data_mean[2*i-1])^2)/(number_mi-1)
T <- data_mean[2*i]^2+(1+1/number_mi)*B

df_mean <- (number_mi-1)*(1+number_mi*data_mean[2*i]/(number_mi+1)/B)^2
########	If the variable >1 then use the upper tails

output[i,] <- c(exp(data_mean[2*i-1]),exp(qt(c(0.025,0.975), df_mean)*sqrt(T)+data_mean[2*i-1]),pt(-abs(data_mean[2*i-1])/sqrt(T), df_mean))
}
return(output)
}







################### Validity of data for stroke

stroke_dm <- subset(dementia,stroke_years >0)

coxph.model <- coxph(formula = Surv(stroke_years, stroke) ~ sex + age_followup+bp_status+diabete+smoking_status+alcohol_status+BMI_cat+MI_new,data=stroke_dm)
coxph.model

coef_model <- summary(coxph.model)$coefficients
