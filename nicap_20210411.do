clear
version 13.0
set more off
set seed 20200901



/*------------------------------------------------------------
INITIAL SETUP & CLEANING
------------------------------------------------------------*/

* UPDATE `root' TO ROOT FOLDER
*local root "D:/Papers_in draft/CAP/Data"
*local	root "C:/Users/stephen.hearps/ownCloud/stephen.hearps (H)/NICAP"
*local	root "/Users/cogld/Desktop/adhd_workmem"
cd"/Users/cogld/Documents/adhd_workmem/"

use		"cog_data+freesurfer_SD.dta"
drop	if id_number == .

*merge	1:1 id_number using "/Volumes/Lexar/Papers_in draft/CAP/Data/ssrt_tracts_T1T2_SD.dta", force
merge	1:1 id_number using "ssrt_tracts_T1T2_SD.dta", force
*drop	if group_nicap==.

*define labelS and encode (label)
lab def	participate	0 "Did not complete" 1 "Completed" 
lab def	group1		1 "Control" 2 "ADHD"
lab def	group2		1 "Control - Persistent" 2 " High Risk" 3 " ADHD - Remitted" 4 "ADHD-Current"
*lab def handedness	1 "Left" 2 "Right" 
lab def	sex			1 "Male" 2 "Female"

foreach v of varlist w3MRIstatus w3MRIstatus2 w3MRIstatus3 {
	encode	`v', gen(`v'_x) lab(participate)
	order	`v'_x, after(`v')
	drop	`v'
	rename	`v'_x `v'
	}

foreach v of varlist group_w3 group_nicap2 {
	encode	`v', gen(`v'_x) lab(group2)
	order	`v'_x, after(`v')
	drop	`v'
	rename	`v'_x `v'
	}

encode	ChildGender2, gen(sex_x) lab(sex)
drop	ChildGender2
encode	c3_GroovedPegboardHand, gen(c3_GroovedPegboardHand_X) lab(handedness)
drop	c3_GroovedPegboardHand



*forcibly destring (numeric)
destring	c3_GroovedPegboardRTotal PDS_Adrogache PDSS w3MRI_age2 c3_PegboardOrder ///
			c3_NBackOrder c3_StopSignalOrder c3_SetShiftOrder c3_SARTOrder ///
			SART_Commission SART_dprime c3_GroovedPegboardLTotal c3_NBackComplete ///
			c3_NBackResultsSaved c3_StopSignalComplete c3_StopSignalResultsSaved ///
			c3_LandmarkComplete c3_PegboardComplete c3_LandmarkOrder, force replace

*encode p3_asd, generate(asd1)
gen		asd1 = . 
replace	asd1 = 1 if p3_asd == "Yes"
replace	asd1 = 0 if p3_asd == "No"
*replace asd1=. if asd1==""
	

