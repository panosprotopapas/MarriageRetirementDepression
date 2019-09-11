**************************************************************************************************************
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/* 											PRELIMINARIES												   */
////////////////////////////////////////////////////////////////////////////////////////////////////////////
***********************************************************************************************************

////////////////////
/* INITIAL SETUP */
//////////////////
qui {
clear all
set mem 1000m
cap log close
cd "H:\pan\"
log close _all
log using microeconometrics, replace
}

//////////////////////////////////////////////
/* OPEN DATABASE & DROP UNWANTED VARIABLES */
////////////////////////////////////////////
qui {
use share_reduceddb
keep w1_country w1_exrate w1_dn014_ w1_ph006d1 w1_ph006d2 w1_ph006d3 w1_ph006d4 w1_ph006d5 /// 
w1_ph006d6 w1_ph006d7 w1_hc015d3 w1_ph006d8 w1_ph006d9 w1_ph006d10 w1_ph006d11 ///
w1_ph006d12 w1_ph006d13 w1_ph006d14 w1_ep005_  w1_ep065_  w1_gender  w1_mobirth ///
w1_yrbirth w1_ph006dno w1_ph006dot w1_int_year  w1_int_month w1_eurod  ///
w1_ch001_  w1_ch022_ w1_ph048d1 w1_ph048d2 w1_ph048d3 w1_ph048d4 w1_ph048d5 ///
w1_currency  w1_pppx2003  w1_pppx2004  w1_pppx2005  w1_ph048d6 ///
w1_ph048d7 w1_ph048d8 w1_ph048d9 w1_ph048d10 w1_hnetwv w1_hhsize ///
w1_ph048dno w1_ph049d1 w1_ph049d2 w1_ph049d3 w1_ph049d4 w1_ph049d5 ///
w1_ph049d6 w1_ph049d9 w1_ph049d10 w1_ph049d11 ///
w1_ph049d12 w1_ph049dno ///
w2_country w2_exrate w2_dn014_ w2_ph006d1 w2_ph006d2 w2_ph006d3 w2_ph006d4 w2_ph006d5 /// 
w2_ph006d6 w2_ph006d7 w2_hc015d3 w2_ph006d8 w2_ph006d9 w2_ph006d10 w2_ph006d11 ///
w2_ph006d12 w2_ph006d13 w2_ph006d14 w2_ep005_  w2_ep065_  w2_gender  w2_mobirth ///
w2_yrbirth w2_ph006dno w2_ph006dot w2_int_year  w2_int_month w2_eurod  ///
w2_ch001_  w2_ch022_ w2_ph048d1 w2_ph048d2 w2_ph048d3 w2_ph048d4 w2_ph048d5 ///
w2_currency  w2_pppx2007  w2_pppx2006  w2_pppx2005  w2_ph048d6 ///
w2_ph048d7 w2_ph048d8 w2_ph048d9 w2_ph048d10 w2_hnetwv w2_hhsize ///
w2_ph048dno w2_ph049d1 w2_ph049d2 w2_ph049d3 w2_ph049d4 w2_ph049d5 ///
w2_ph049d6 w2_ph049d9 w2_ph049d10 w2_ph049d11 ///
w2_ph049d12 w2_ph049dno
}

////////////////////
/* JOB SITUATION */
//////////////////
qui{ 
recode w1_ep005_ (-1=.) (-2=.) (6=.) (7=.) (97=.)
recode w2_ep005_ (-1=.) (-2=.) (6=.) (7=.) (97=.)
rename w1_ep005_ w1_job
rename w2_ep005_ w2_job
}

///////////////////////
/* RETIRED VARIABLE */
/////////////////////
qui {
generate retired=.
label var retired "Retired between waves and coming from the stated working group" 
*if retired from working then value of 2
replace retired=2 if w1_job==2 & w2_job==1
*if retired from unemployment value of 3
replace retired=3 if w1_job==3 & w2_job==1
*if retired from homemaker value of 5
replace retired=5 if w1_job==5 & w2_job==1
*if retired from permenantly sick value of 4
replace retired=4 if w1_job==4 & w2_job==1
label values retired ep005
}

