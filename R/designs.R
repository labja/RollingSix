# Determines next dose and checks if stop criteria are reached
#
# design The dose-finding design which is employed. Possible options are "RollingSix" for Rolling Six.
# tox_rates Vector of true toxicity rates for each dose level in ascending order
# start Dose level to be used at the beginning of the trial
# res_dlt Known DLT results for each patient
# res_time Known time results for each patient
# t Current time point in days from start of trial

determine_dose <- function(design,tox_rates,start,res_dlt,res_time,t) {
  
  if (nrow(res_dlt)==0) {
    
    # If no patients have been observed before pick the starting dose level
    stop <- FALSE
    dose <- start
    res_list <- list(stop=stop, dose=dose,t=t)
    
  } else {
    
    res_list <- switch(design
                       #, BCRM=determine_dose_crm(res_dlt_known=res_dlt_known,stop_bcrm=stop_bcrm,prior=prior,target=target,constrain=constrain,method_bcrm=method_bcrm,t=t)
                       #, TPT=determine_dose_tpt(res_dlt_known=res_dlt_known,res_dlt=res_dlt,t=t)
                       , RollingSix=determine_dose_r6(res_dlt=res_dlt,res_time=res_time,t=t,tox_rates=tox_rates)) 
    stop <- res_list$stop
    dose <- res_list$dose
    t <- res_list$t
  
  }
  
  return(res_list)
  
}

# Determines MTD once the trial is stopped

determine_mtd <- function(design,res_dlt) {
  

    
    mtd_est <- switch(design
                       #, BCRM=determine_dose_crm(res_dlt_known=res_dlt_known,stop_bcrm=stop_bcrm,prior=prior,target=target,constrain=constrain,method_bcrm=method_bcrm,t=t)
                       #, TPT=determine_dose_tpt(res_dlt_known=res_dlt_known,res_dlt=res_dlt,t=t)
                       , RollingSix=determine_mtd_r6(res_dlt=res_dlt)) 

     return(mtd_est)
  
}


# Determines next dose for Rolling Six

determine_dose_r6 <- function(res_dlt,res_time,t,tox_rates) {
  
  # Summarize results so far
  res <- merge(res_dlt,res_time)
  all_summary <- res %>% group_by(dose) %>% summarise(n=n(),n_dlt=sum(dlt),.groups="drop_last")
  pending_summary <- res %>% filter(t_end_treat > t) %>% group_by(dose) %>% summarise(n=n(),n_dlt=sum(dlt),.groups="drop_last")
  known_summary <- res %>% filter(t_end_treat <= t) %>% group_by(dose) %>% summarise(n=n(),n_dlt=sum(dlt),.groups="drop_last")
  
  # Determine last dose
  last_dose <- max(1,res_dlt$dose[nrow(res_dlt)])
  
  # Set t to a later time if previous patients at last dose had to wait
  t_last_dose_last_start <- res %>% filter(dose==last_dose) %>% select(t_start_treat) %>% last()
  t <- max(t,t_last_dose_last_start)
  
  # Look up escalation decision in lookup table
  n_pat <- all_summary %>% filter(dose==last_dose) %>% select(n) %>% as.numeric()
  n_pending <- pending_summary %>% filter(dose==last_dose) %>% select(n) %>% as.numeric() %>% tidyr::replace_na(0)
  n_dlt <- known_summary %>% filter(dose==last_dose) %>% select(n_dlt) %>% as.numeric() %>% tidyr::replace_na(0)
  decision <- sysdata$decision[decision_table$n_pat==n_pat & sysdata$n_dlt==n_dlt & sysdata$n_pending==n_pending]
  
  
  if (decision=="Suspend") {
    
    # 6 patients have been assigned to last dose and some results are pending -> wait
    t <- max(res_time$t_end_treat) 
    dose_decision <- determine_dose_r6(res_dlt=res_dlt,res_time=res_time,t=t,tox_rates=tox_rates)
    new_dose <- dose_decision$dose
    stop <- stopcheck_r6(res_summary=all_summary,new_dose=new_dose,tox_rates=tox_rates)
    
    
  } else if (decision %in% c("Escalate","De-escalate")) {
    
    # Not necessary to wait -> determine next dose right away
    new_dose <- ifelse(decision=="Escalate",last_dose+1,last_dose-1)
    
    # If the next dose is different it needs to be checked if recruitment at that dose is still intended 
    # If the dose decision from the lower dose is escalation and the dose decision from the higher dose is de-escalation pick the lower dose
     new_dose1 <- determine_dose_r6_help(res_summary=known_summary,last_dose=new_dose)
     if (new_dose!=new_dose1) new_dose <- min(new_dose,new_dose1)
     
     # Check if stop criteria are reached
     stop <- stopcheck_r6(res_summary=known_summary,new_dose=new_dose,tox_rates=tox_rates)
      
    } else if (decision=="Stay") {
    
    new_dose <- last_dose  
    stop <- FALSE
    
    }
  
  return(list(stop=stop,dose=new_dose,t=t))
  
}

# Checks if stop criteria are reached for Rolling Six

stopcheck_r6 <- function(res_summary,new_dose,tox_rates) {
  
  stop <- FALSE
  
  same_dose <- res_summary %>% filter(dose==new_dose)
  
  if (new_dose > length(tox_rates)) stop <- TRUE 
  if (new_dose < 1) stop <- TRUE
  if (nrow(same_dose)>0) if (same_dose$n==6 | same_dose$n_dlt>=2) stop <- TRUE
  
  return(stop)
  
}

# Determines MTD for Rolling Six

determine_mtd_r6 <- function(res_dlt) {
  
  res_dlt_summary <- res_dlt %>% group_by(dose) %>% summarise(n=n(),n_dlt=sum(dlt),.groups="drop_last")
  
  # Filter for all dose levels which could be the MTD
  possible_mtd <- res_dlt_summary %>% mutate(possible_mtd=(n>=3 & n_dlt==0) | (n==6 & n_dlt==1)) %>%
    filter(possible_mtd) 
  
  # If none of the dose levels are possible as the MTD set mtd_est to 0. Otherwise choose highest possible dose level.
  mtd_est <- max(possible_mtd$dose,0)
  
  return(mtd_est)
  
}