*Check groupings - this needs work here - need to get correct variables
foreach x of varlist w3MRIdate ChildDOB w3CAdate {
	gen		`x'_2 = subinstr(`x', "/", "", .)
	gen		`x'_3 = string(real(`x'_2),"%06.0f")
	gen		`x'_4 = date(`x'_3, "DM20Y")
	format	`x'_4 %td
	}

drop	w3MRIdate w3MRIdate_2 w3MRIdate_3 ChildDOB ChildDOB_2 ChildDOB_3 ///
		w3CAdate w3CAdate_2 w3CAdate_3 nicap_participate

*drop ID 6242 as no group,demo data
drop	if id_number==6242

*New group variable - control group==1, ADHD group is those with a history of ADHD at CAP 1 or NICAP 1
gen		group_hx_adhd = .
replace group_hx_adhd = 1 if group == 2 & group_w3 == 1
replace group_hx_adhd = 3 if group == 4 & group_w3 == 7
replace group_hx_adhd = 2 if group == 1 | group_w3 == 4 | group_w3 == 6

drop	if group == 5

*no group label
replace	group_nicap2 = 4 if id_number == 6911

**Gen missing sex for ID 6911
replace sex_x = 1 if id_number == 6911

**Gen missing adhd subtype for IDs (inattentive=1, CT=2, hyper=3)
replace ADHD_subtype = 1 if inlist(id_number,718,2105,4264,4405,6207,6919,530,1028,1020,1127,2166,4325,5889)
replace	ADHD_subtype = 2 if inlist(id_number,642,2263,271,638,6911)
replace	ADHD_subtype = 3 if inlist(id_number,2582,1162,4209,7242)

*drop high-risk group (high risk at wave 1 and wave 3)
drop	if group_hx_adhd == 3


*drop those who didn't participate in W3
drop	if group_w3 == 5

*Drop ID with technical issues
drop	if inlist(id_number,5363,2309,5639,7031,2474,6669,0208,2202,5459,1860)
	
	


/*-------------------------------------------------------------*
CAP Study
*-------------------------------------------------------------*/

*generate varaible for medication status for ADHD group at w3
*gen ADHD_med_w3=p3_adhdmedication_curr
*replace ADHD_med_w3=0 if p3_adhdmedication_curr==.

replace	p3_adhdmedication_curr = 0 if ///
		(p3_adhdmedication_curr == . & group_hx_adhd == 1) | ///
		inlist(id_number,2704,4405,5889)

replace ADHD_subtype=0 if group_hx_adhd==1

*Drop if did not complete nback or missing data
drop	if c3_NBackComplete == 0 | ///
		c3_NBackComplete == . | ///
		c3_nback_b_total_hits == . | ///
		c3_nback_b_total_hits_2 == .

****CAP W3 WITH NBACK DATA

*Check for effect of medication on nback performance - 
*check para and non-parametric. No differences between med and non med groups
ttest c3_nback_b_d_2, by(p3_adhdmedication_curr)


/*------------------------------------------------------------
summary tables - use exact when exp cells are less than 5
------------------------------------------------------------*/

*Summary tables
*Sex
tab		group_hx_adhd sex, row chi2 exact exp

*Age at assessment
bysort	group_hx_adhd: sum c3_childage
ttest	c3_childage, by(group_hx_adhd)

*handedness
tab		group_hx_adhd handed, row chi2 exact exp

*IQ
bysort	group_hx_adhd: sum c1_iq_sts
ttest	c1_iq_sts, by(group_hx_adhd)

*SES
bysort	group_hx_adhd: sum IRSADScore 
ttest	IRSADScore, by(group_hx_adhd)

*Medication
tab		group_hx_adhd p3_adhdmedication_curr, row chi2 exact exp

*ADHD Subtype
tab		group_hx_adhd ADHD_subtype, row chi2 exact exp

*Comorbid ASD
tab		group_hx_adhd asd1, row chi2 exact exp

*Parent SDQ hyperactivity, dichotimous
tab		group_hx_adhd p1_sdqhyper_dich, row chi2 exact

*Teacher SDQ hyperactivity, dichitimous
tab		group_hx_adhd t1_sdqhyper_dich, row chi2 exact


/*------------------------------------------------------------
*3 -Nback data visualisation

c3_nback_b_total_hits: neg skewed - transform
c3_nback_b_total_misses: pos skewed
c3_nback_b_total_fa: pos skewed - leave and apply negbinomial
c3_nback_b_total_hitrt:neg skewed - log
c3_nback_b_total_hitrtvar:neg skewed - log
c3_nback_b_total_corrrej:neg skewed - transform
c3_nback_b_d: neg skewed - transform
c3_nback_b_c: normal
c3_nback_b_betabias: pos skewed - leave and apply negbinomial

c3_nback_b_total_hits_2: neg skewed- transform
c3_nback_b_total_misses_2:
c3_nback_b_total_fa_2: pos skewed - leave and apply negbinomial
c3_nback_b_total_hitrt_2: neg skewed - log
c3_nback_b_total_hitrtvar_2: neg skewed - log
c3_nback_b_total_corrrej_2: neg skewed- transform
c3_nback_b_d_2: neg skew - transform
c3_nback_b_c_2: normal
c3_nback_b_betabias_2: pos skew - leave and apply neg binomial

total_symptoms, d3_ad_hypsym_y, d3_ad_inattsym_y: all neg binomial for 1, normal for 2
p3_adhdmedication_curr: binary? 


group variables: group_hx_adhd

List of all nback variables:
c3_nback_b_total_hits
c3_nback_b_total_misses_2
c3_nback_b_total_fa
c3_nback_b_total_hitrt
c3_nback_b_total_hitrtvar
c3_nback_b_total_corrrej
c3_nback_b_d
c3_nback_b_c
c3_nback_b_betabias
c3_nback_b_total_hits_2
c3_nback_b_total_fa_2
c3_nback_b_total_hitrt_2
c3_nback_b_total_hitrtvar_2
c3_nback_b_total_corrrej_2
c3_nback_b_d_2
c3_nback_b_c_2
c3_nback_b_betabias_2

List of symptom outcomes:
total_symptoms, d3_ad_hypsym_y, d3_ad_inattsym_y

Medication variable:
p3_adhdmedication_curr


------------------------------------------------------------*/

/*histogasm btw groups	
	hist c3_nback_b_total_hits, by(group_hx_adhd) discrete
	hist c3_nback_b_total_misses, by(group_hx_adhd) discrete
	hist c3_nback_b_total_fa, by(group_hx_adhd) discrete
	hist c3_nback_b_total_hitrt, by(group_hx_adhd)
	hist c3_nback_b_total_hitrtvar, by(group_hx_adhd)
	hist c3_nback_b_total_corrrej, by(group_hx_adhd) discrete
	hist c3_nback_b_d, by(group_hx_adhd)
	hist c3_nback_b_c, by(group_hx_adhd)
	hist c3_nback_b_betabias, by(group_hx_adhd)
	
	hist c3_nback_b_total_hits_2, by(group_hx_adhd) discrete
	hist c3_nback_b_total_misses_2, by(group_hx_adhd) discrete
	hist c3_nback_b_total_fa_2, by(group_hx_adhd) discrete
	hist c3_nback_b_total_hitrt_2, by(group_hx_adhd)
	hist c3_nback_b_total_hitrtvar_2, by(group_hx_adhd)

	hist c3_nback_b_total_corrrej_2, by(group_hx_adhd) discrete
	hist c3_nback_b_d_2, by(group_hx_adhd)
	hist c3_nback_b_c_2, by(group_hx_adhd)
	hist c3_nback_b_betabias_2, by(group_hx_adhd)
	
	hist total_symptoms, by(group_hx_adhd) discrete
	hist d3_ad_hypsym_y, by(group_hx_adhd) discrete 
	hist d3_ad_inattsym_y, by(group_hx_adhd) discrete
	
	hist p3_adhdmedication_curr, by(group_hx_adhd) discrete
*/

/*------------------------------------------------------------
log transform rt and rtvariability variables
------------------------------------------------------------*/

foreach	x in c3_nback_b_total_hitrt c3_nback_b_total_hitrtvar ///
		c3_nback_b_total_hitrt_2 c3_nback_b_total_hitrtvar_2 {
			gen `x'_log = log(`x')
			}
	
	
	