/////////////////////////////////////////
/* FORMING "DOCTOR TOLD YOU" VARIABLE */
///////////////////////////////////////
qui {
generate w1_doctor=0
generate w2_doctor=0
forvalues i=1(1)14 {
recode w1_ph006d`i' (-2=.) (-1=.)
replace w1_doctor=w1_ph006d`i'+w1_doctor
drop w1_ph006d`i' 
}
forvalues i=1(1)14 {
recode w2_ph006d`i' (-2=.) (-1=.)
replace w2_doctor=w2_ph006d`i'+w2_doctor
drop w2_ph006d`i' 
}
recode w1_ph006dot (-2=.) (-1=.)
recode w2_ph006dot (-2=.) (-1=.)
replace w1_doctor=w1_ph006dot+w1_doctor
replace w2_doctor=w2_ph006dot+w2_doctor
drop w1_ph006dot w2_ph006dot
*Value of 0 if and only if the observation had "doctor told you have none" otherwise put value .
replace w1_doctor=. if w1_doctor==0
replace w1_doctor=0 if w1_ph006dno==1
drop w1_ph006dno
replace w2_doctor=. if w2_doctor==0
replace w2_doctor=0 if w2_ph006dno==1
drop w2_ph006dno
label var w1_doctor "How many health problems according to doctor"
label var w2_doctor "How many health problems according to doctor"
*Form Doctor change variable
gen doctorchange=.
label var doctorchange "Changes in doctor reported health"
replace doctorchange=w1_doctor-w2_doctor
replace doctorchange=. if w1_doctor==. | w2_doctor==.
replace doctorchange=1 if doctorchange==1 | doctorchange==2
replace doctorchange=-1 if doctorchange==-1 | doctorchange==-2
replace doctorchange=2 if doctorchange>2 & doctorchange!=.
replace doctorchange=-2 if doctorchange<-2 & doctorchange!=.
label define doctor 2 "Much better" 1 "Better" 0 "Same" -1 "Worse" -2 " Much worse"
label values doctorchange doctor
*Check if percentages of each case is ok or needs merging and tabulate
tab doctorchange if retired!=. , label
*Too few observations in much better/worse so merge in Better-Worse-Same
recode doctorchange (-2=-1) (2=1)
label define doctor2 1 "Better" -1 "Worse" 0 "Same"
label values doctorchange doctor2
tab doctorchange , gen(doctor)
}

//////////////////////////////////////
/* FORMING "DIFFICULTIES" VARIABLE */
////////////////////////////////////
qui {
generate w1_diff=0
generate w2_diff=0
forvalues i=1(1)10 {
recode w1_ph048d`i' (-2=.) (-1=.)
replace w1_diff=w1_ph048d`i'+w1_diff
drop w1_ph048d`i' 
}
forvalues i=1(1)10 {
recode w2_ph048d`i' (-2=.) (-1=.)
replace w2_diff=w2_ph048d`i'+w2_diff
drop w2_ph048d`i' 
}

rename w1_ph049d11 w1_ph049d7
rename w1_ph049d12 w1_ph049d8
rename w2_ph049d11 w2_ph049d7
rename w2_ph049d12 w2_ph049d8

forvalues i=1(1)10 {
recode w1_ph049d`i' (-2=.) (-1=.)
replace w1_diff=w1_ph049d`i'+w1_diff
drop w1_ph049d`i' 
}
forvalues i=1(1)10 {
recode w2_ph049d`i' (-2=.) (-1=.)
replace w2_diff=w2_ph049d`i'+w2_diff
drop w2_ph049d`i' 
}
*Value of 0 if and only if the observation had both "difficulties none" otherwise put value .
replace w1_diff=. if w1_diff==0
replace w1_diff=0 if w1_ph048dno==1 & w1_ph049dno==1
drop w1_ph048dno w1_ph049dno
replace w2_diff=. if w2_diff==0
replace w2_diff=0 if w2_ph048dno==1 & w2_ph049dno==1
drop w2_ph048dno w2_ph049dno
label var w1_diff "How many difficulties in everyday tasks (Physical activity)"
label var w2_diff "How many difficulties in everyday tasks (Physical activity)"
*Form difficulties change variable
gen diffchange=.
label var diffchange "Changes in difficulties"
replace diffchange =w1_diff-w2_diff
replace diffchange =. if w1_diff==. | w2_diff==.
replace diffchange =1 if diffchange ==1 | diffchange ==2
replace diffchange =-1 if diffchange ==-1 | diffchange ==-2
replace diffchange =2 if diffchange>2 & diffchange!=.
replace diffchange =-2 if diffchange <-2 & diffchange!=.
*Check if percentages of each case is ok or needs merging and tabulate
label values diffchange doctor
tab diffchange if retired!=. , label
*Too few observations in much better/worse so merge in Better-Worse-Same
recode diffchange (-2=-1) (2=1)
label values diffchange doctor2
tab diffchange , gen(diff)
}