/*------------------------------------------------------------
visualise log transformed data

hist c3_nback_b_total_hitrt_log, by(group_hx_adhd)
hist c3_nback_b_total_hitrtvar_log, by(group_hx_adhd)
hist c3_nback_b_total_hitrt_2_log, by(group_hx_adhd)
hist c3_nback_b_total_hitrtvar_2_log, by(group_hx_adhd)

------------------------------------------------------------*/




		
/*------------------------------------------------------------
reverse transform neg skewed variables
------------------------------------------------------------*/
	
foreach	x in c3_nback_b_total_corrrej c3_nback_b_d ///
		c3_nback_b_total_corrrej_2 c3_nback_b_d_2 {
			summ `x'
			gen `x'_trans = abs(`r(max)'-`x')
			}
		
/*------------------------------------------------------------
make negative values positive - shift x axis by +1
------------------------------------------------------------*/

foreach	x in c3_nback_b_c c3_nback_b_c_2 {
		gen `x'_trans = `x'+2
		}
	
	
/*------------------------------------------------------------
Check OLS for model fit
- none fit so progress to negbinom or poisson
------------------------------------------------------------*/	
/*
foreach x in c3_nback_b_total_misses c3_nback_b_total_fa c3_nback_b_total_misses_2 ///
	c3_nback_b_total_fa_2 c3_nback_b_d c3_nback_b_d_2 c3_nback_b_total_corrrej ///
	c3_nback_b_betabias c3_nback_b_total_corrrej_2 c3_nback_b_betabias_2 {
		reg `x' i.group_hx_adhd p3_adhdmedication_curr
		predict rstan_`x', rstan
		hist rstan_`x'
		lvr2plot, mlabel(id) name(lvr2_`x') replace
		}
*/

/*------------------------------------------------------------
check neg binomial assumptions:

summ for overdispersion and tab for zero inflation

c3_nback_b_total_misses: not overdispersed, zero inflated
c3_nback_b_total_fa: not overD, zero imflated
c3_nback_b_total_corrrej: not overD not zeroI
c3_nback_b_d: not overD not zeroI
c3_nback_b_betabias: not overD not zeroI
c3_nback_b_total_misses_2: not overdispercted, zeroI
c3_nback_b_total_fa_2: overdispersed, zero infl
c3_nback_b_total_corrrej_2: not and not
c3_nback_b_d_2 - needs to be transformed, some neg vals
c3_nback_b_betabias_2: not and not

check model fit - looking at deviance and pearson on RHS 
- need to be close to 1
------------------------------------------------------------*/



*Check model fit statistics
glm c3_nback_b_total_misses				group_hx_adhd p3_adhdmedication_curr, ///
	family(gaussian) eform
glm c3_nback_b_d_trans					group_hx_adhd p3_adhdmedication_curr, ///
	family (gaussian) eform
glm c3_nback_b_total_corrrej_trans		group_hx_adhd p3_adhdmedication_curr, ///
	family(nbinomial) eform
glm c3_nback_b_total_misses_2			group_hx_adhd p3_adhdmedication_curr, ///
	family(nbinomial) eform
glm c3_nback_b_d_2_trans				group_hx_adhd p3_adhdmedication_curr, ///
	family(poisson) eform
glm c3_nback_b_total_corrrej_2_trans	group_hx_adhd p3_adhdmedication_curr, ///
	family(nbinomial) eform
glm c3_nback_b_c_trans					group_hx_adhd p3_adhdmedication_curr, ///
	family(gaussian) eform
glm c3_nback_b_c_2_trans				group_hx_adhd p3_adhdmedication_curr, ///
	family(gaussian) eform
glm c3_nback_b_total_hitrt_log			group_hx_adhd p3_adhdmedication_curr, ///
	family(gaussian) eform
glm c3_nback_b_total_hitrt_2_log		group_hx_adhd p3_adhdmedication_curr, ///
	family(gaussian) eform
glm c3_nback_b_total_hitrtvar_log		group_hx_adhd p3_adhdmedication_curr, ///
	family(gaussian) eform
glm c3_nback_b_total_hitrtvar_2_log		group_hx_adhd p3_adhdmedication_curr, ///
	family(gaussian) eform
glm c3_nback_b_betabias					group_hx_adhd p3_adhdmedication_curr, ///
	family(gaussian) eform
glm c3_nback_b_betabias_2				group_hx_adhd p3_adhdmedication_curr, ///
	family(nbinomial) eform





/*------------------------------------------------------------
Check to see difference in performance between ADHD medicated 
and not on nback outcomes - no difference
------------------------------------------------------------*/

foreach x in `nback' {	// local defined?
	ranksum `x', by(p3_adhdmedication_curr)
	}



/*------------------------------------------------------------
Difference between groups controlling for medication

NB Regression
 - assumptions
 1. count data
 2. overdispertion 
 3. Independence of observations

Regression Diagnostics (vanilla)
	
	Use: to visualise transformation:
	*gladder [var]
	*ladder [var]
 
------------------------------------------------------------*/


*Regressions for total group with total symptoms - note - need to run whole syntax to get to NICAP sample, then come back to here to run	
*zero inflated and overdispersed
foreach x in c3_nback_b_total_misses c3_nback_b_total_fa c3_nback_b_total_misses_2 ///
	c3_nback_b_total_fa_2 c3_nback_b_d_trans c3_nback_b_d_2_trans {
		qui zip `x' total_symptoms p3_adhdmedication_curr sex c3_childage, ///
			inflate(i.group_hx_adhd) irr
		di	"`x'" _col(40) %10.0f e(N) %10.4f exp(_b[total_symptoms]) ///
			%10.4f exp(_se[total_symptoms]) ///
			%10.4f 2*(1-normal(abs(_b[total_symptoms]/_se[total_symptoms])))
		}

*not overdispersed or zero inflated
foreach x in c3_nback_b_total_corrrej_trans c3_nback_b_betabias ///
	c3_nback_b_total_corrrej_2_trans c3_nback_b_betabias_2 {
		qui nbreg `x' total_symptoms p3_adhdmedication_curr sex c3_childage, irr
		di	"`x'" _col(40) %10.0f e(N) %10.4f exp(_b[total_symptoms]) ///
			%10.4f exp(_se[total_symptoms]) ///
			%10.4f 2*(1-normal(abs(_b[total_symptoms]/_se[total_symptoms])))
		}

*Normal data
foreach x in c3_nback_b_c_trans c3_nback_b_c_2_trans c3_nback_b_total_hitrt_log ///
	c3_nback_b_total_hitrtvar_log c3_nback_b_total_hitrt_2_log ///
	c3_nback_b_total_hitrtvar_2_log {
		qui reg `x' total_symptoms p3_adhdmedication_curr sex c3_childage
		di	"`x'" _col(40) %10.0f e(N) %10.4f (_b[total_symptoms]) ///
			%10.4f (_se[total_symptoms]) ///
			%10.4f 2* ttail(e(df_r), abs(_b[total_symptoms]/_se[total_symptoms]))
		}

	
*Regressions for total group with hyperactive symptoms
	
*zero inflated and overdispersed
foreach x in c3_nback_b_total_misses c3_nback_b_total_fa c3_nback_b_total_misses_2 ///
	c3_nback_b_total_fa_2 c3_nback_b_d_trans c3_nback_b_d_2_trans {
		qui zip `x' d3_ad_hypsym_y p3_adhdmedication_curr sex c3_childage, ///
			inflate(i.group_hx_adhd) irr
		di	"`x'" _col(40) %10.0f e(N) %10.4f exp(_b[d3_ad_hypsym_y]) ///
			%10.4f exp(_se[d3_ad_hypsym_y]) ///
			%10.4f 2*(1-normal(abs(_b[d3_ad_hypsym_y]/_se[d3_ad_hypsym_y])))
		}

*not overdispersed or zero inflated
foreach x in c3_nback_b_total_corrrej_trans c3_nback_b_betabias ///
	c3_nback_b_total_corrrej_2_trans c3_nback_b_betabias_2 {
		qui nbreg `x' d3_ad_hypsym_y p3_adhdmedication_curr sex c3_childage, irr
		di	"`x'" _col(40) %10.0f e(N) %10.4f exp(_b[d3_ad_hypsym_y]) ///
			%10.4f exp(_se[d3_ad_hypsym_y]) ///
			%10.4f 2*(1-normal(abs(_b[d3_ad_hypsym_y]/_se[d3_ad_hypsym_y])))
		}

*Normal data
foreach x in c3_nback_b_c_trans c3_nback_b_c_2_trans c3_nback_b_total_hitrt_log ///
	c3_nback_b_total_hitrtvar_log c3_nback_b_total_hitrt_2_log ///
	c3_nback_b_total_hitrtvar_2_log {
		qui reg `x' d3_ad_hypsym_y p3_adhdmedication_curr sex c3_childage
		di	"`x'" _col(40) %10.0f e(N) %10.4f (_b[d3_ad_hypsym_y]) ///
			%10.4f (_se[d3_ad_hypsym_y]) ///
			%10.4f 2* ttail(e(df_r), abs(_b[d3_ad_hypsym_y]/_se[d3_ad_hypsym_y]))
		}
		

*Regressions for total group with hyperactive symptoms
	
*zero inflated and overdispersed
foreach x in c3_nback_b_total_misses c3_nback_b_total_fa c3_nback_b_total_misses_2 ///
	c3_nback_b_total_fa_2 c3_nback_b_d_trans c3_nback_b_d_2_trans {
		qui zip `x' d3_ad_inattsym_y p3_adhdmedication_curr sex c3_childage, ///
			inflate(i.group_hx_adhd) irr
		di	"`x'" _col(40) %10.0f e(N) %10.4f exp(_b[d3_ad_inattsym_y]) ///
			%10.4f exp(_se[d3_ad_inattsym_y]) ///
			%10.4f 2*(1-normal(abs(_b[d3_ad_inattsym_y]/_se[d3_ad_inattsym_y])))
		}