///////////////////
/* AGE OF PEOPLE*/
/////////////////
qui {
generate w1_age=.
generate w2_age=.
label var w1_age "Age of participants at time of interview"
label var w2_age "Age of participants at time of interview"
*Take out all samples that did not report a year of birth
recode w1_yrbirth (-2=.) (-1=.)
replace w1_mobirth=. if w1_yrbirth==.
recode w2_yrbirth (-2=.) (-1=.)
replace w2_mobirth=. if w2_yrbirth==.
replace w1_age=w1_int_year-w1_yrbirth
replace w2_age=w1_int_year-w2_yrbirth
*if observation "refusal" or "don't know" for month of birth use value of 6 (average)
recode w1_mobirth (-2=6) (-1=6)
recode w2_mobirth (-2=6) (-1=6)
replace w1_age=w1_age+((w1_int_month-w1_mobirth)/12)
replace w2_age=w2_age+((w2_int_month-w2_mobirth)/12)
}

////////////
/* MONEY */
//////////
qui {
generate w1_networth=.
generate w2_networth=.
label var w1_networth "Networth of the individual's household"
label var w2_networth "Networth of the individual's household"
*No interviews in 2003 (wave 1) and 2005 (wave 2) so ppp variable for these years is irrelevant for us
replace w1_networth=w1_hnetwv*w1_pppx2004 if w1_int_year==2004
replace w1_networth=w1_hnetwv*w1_pppx2005 if w1_int_year==2005
replace w2_networth=w2_hnetwv*w2_pppx2006 if w2_int_year==2006
replace w2_networth=w2_hnetwv*w2_pppx2007 if w2_int_year==2007
*Divide all values from countries not using euro by the exchange rate with euro
replace w1_networth=w1_networth/w1_exrate if w1_currency!="Euro"
replace w2_networth=w2_networth/w2_exrate if w2_currency!="Euro"
*"Normalize" household values for each person according to the INSEE standards
replace w1_hhsize=((w1_hhsize-1)/2)+1
replace w2_hhsize=((w2_hhsize-1)/2)+1
replace w1_networth=w1_networth/w1_hhsize
replace w2_networth=w2_networth/w2_hhsize
*Take the average of both values to use later on
gen networth=.
label var networth "Networth of person calculated according to INSEE"
replace networth=((w1_networth+w2_networth)/2)
}

///////////////////////////////////////////
/* GRANDCHILDREN AND CHILDREN VARIABLES */
/////////////////////////////////////////
qui {
rename w1_ch022_ w1_grandchildren
rename w2_ch022_ w2_grandchildren
recode w2_grandchildren (-2=.) (-1=.)
rename w1_ch001_ w1_children
rename w2_ch001_ w2_children
replace w1_children=. if w1_children==-1 | w1_children==-2
replace w2_children=. if w2_children==-1 | w2_children==-2
replace w1_children=1 if w1_children>=1 & w1_children!=.
replace w1_children=0 if w1_children==0 & w1_children!=.
replace w2_children=0 if w2_children==0 & w2_children!=.
replace w2_children=1 if w2_children>=1 & w2_children!=.
label define child 1 "Yes" 0 "No"
*Form children in binary variable
gen children=.
gen grandchildren=.
label var children "Has children"
label var grandchildren "Has grandchildren"
replace children=1 if w1_children==1 | w2_children==1
replace children=0 if w1_children==0 | w2_children==0
replace grandchildren=1 if w1_grandchildren==1 | w2_grandchildren==1
replace grandchildren=0 if w1_grandchildren==5 | w2_grandchildren==5
label values children grandchildren child
}

////////////////////
/* MENTAL HEALTH */
//////////////////
qui {
recode w1_hc015d3 (-2=.) (-1=.)
recode w2_hc015d3 (-2=.) (-1=.)
rename w1_hc015d3 w1_mental
rename w2_hc015d3 w2_mental
*Form into binary of ever having a mental problem before the interviews
generate mental=.
label var mental "In hospital for mental reasons at least once one year before one or both waves"
replace mental=0 if w1_mental==0 | w2_mental==0
replace mental=1 if w1_mental==1 | w2_mental==1
}

/////////////
/* GENDER */
///////////
qui {
recode w1_gender (-2=.) (-1=.) (2=0)
recode w2_gender (-2=.) (-1=.) (2=0)
gen gender=.
label var gender "Gender of responder"
replace gender=1 if w1_gender==1 & w2_gender==1
replace gender=0 if w1_gender==0 & w2_gender==0
drop w1_gender w2_gender
label define gender1 1 "Male" 0 "Female"
label values gender gender1
}