*not overdispersed or zero inflated
foreach x in c3_nback_b_total_corrrej_trans c3_nback_b_betabias ///
	c3_nback_b_total_corrrej_2_trans c3_nback_b_betabias_2 {
		qui nbreg `x' d3_ad_inattsym_y p3_adhdmedication_curr sex c3_childage, irr
		di	"`x'" _col(40) %10.0f e(N) %10.4f exp(_b[d3_ad_inattsym_y]) ///
			%10.4f exp(_se[d3_ad_inattsym_y]) ///
			%10.4f 2*(1-normal(abs(_b[d3_ad_inattsym_y]/_se[d3_ad_inattsym_y])))
		}

*Normal data
foreach x in c3_nback_b_c_trans c3_nback_b_c_2_trans c3_nback_b_total_hitrt_log ///
	c3_nback_b_total_hitrtvar_log c3_nback_b_total_hitrt_2_log ///
	c3_nback_b_total_hitrtvar_2_log {
		qui reg `x' d3_ad_inattsym_y p3_adhdmedication_curr sex c3_childage
		di	"`x'" _col(40) %10.0f e(N) %10.4f (_b[d3_ad_inattsym_y]) ///
			%10.4f (_se[d3_ad_inattsym_y]) ///
			%10.4f 2* ttail(e(df_r), abs(_b[d3_ad_inattsym_y]/_se[d3_ad_inattsym_y]))
		}


 

local	nback c3_nback_b_total_misses c3_nback_b_total_fa c3_nback_b_total_misses_2 ///
		c3_nback_b_total_fa_2 c3_nback_b_d_trans c3_nback_b_d_2_trans ///
		c3_nback_b_betabias c3_nback_b_betabias_2 c3_nback_b_c_trans ///
		c3_nback_b_c_2_trans c3_nback_b_total_hitrt_log c3_nback_b_total_hitrtvar_log ///
		c3_nback_b_total_hitrt_2_log c3_nback_b_total_hitrtvar_2_log 

local	nback c3_nback_b_d c3_nback_b_d_2 ///
		c3_nback_b_c c3_nback_b_c_2 ///
		c3_nback_b_total_hitrt c3_nback_b_total_hitrtvar ///
		c3_nback_b_total_hitrt_2 c3_nback_b_total_hitrtvar_2 
	
*partial correlation controlling for medication by using groups
foreach x in `nback' {
	pcorr `x' total_symptoms group_hx_adhd 
	}

	
*correlations for CAP group with ADHD symptoms	
local	nback c3_nback_b_total_misses c3_nback_b_total_fa c3_nback_b_c_trans ///
		c3_nback_b_d_trans c3_nback_b_total_hitrt_log c3_nback_b_total_hitrtvar_log ///
		c3_nback_b_total_misses_2 c3_nback_b_total_fa_2  c3_nback_b_c_2_trans ///
		c3_nback_b_d_2_trans c3_nback_b_total_hitrt_2_log c3_nback_b_total_hitrtvar_2_log 

	
pwcorr `nback' total_symptoms, star(0.05)
		

		
***Check OLS for transformed nback varaibles
/*
foreach x in c3_nback_b_total_misses {
	reg `x' i.group_hx_adhd p3_adhdmedication_curr
	predict rstan_`x', rstan
	hist rstan_`x'
	lvr2plot, mlabel(id)
	predict cooksd_`dx', cooks
	}

	**outcome no leveage points
	reg c3_nback_b_c_trans i.group_hx_adhd p3_adhdmedication_curr
	predict rstan_c1, rstan
	hist rstan_c1
	lvr2plot, mlabel(id)
	predict cooksd_c1, cooks
	
	**outcome - no leverage points
	reg c3_nback_b_c_2_trans i.group_hx_adhd p3_adhdmedication_curr
	predict rstan_c2, rstan
	hist rstan_c2
	lvr2plot, mlabel(id)
	predict cooksd_c2, cooks
	
	**outcome - 2051 leverage point - reran without this ID and results are the same so leave in
	reg c3_nback_b_total_hitrt_log i.group_hx_adhd p3_adhdmedication_curr
	predict rstan_rt1, rstan
	hist rstan_rt1
	lvr2plot, mlabel(id)
	predict cooksd_rt1, cooks
	
	
	**outcome - 4576, 2498 leverage point - reran without these IDs and results are the same so leave in
	reg c3_nback_b_total_hitrt_2_log i.group_hx_adhd p3_adhdmedication_curr
	predict rstan_rt2, rstan
	hist rstan_rt2
	lvr2plot, mlabel(id)
	predict cooksd_rt2, cooks
	
	**outcome - 6461, 6392, 2051, 71 leverage point - dropped these IDs and reran, got sme results so leave them in
	reg c3_nback_b_total_hitrtvar_log i.group_hx_adhd p3_adhdmedication_curr
	predict rstan_rtvar2, rstan
	hist rstan_rtvar2
	lvr2plot, mlabel(id)
	predict cooksd_rtvar2, cooks

*/

/*------------------------------------------------------------
Correlation between symptoms and nback outcomes - 
not sure how to control for categorical fx (medication)
------------------------------------------------------------*/
pwcorr `nback' total_symptoms ///
		d3_ad_hypsym_y d3_ad_inattsym_y, star(0.05)
	
		
pwcorr `nback' total_symptoms ///
		d3_ad_hypsym_y d3_ad_inattsym_y if group_hx_adhd==1, star(0.05)

/*
*partial correlation
*foreach x in `nback' {
		pcorr `x' total_symptoms p3_adhdmedication_curr 
		}
*/		
	
/*------------------------------------------------------------
Comparrision of NICAP and non-NICAP sample
- Generate nicap group
- Generate proportionate volumes
------------------------------------------------------------*/
gen		nicapgroup = 1
replace nicapgroup = 0 if w3MRIstatus==0 | w3MRIstatus==2 

*Generate proportionate imaging variables
gen		WM = CorticalWhiteMatterVol/ICV
gen		GM = TotalGrayVol/ICV
gen		surfacearea = LSurfArea2+RSurfArea2
gen		thickness = Lthickness2 + RThickness2


foreach	x in L_SLF1_th_bin_vol L_SLF2_th_bin_vol L_SLF3_th_bin_vol ///
		R_SLF1_th_bin_vol R_SLF2_th_bin_vol R_SLF3_th_bin_vol ///
		L_SLF1_AFD_m L_SLF2_AFD_m L_SLF3_AFD_m R_SLF1_AFD_m ///
		R_SLF2_AFD_m R_SLF3_AFD_m L_SLF1_th_bin_FA_m L_SLF2_th_bin_FA_m ///
		L_SLF3_th_bin_FA_m R_SLF1_th_bin_FA_m R_SLF2_th_bin_FA_m ///
		R_SLF3_th_bin_FA_m {
		    replace `x' = . if `x' == 0
			}
	
foreach	x in ICV L_SLF1_th_bin_vol L_SLF2_th_bin_vol L_SLF3_th_bin_vol ///
		R_SLF1_th_bin_vol R_SLF2_th_bin_vol R_SLF3_th_bin_vol ///
		L_SLF1_AFD_m L_SLF2_AFD_m L_SLF3_AFD_m R_SLF1_AFD_m ///
		R_SLF2_AFD_m R_SLF3_AFD_m ///
		L_SLF1_th_bin_FA_m L_SLF2_th_bin_FA_m L_SLF3_th_bin_FA_m ///
		R_SLF1_th_bin_FA_m R_SLF2_th_bin_FA_m R_SLF3_th_bin_FA_m ///
		L_SLF1_th_bin_MD_m L_SLF2_th_bin_MD_m L_SLF3_th_bin_MD_m ///
		R_SLF1_th_bin_MD_m R_SLF2_th_bin_MD_m R_SLF3_th_bin_MD_m ///
		L_SLF1_th_bin_AD_m L_SLF2_th_bin_AD_m L_SLF3_th_bin_AD_m ///
		R_SLF1_th_bin_AD_m R_SLF2_th_bin_AD_m R_SLF3_th_bin_AD_m ///
		L_SLF1_th_bin_RD_m L_SLF2_th_bin_RD_m L_SLF3_th_bin_RD_m ///
		R_SLF1_th_bin_RD_m R_SLF2_th_bin_RD_m R_SLF3_th_bin_RD_m {
			replace nicapgroup=0 if `x'==.
			}


/*------------------------------------------------------------
Compare nicap and non-nicap sample on demographics
------------------------------------------------------------*/

*Summary tables
*Sex
ttest	sex, by(nicapgroup)
tab		nicapgroup sex, row chi2 exact exp

*Age at assessment
bysort nicapgroup: sum c3_childage
ttest	c3_childage, by(nicapgroup)

*handedness
tab		nicapgroup handed, row chi2 exact exp

*IQ
bysort	nicapgroup: sum c1_iq_sts
ttest	c1_iq_sts, by(nicapgroup)

*SES
bysort	nicapgroup: sum IRSADScore 
ttest	IRSADScore, by(nicapgroup)

*Medication
tab		nicapgroup p3_adhdmedication_curr, row chi2 exact exp

*ADHD Subtype
tab		nicapgroup ADHD_subtype, row chi2 exact exp




/*-------------------------------------------------------------*
NICAP Study
*-------------------------------------------------------------*/


/*------------------------------------------------------------
Clean up missing data
------------------------------------------------------------*/

*Drop if did not complete MRI	
drop if w3MRIstatus==0 | w3MRIstatus==2
	
/*------------------------------------------------------------
Generate proportional imaging outcomes 
and drop those with missing data
------------------------------------------------------------*/


*Generate proportional volumes for frontal and parietal regions
foreach	x in lh_lateralorbitofrontal_volume rh_lateralorbitofrontal_volume ///
		lh_medialorbitofrontal_volume rh_medialorbitofrontal_volume ///
		lh_rostralmiddlefrontal_volume rh_rostralmiddlefrontal_volume ///
		lh_superiorfrontal_volume rh_superiorfrontal_volume ///
		lh_superiorparietal_volume rh_superiorparietal_volume ///
		lh_frontalpole_volume rh_frontalpole_volume ///
		lh_parsopercularis_volume rh_parsopercularis_volume ///
		lh_parsorbitalis_volume rh_parsorbitalis_volume ///
		lh_parstriangularis_volume rh_parstriangularis_volume ///
		lh_precentral_volume rh_precentral_volume lh_paracentral_volume ///
		rh_paracentral_volume lh_inferiorparietal_volume ///
		rh_inferiorparietal_volume lh_inferiortemporal_volume ///
		rh_inferiortemporal_volume lh_supramarginal_volume ///
		rh_supramarginal_volume lh_postcentral_volume rh_postcentral_volume ///
		lh_precuneus_volume rh_precuneus_volume {
			gen `x'_p = `x'/ICV
			}