///////////////////////////////////
/* RETIREMENT RELIEF OR CONCERN */
/////////////////////////////////
qui {
recode w1_ep065_ (-2=.) (-1=.)
recode w2_ep065_ (-2=.) (-1=.)
rename w1_ep065_ concern
drop w2_ep065_
}

///////////////
/* MARRIAGE */
/////////////
qui {
recode w1_dn014_ (-1=.) (-2=.)
recode w2_dn014_ (-1=.) (-2=.)
rename w1_dn014_ w1_marriage
rename w2_dn014_ w2_marriage
/*Marriage - Assume that if a person only answers in the 2nd this is his 1st wave answer as well
Also, we are interested mainly that marriage remains the same so make
dummy variable equal to 1 if situation remains the same or 0 if the person only
reports his marriage situation in one of the waves*/
replace w1_marriage=w2_marriage if w1_marriage==.
replace w2_marriage=w1_marriage if w2_marriage==.
gen marchange=.
label var marchange "Change of marriage situation between waves"
replace marchange=0 if w1_marriage-w2_marriage==0 
replace marchange=1 if w1_marriage-w2_marriage!=0
label define marr 1 "Yes" 0 "No"
label values marchange mental marr
*Tabulate
tab w1_marriage , gen(marriage)
rename w1_marriage marriage
}

/////////////////
/* DEPRESSION */
///////////////
qui{
rename w1_eurod w1_depression
rename w2_eurod w2_depression
*Form depression change variable
gen depressionchange=.
label var depressionchange "Changes in dipression"
replace depressionchange =w1_depression-w2_depression
replace depressionchange =. if w1_depression==. | w2_depression==.
replace depressionchange =1 if depressionchange ==1 | depressionchange ==2 | depressionchange==3
replace depressionchange =-1 if depressionchange ==-1 | depressionchange ==-2 | depressionchange==-3
replace depressionchange =2 if depressionchange>2 & depressionchange!=.
replace depressionchange =-2 if depressionchange <-2 & depressionchange!=.
*Check if percentages of each case is ok or needs merging and tabulate
label values depressionchange doctor
tab depressionchange if retired!=. , label
*Too few observations in much better/worse so merge in Better-Worse-Same
recode depressionchange (-2=-1) (2=1)
label values depressionchange doctor2
tab depressionchange , gen(depress)
}

//////////////
/* COUNTRY */
////////////
qui {
list w1_country w2_country if w1_country-w2_country!=0 & w1_country!=. & w2_country!=.
*No changes between 1st and 2nd wave so drop the 2nd wave
rename w1_country country
}

//////////////////////////////////////////
/* NOT-DEPRESSED PEOPLE (WAVE 1) DUMMY */
////////////////////////////////////////
qui {
gen depdummy=.
replace depdummy=1 if w1_depression==0
replace depdummy=0 if w1_depression!=. & w1_depression!=0
label define notdepressed 1 "Not Depressed Initially" 0 "Initially depressed"
label values depdummy notdepressed
}