foreach	x of varlist ICV L_SLF1_th_bin_vol L_SLF2_th_bin_vol L_SLF3_th_bin_vol ///
		R_SLF1_th_bin_vol R_SLF2_th_bin_vol R_SLF3_th_bin_vol ///
		L_SLF1_AFD_m L_SLF2_AFD_m L_SLF3_AFD_m ///
		R_SLF1_AFD_m R_SLF2_AFD_m R_SLF3_AFD_m ///
		L_SLF1_th_bin_FA_m L_SLF2_th_bin_FA_m ///
		L_SLF3_th_bin_FA_m R_SLF1_th_bin_FA_m ///
		R_SLF2_th_bin_FA_m R_SLF3_th_bin_FA_m ///
		L_SLF1_th_bin_MD_m L_SLF2_th_bin_MD_m ///
		L_SLF3_th_bin_MD_m R_SLF1_th_bin_MD_m ///
		R_SLF2_th_bin_MD_m R_SLF3_th_bin_MD_m ///
		L_SLF1_th_bin_AD_m L_SLF2_th_bin_AD_m ///
		L_SLF3_th_bin_AD_m R_SLF1_th_bin_AD_m ///
		R_SLF2_th_bin_AD_m R_SLF3_th_bin_AD_m ///
		L_SLF1_th_bin_RD_m L_SLF2_th_bin_RD_m ///
		L_SLF3_th_bin_RD_m R_SLF1_th_bin_RD_m ///
		R_SLF2_th_bin_RD_m R_SLF3_th_bin_RD_m {
			drop if `x'==.
			}


/*------------------------------------------------------------
Check to see if theres a difference on imaging outcomes 
between medicated and non-medicated ADHD group 
- no significant differences
------------------------------------------------------------*/

local	imaging_vars L_SLF1_th_bin_vol L_SLF2_th_bin_vol L_SLF3_th_bin_vol ///
		R_SLF1_th_bin_vol R_SLF2_th_bin_vol R_SLF3_th_bin_vol ///
		L_SLF1_AFD_m L_SLF2_AFD_m L_SLF3_AFD_m R_SLF1_AFD_m R_SLF2_AFD_m ///
		R_SLF3_AFD_m L_SLF1_th_bin_FA_m L_SLF2_th_bin_FA_m L_SLF3_th_bin_FA_m ///
		R_SLF1_th_bin_FA_m R_SLF2_th_bin_FA_m R_SLF3_th_bin_FA_m
		
foreach	x in `imaging_vars' {
		ranksum `x', by(p3_adhdmedication_curr)
		}
		
foreach	x in `imaging_vars' {
		replace `x'=. if `x'==0
		}
		
foreach x in `imaging_vars' {
		drop if `x'==.
		}





/*------------------------------------------------------------
 Table 2 - use exact when exp cells are less than 5
------------------------------------------------------------*/

*Summary tables
*Sex
tab		group_hx_adhd sex, row chi2 exact exp

*Age at assessment
bysort	group_hx_adhd: sum c3_childage
ttest	c3_childage, by(group_hx_adhd)

*handedness
tab		group_hx_adhd handed, row chi2 exact exp

*IQ
bysort	group_hx_adhd: sum c1_iq_sts
ttest	c1_iq_sts, by(group_hx_adhd)

*SES
bysort	group_hx_adhd: sum IRSADScore 
ttest	IRSADScore, by(group_hx_adhd)

*Medication
tab		group_hx_adhd p3_adhdmedication_curr, row chi2 exact exp

*ADHD Subtype
tab		group_hx_adhd ADHD_subtype, row chi2 exact exp

*Comorbid ASD
tab		group_hx_adhd asd1, row chi2 exact exp

*Parent SDQ hyperactivity, dichotimous
tab		group_hx_adhd p1_sdqhyper_dich, row chi2 exact

*Teacher SDQ hyperactivity, dichitimous
tab		group_hx_adhd t1_sdqhyper_dich, row chi2 exact



 
/*------------------------------------------------------------
nback regressions - controlling for medication
"3.1.2 Group differences in SLF microstructure"
------------------------------------------------------------*/


foreach x in L_SLF1_th_bin_vol L_SLF2_th_bin_vol L_SLF3_th_bin_vol ///
		R_SLF1_th_bin_vol R_SLF2_th_bin_vol R_SLF3_th_bin_vol {
			qui reg `x' i.group_hx_adhd p3_adhdmedication_curr i.sex c3_childage
			if (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))<0.05 {
				di	%12.2f _b[2.group_hx_adhd] "*" _col(20) %12.2f _se[2.group_hx_adhd] ///
					%12.4f (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))
				}
			else {
				di	%12.2f _b[2.group_hx_adhd] _col(20) %12.2f _se[2.group_hx_adhd] ///
					%12.4f (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))
				}
			}
foreach x in L_SLF1_AFD_m L_SLF2_AFD_m L_SLF3_AFD_m R_SLF1_AFD_m ///
		R_SLF2_AFD_m R_SLF3_AFD_m {
			qui reg `x' i.group_hx_adhd p3_adhdmedication_curr i.sex c3_childage
			if (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))<0.05 {
				di	%12.4f _b[2.group_hx_adhd]*1000 "*" _col(20) %12.4f _se[2.group_hx_adhd]*1000 ///
					%12.4f (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))
				}
			else {
				di	%12.4f _b[2.group_hx_adhd]*1000 _col(20) %12.4f _se[2.group_hx_adhd]*1000 ///
					%12.4f (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))
				}
			}
foreach	x in L_SLF1_th_bin_FA_m L_SLF2_th_bin_FA_m L_SLF3_th_bin_FA_m ///
		R_SLF1_th_bin_FA_m R_SLF2_th_bin_FA_m R_SLF3_th_bin_FA_m {
			qui reg `x' i.group_hx_adhd p3_adhdmedication_curr i.sex c3_childage
			if (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))<0.05 {
				di	%12.4f _b[2.group_hx_adhd]*1000 "*" _col(20) %12.4f _se[2.group_hx_adhd]*1000 ///
					%12.4f (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))
				}
			else {
				di	%12.4f _b[2.group_hx_adhd]*1000 _col(20) %12.4f _se[2.group_hx_adhd]*1000 ///
					%12.4f (2 * ttail(e(df_r), abs(_b[2.group_hx_adhd]/_se[2.group_hx_adhd])))
				}
			}
	
	


/*------------------------------------------------------------
Table 3 
3.1.1
------------------------------------------------------------*/

*Regressions for total group with Working Memory outcomes 

*zero inflated and overdispersed
foreach	x in c3_nback_b_total_misses c3_nback_b_total_fa c3_nback_b_total_misses_2 ///
		c3_nback_b_total_fa_2 c3_nback_b_d_trans c3_nback_b_d_2_trans {
			qui zip		`x' group_hx_adhd p3_adhdmedication_curr sex c3_childage, inflate(i.group_hx_adhd) irr
			di			"`x'" _col(40) %10.0f e(N) %10.4f exp(_b[group_hx_adhd]) ///
							%10.4f exp(_se[group_hx_adhd]) ///
							%10.4f 2*(1-normal(abs(_b[group_hx_adhd]/_se[group_hx_adhd])))
			}

*not overdispersed or zero inflated
foreach	x in c3_nback_b_total_corrrej_trans c3_nback_b_betabias ///
		c3_nback_b_total_corrrej_2_trans c3_nback_b_betabias_2 {
			qui nbreg	`x' group_hx_adhd p3_adhdmedication_curr sex c3_childage, irr
			di			"`x'" _col(40) %10.0f e(N) %10.4f exp(_b[group_hx_adhd]) ///
							%10.4f exp(_se[group_hx_adhd]) ///
							%10.4f 2*(1-normal(abs(_b[group_hx_adhd]/_se[group_hx_adhd])))
			}

*Normal data
foreach	x in c3_nback_b_c_trans c3_nback_b_c_2_trans c3_nback_b_total_hitrt_log ///
		c3_nback_b_total_hitrtvar_log c3_nback_b_total_hitrt_2_log ///
		c3_nback_b_total_hitrtvar_2_log {
			qui reg		`x' group_hx_adhd p3_adhdmedication_curr sex c3_childage
			di			"`x'" _col(40) %10.0f e(N) %10.4f (_b[group_hx_adhd]) ///
							%10.4f  (_se[group_hx_adhd]) ///
							%10.4f 2* ttail(e(df_r), abs(_b[group_hx_adhd]/_se[group_hx_adhd]))
			}
	
	

	
/*------------------------------------------------------------
Table 4
3.1.3
------------------------------------------------------------*/
	
*Regression significant nback outcomes on imaging outcomes
*with sig main effect of group or model

local	imaging L_SLF2_th_bin_vol L_SLF2_AFD_m
	
local	nbacksig c3_nback_b_total_misses_2 c3_nback_b_total_fa_2 ///
		c3_nback_b_d_2_trans c3_nback_b_total_hitrt_2_log ///
		c3_nback_b_total_hitrtvar_2_log


foreach i in L_SLF2_th_bin_vol {
	foreach n in `nbacksig' {
		qui reg `n' c.`i' p3_adhdmedication_curr i.sex c3_childage
		if (2 * ttail(e(df_r), abs(_b[c.`i']/_se[c.`i'])))<0.05 {
			di	"`n'" _col(40) "`i'" _col(80) %12.2f _b[c.`i']*1000000 "*" ///
				_col(100) %12.2f _se[c.`i']*1000000 ///
				%12.4f (2 * ttail(e(df_r), abs(_b[c.`i']/_se[c.`i'])))
			}
		else {
			di	"`n'" _col(40) "`i'" _col(80) %12.2f _b[c.`i']*1000000 ///
				_col(100) %12.2f _se[c.`i']*1000000 ///
				%12.4f (2 * ttail(e(df_r), abs(_b[c.`i']/_se[c.`i'])))
			}
		}
	}
foreach i in L_SLF2_AFD_m {
	foreach n in `nbacksig' {
		qui reg `n' c.`i' p3_adhdmedication_curr i.sex c3_childage
		if (2 * ttail(e(df_r), abs(_b[c.`i']/_se[c.`i'])))<0.05 {
			di	"`n'" _col(40) "`i'" _col(80) %12.2f _b[c.`i'] "*" ///
				_col(100) %12.2f _se[c.`i'] ///
				%12.4f (2 * ttail(e(df_r), abs(_b[c.`i']/_se[c.`i'])))
			}
		else {
			di	"`n'" _col(40) "`i'" _col(80) %12.2f _b[c.`i'] ///
				_col(100) %12.2f _se[c.`i'] ///
				%12.4f (2 * ttail(e(df_r), abs(_b[c.`i']/_se[c.`i'])))
			}
		}
	}

	
	