///////////////////////////////////////////////////////////////////
/* TAKE AVERAGE OF 1ST AND 2ND WAVE AGE, USE TO MAKE AGE GROUPS */
/////////////////////////////////////////////////////////////////
qui {
generate age=.
label var age "Average age of responder between the waves"
replace age=((w1_age+w2_age)/2)
*Age groups 
gen agegroup=.
label var agegroup "Age Groups"
replace agegroup=1 if age<52
replace agegroup=2 if age>=52 & age<60
replace agegroup=3 if age>=60 & age<68
replace agegroup=4 if age>=68
label define agegroup 1 "Younger than 52" 2 "Between 52 and 60" 3 "Between 60 and 68" 4 "Older than 68"
*Check if percentages of each case is ok or needs merging and tabulate
label values agegroup agegroup
tab agegroup if retired!=., label
*Age group 1 is too small, combine it with 2 and tabulate
recode agegroup (1=2)
label define agegroup2 2 "60 or younger" 3 "Between 60 and 68" 4 "Older than 68"
label values agegroup agegroup2
tab agegroup , gen(agegroup)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/* DIVIDE PEOPLE IN POOR (30%) - MIDDLE CLASS (50%) - RICH (20%) DEPENDING ON THEIR NETWORTH AND COUNTRY */
//////////////////////////////////////////////////////////////////////////////////////////////////////////
qui {
generate class=.
generate middlelow=.
generate middlehigh=.
*Austria
_pctile networth if country==11 , p(30 , 80)
replace middlelow=`r(r1)' if country==11
replace middlehigh=`r(r2)' if country==11
*Belgium
_pctile networth if country==23 , p(30 , 80)
replace middlelow=`r(r1)' if country==23
replace middlehigh=`r(r2)' if country==23
*Denmark
_pctile networth if country==18 , p(30 , 80)
replace middlelow=`r(r1)' if country==18
replace middlehigh=`r(r2)' if country==18
*France
_pctile networth if country==17 , p(30 , 80)
replace middlelow=`r(r1)' if country==17
replace middlehigh=`r(r2)' if country==17
*Germany
_pctile networth if country==12 , p(30 , 80)
replace middlelow=`r(r1)' if country==12
replace middlehigh=`r(r2)' if country==12
*Greece
_pctile networth if country==19 , p(30 , 80)
replace middlelow=`r(r1)' if country==19
replace middlehigh=`r(r2)' if country==19
*Italy
_pctile networth if country==16 , p(30 , 80)
replace middlelow=`r(r1)' if country==16
replace middlehigh=`r(r2)' if country==16
*Netherlands
_pctile networth if country==14 , p(30 , 80)
replace middlelow=`r(r1)' if country==14
replace middlehigh=`r(r2)' if country==14
*Spain
_pctile networth if country==15 , p(30 , 80)
replace middlelow=`r(r1)' if country==15
replace middlehigh=`r(r2)' if country==15
*Sweden
_pctile networth if country==13 , p(30 , 80)
replace middlelow=`r(r1)' if country==13
replace middlehigh=`r(r2)' if country==13
*Switzerland
_pctile networth if country==20 , p(30 , 80)
replace middlelow=`r(r1)' if country==20
replace middlehigh=`r(r2)' if country==20
*Form the class variable & label it
replace class=1 if networth<=middlelow & middlelow!=. & middlehigh!=.
replace class=2 if networth>middlelow & networth<=middlehigh & middlelow!=. & middlehigh!=.
replace class=3 if networth>middlehigh & middlelow!=. & middlehigh!=.
label define class 1 "Lower Class" 2 "Middle Class" 3 "Upper Class"
*Check if percentages of each case are ok or need changing and of OK tabulate
label values class class
tab class if retired!=., label
tab class , gen(class)
}

//////////////
/* TABLE 1 */
////////////
qui {
summ w1_depression if marriage==1
summ w1_depression if marriage==2
summ w1_depression if marriage==3
summ w1_depression if marriage==4
summ w1_depression if marriage==5
summ w1_depression if marriage==6
summ w1_depression
}

//////////////
/* TABLE 2 */
////////////
qui {
mean w1_depression if retired==2, over (marriage)
mean w1_depression if retired==2
mean w2_depression if retired==2, over (marriage)
mean w2_depression if retired==2
mean w1_depression if retired==3, over (marriage)
mean w1_depression if retired==3
mean w2_depression if retired==3, over (marriage)
mean w2_depression if retired==3
mean w1_depression if retired==4, over (marriage)
mean w1_depression if retired==4
mean w2_depression if retired==4, over (marriage)
mean w2_depression if retired==4
mean w1_depression if retired==5, over (marriage)
mean w1_depression if retired==5
mean w2_depression if retired==5, over (marriage)
mean w2_depression if retired==5
mean w1_depression if retired==5 | retired==4 | retired==3 | retired==2, over (marriage)
mean w1_depression if retired==5 | retired==4 | retired==3 | retired==2
mean w2_depression if retired==5 | retired==4 | retired==3 | retired==2, over (marriage)
mean w2_depression if retired==5 | retired==4 | retired==3 | retired==2
}

//////////////
/* TABLE 3 */
////////////
qui {
sum w1_age if retired==2 | retired==3 | retired==4 | retired==5
sum w1_depression if retired==2 | retired==3 | retired==4 | retired==5
sum w1_grandchildren if retired==2 | retired==3 | retired==4 | retired==5
sum w1_children if retired==2 | retired==3 | retired==4 | retired==5
sum w1_doctor if retired==2 | retired==3 | retired==4 | retired==5
sum w1_diff if retired==2 | retired==3 | retired==4 | retired==5
sum w1_networth if retired==2 | retired==3 | retired==4 | retired==5
}

////////////////////////////////
/* DROP NOT NEEDED VARIABLES */
//////////////////////////////
qui {
drop w1_pppx2003 w1_pppx2004 w1_pppx2005 w2_pppx2005 w2_pppx2006 w2_pppx2007 w1_exrate w2_exrate ///
w1_int_year w2_int_year w1_hnetwv w2_hnetwv w1_currency w2_currency w1_mobirth w2_mobirth ///
w1_yrbirth w2_yrbirth w1_int_month w2_int_month w1_mental w2_mental w1_children ///
w2_children w1_grandchildren w2_grandchildren w1_networth w2_networth w1_hhsize w2_hhsize ///
w1_age w2_age w2_country w2_marriage
}

***************************************************************************************************************
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*  							    MULTINOMIAL LOGISTIC REGRESSION 									   */
////////////////////////////////////////////////////////////////////////////////////////////////////////////
***********************************************************************************************************

///////////////////////////
/*    INITIAL STUFF     */
/////////////////////////

*All retired individuals

*Mean, standard deviation, number of observations
tabstat doctor1-doctor3 depress1-depress3 agegroup1-agegroup3 class1-class3 gender ///
grandchildren marriage1-marriage6 concern depdummy if retired!=.,stat(mean sd n)
*Histogram
hist depressionchange if retired!=., percent

*Working individuals prior to retirement

*Mean, standard deviation, number of observations
tabstat doctor1-doctor3 agegroup1-agegroup3 class1-class3 gender ///
grandchildren marriage1-marriage6 concern depdummy if retired==2,stat(mean sd n)
*Histogram
hist depressionchange if retired!=2, percent

///////////////////////////////////////////
/*     IMPACT OF MARRIAGE SITUATION     */
/////////////////////////////////////////

*On a side note .jpg is not producing anything so we are using standard .gph

///////////////
/* EVERYONE */
/////////////
qui{
*Check how changes in different variables vary changes in depression
graph bar (mean) depressionchange if retired!=., over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(class) ytitle("Depression Change") nodraw
graph save graph_marriage_by_class_all, replace
graph bar (mean) depressionchange if retired!=., over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(gender) ytitle("Depression Change") nodraw
graph save graph_marriage_by_gender_all, replace
graph bar (mean) depressionchange if retired!=., over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(doctorchange) ytitle("Depression Change") nodraw
graph save graph_marriage_by_doctor_all, replace
graph bar (mean) depressionchange if retired!=., over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(grandchildren) ytitle("Depression Change") nodraw
graph save graph_marriage_by_grandchildren_all, replace
graph bar (mean) depressionchange if retired!=., over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(agegroup) ytitle("Depression Change") nodraw
graph save graph_marriage_by_agegroup_all, replace
*Check how different changes of depression (+ve, -ve, zero) vary accross different marital statuses 
hist marriage if depressionchange==0 & retired!=., percent saving(hist_depressionbymarriage1.gph, replace) ///
title("No Change") xlabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid") xtitle("") nodraw
hist marriage if depressionchange==1 & retired!=., percent saving(hist_depressionbymarriage2.gph, replace) ///
title("Less Depressed") xlabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid") xtitle("") nodraw
hist marriage if depressionchange==-1 & retired!=., percent saving(hist_depressionbymarriage3.gph, replace) ///
title("More Depressed") xlabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid") xtitle("") nodraw
graph combine hist_depressionbymarriage1.gph hist_depressionbymarriage2.gph hist_depressionbymarriage3.gph, ///
title("Depression Change by Marriage") xcommon nodraw
graph save graph_depression_by_marriage_all, replace
*Check how different changes of marital statuses vary accross different changes of depression
*(the opposite of the above!)
hist depressionchange if marriage==1 & retired!=., percent saving(hist_marriagebydepressionchange1.gph, replace) ///
title("Married") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==2 & retired!=., percent saving(hist_marriagebydepressionchange2.gph, replace) ///
title("Registered Couple") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==3 & retired!=., percent saving(hist_marriagebydepressionchange3.gph, replace) ///
title("Separated") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==4 & retired!=., percent saving(hist_marriagebydepressionchange4.gph, replace) ///
title("Never Married") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==5 & retired!=., percent saving(hist_marriagebydepressionchange5.gph, replace) ///
title("Divorced") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==6 & retired!=., percent saving(hist_marriagebydepressionchange6.gph, replace) ///
title("Widowed") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
graph combine hist_marriagebydepressionchange6.gph hist_marriagebydepressionchange5.gph ///
hist_marriagebydepressionchange4.gph hist_marriagebydepressionchange3.gph hist_marriagebydepressionchange2.gph ///
hist_marriagebydepressionchange1.gph, title("Marriage by Depression Change") xcommon nodraw
graph save graph_marriage_by_depression_all, replace
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange ib2.marriage if retired!=., robust
estimates store ologit_marriage_all
* Marginal effects
eststo mologit_marriage_all: margins, dydx(*) 
}

//////////////////////////////////
/* WORKING PRIOR TO RETIREMENT */
////////////////////////////////
qui {
*Check how changes in different variables vary changes in depression
graph bar (mean) depressionchange if retired==2, over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(class) ytitle("Depression Change")
graph save graph_income_by_marriage_working, replace
graph bar (mean) depressionchange if retired==2, over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(gender) ytitle("Depression Change") nodraw
graph save graph_marriage_by_gender_working, replace
graph bar (mean) depressionchange if retired==2, over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(diffchange) ytitle("Depression Change") nodraw
graph save graph_marriage_by_difficulties_working, replace 
graph bar (mean) depressionchange if retired==2, over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(doctorchange) ytitle("Depression Change") nodraw
graph save graph_marriage_by_doctor_working, replace
graph bar (mean) depressionchange if retired==2, over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(grandchildren) ytitle("Depression Change") nodraw
graph save graph_marriage_by_grandchildren_working, replace
graph bar (mean) depressionchange if retired==2, over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(mental) ytitle("Depression Change") nodraw
graph save graph_marriage_by_mental_working, replace
graph bar (mean) depressionchange if retired==2, over(marriage, ///
relabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid")) by(agegroup) ytitle("Depression Change") nodraw
graph save graph_marriage_by_agegroup_all, replace
*Check how different changes of depression (+ve, -ve, zero) vary accross different marital statuses 
hist marriage if depressionchange==0 & retired==2, percent saving(hist_depressionbymarriage1_working.gph, replace) ///
title("No Change")  xlabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid") xtitle("") nodraw 
hist marriage if depressionchange==1 & retired==2, percent saving(hist_depressionbymarriage2_working.gph, replace) ///
title("Less Depressed")  xlabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid") xtitle("") nodraw
hist marriage if depressionchange==-1 & retired==2, percent saving(hist_depressionbymarriage3_working.gph, replace) ///
title("More Depressed")  xlabel(1"Mar" 2"Reg" 3"Sep" 4"Nev" 5"Div" 6"Wid") xtitle("") nodraw
graph combine hist_depressionbymarriage1_working.gph hist_depressionbymarriage2_working.gph ///
hist_depressionbymarriage3_working.gph, title("Depression Change by Marriage") xcommon nodraw
graph save graph_depression_by_marriage_working, replace
*Check how different changes of marital statuses vary accross different changes of depression
hist depressionchange if marriage==1 & retired==2, percent saving(hist_marriagebydepressionchange1work.gph, replace) ///
title("Married") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==2 & retired==2, percent saving(hist_marriagebydepressionchange2work.gph, replace) ///
title("Registered Couple") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==3 & retired==2, percent saving(hist_marriagebydepressionchange3work.gph, replace) ///
title("Separated") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==4 & retired==2, percent saving(hist_marriagebydepressionchange4work.gph, replace) ///
title("Never Married") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==5 & retired==2, percent saving(hist_marriagebydepressionchange5work.gph, replace) ///
title("Divorced") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
hist depressionchange if marriage==6 & retired==2, percent saving(hist_marriagebydepressionchange6work.gph, replace) ///
title("Widowed") xlabel(1 "Less" -1 "More" 0 "No Change") xtitle("") nodraw
graph combine hist_marriagebydepressionchange6work.gph hist_marriagebydepressionchange5work.gph ///
hist_marriagebydepressionchange4work.gph hist_marriagebydepressionchange3work.gph hist_marriagebydepressionchange2work.gph ///
hist_marriagebydepressionchange1work.gph, title("Marriage by Depression Change") xcommon nodraw
graph save graph_marriage_by_depression_work, replace
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange ib2.marriage if retired==2, robust
estimates store ologit_marriage_working
* Marginal effects
eststo mologit_marriage_working: margins, dydx(*)
}

//////////////////////////////////////////////////
/*     IMPACT OF ALL EXPLANATORY VARIABLES     */
////////////////////////////////////////////////

///////////////
/* EVERYONE */
/////////////
qui {
global variables "i.depdummy doctor1-doctor3 i.agegroup i.class i.gender ib2.marriage"
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables if retired!=., robust difficult
estimates store ologit_all
*Marginal effects
eststo mologit_all: margins, dydx(*)
}

//////////////////////////////////
/* WORKING PRIOR TO RETIREMENT */
////////////////////////////////
qui {
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables if retired==2, robust difficult
estimates store ologit_working
*Marginal effects
eststo mologit_working: margins, dydx(*)
}

/////////////////////////////////////////
/*     DISPLAY ESTIMATION RESULTS     */
///////////////////////////////////////
estimates table mologit_all mologit_working mologit_marriage_working mologit_marriage_all ,star stats(N chi2 p ll) 

***************************************************************************************************************
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*  							    	    POSSIBLE EXTENSIONS 										   */
////////////////////////////////////////////////////////////////////////////////////////////////////////////
***********************************************************************************************************

***************************************************
//////////////////////////////////////////////////
/* CHANGE "DOCTOR" FOR "DIFFICULTIES" VARIABLE */
////////////////////////////////////////////////
***********************************************
qui {
///////////////
/* EVERYONE */
/////////////
global variables2 "i.depdummy diff1-diff3 i.agegroup i.class i.gender ib2.marriage"
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables2 if retired!=., robust difficult
estimates store ologit_all_3
*Marginal effects
eststo mologit_all_3: margins, dydx(*)

//////////////////////////////////
/* WORKING PRIOR TO RETIREMENT */
////////////////////////////////
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables2 if retired==2, robust difficult
estimates store ologit_work_3
*Marginal effects
eststo mologit_work_3: margins, dydx(*)
}

*******************************
//////////////////////////////
/* ADD "CHILDREN" VARIABLE */
////////////////////////////
***************************
qui {
///////////////
/* EVERYONE */
/////////////
global variables3 "i.depdummy doctor1-doctor3 i.agegroup i.class i.gender i.children ib2.marriage"
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables3 if retired!=., robust difficult
estimates store ologit_all_4
*Marginal effects
eststo mologit_all_4: margins, dydx(*)

//////////////////////////////////
/* WORKING PRIOR TO RETIREMENT */
////////////////////////////////
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables3 if retired==2, robust difficult
estimates store ologit_work_4
*Marginal effects
eststo mologit_work_4: margins, dydx(*)
}

*******************************
//////////////////////////////
/* ADD MENTAL HEALTH DUMMY */
////////////////////////////
***************************
qui {
///////////////
/* EVERYONE */
/////////////
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables i.mental if retired!=., robust difficult
estimates store ologit_all_5
*Marginal effects
eststo mologit_all_5: margins, dydx(*)

//////////////////////////////////
/* WORKING PRIOR TO RETIREMENT */
////////////////////////////////
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables i.mental if retired==2, robust difficult
estimates store ologit_work_5
*Marginal effects
eststo mologit_work_5: margins, dydx(*)
}

*********************************
////////////////////////////////
/* ADD MARRIAGE CHANGE DUMMY */
//////////////////////////////
*****************************
qui {
///////////////
/* EVERYONE */
/////////////
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables i.marchange if retired!=., robust difficult
estimates store ologit_all_6
*Marginal effects
eststo mologit_all_6: margins, dydx(*)

//////////////////////////////////
/* WORKING PRIOR TO RETIREMENT */
////////////////////////////////
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables i.marchange if retired==2, robust difficult
estimates store ologit_work_6
*Marginal effects
eststo mologit_work_6: margins, dydx(*)
}

*************************************************
////////////////////////////////////////////////
/*       DISPLAY EXTENSIONS RESULTS          */
//////////////////////////////////////////////
*********************************************
estimates table mologit_work_6 mologit_all_6 mologit_work_5 mologit_all_5 ///
mologit_work_4 mologit_all_4 mologit_work_3 mologit_all_3, star stats(N chi2 p ll) 

***************************************************************************************************************
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*  							    	    ROBUSTNESS CHECKS 											   */
////////////////////////////////////////////////////////////////////////////////////////////////////////////
***********************************************************************************************************

****************************************************
///////////////////////////////////////////////////
/* CHECK FOR NON-RETIRED INDIVIDUALS AGED 45-55 */
/////////////////////////////////////////////////
************************************************
qui {
//////////
/* ALL */
////////
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables if retired==. & age>=45 & age<55, robust
estimates store ologit_all1
* Marginal effects
eststo mologit_all1: margins, dydx(*) 

//////////////////////////
/* WORKING INDIVIDUALS */
////////////////////////
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables if retired==. & age>=45 & age<55 & w1_job==2, robust
estimates store ologit_work1
* Marginal effects
eststo mologit_work1: margins, dydx(*) 
}

****************************************
///////////////////////////////////////
/* CHECK FOR INDIVIDUALS AGED 68-78 */
/////////////////////////////////////
************************************
qui {
*Ordered logit of mode on alternative-invariant regressor
ologit depressionchange $variables if age>=68 & age<78, robust
estimates store ologit_2
* Marginal effects
eststo mologit_2: margins, dydx(*) 
}

*************************************************
////////////////////////////////////////////////
/*     DISPLAY ROBUSTNESS CHECKS RESULTS     */
//////////////////////////////////////////////
*********************************************
estimates table mologit_2 mologit_work1 mologit_all1, star stats(N chi2 p ll) 

log close
