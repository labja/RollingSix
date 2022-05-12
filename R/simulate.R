# Simulates multiple trials 

# Arguments
# tox_rates: Vector of true toxicity rates for each dose level in ascending order
# days: How many days the intrapatient dose escalation lasts
# n: Number of patients
# intra: Whether there is an intrapatient dose escalation stage or not
# nsim: How many trials are simulated

# Return
# Data frame with number of patients, number of dlt and estimated mtd for each trial

#' Simulates multiple trials  
#'
#' @param design Thedose-finding design which is employed. Possible options are "RollingSix" for Rolling Six.
#' @param tox_rates Vector of true toxicity rates for each dose level in ascending order
#' @param cohortsize Number of patients in a cohort
#' @param start Dose level to be used at the beginning of the trial 
#' @param parallel_recruit Whether recruitment is parallel or sequential. If FALSE recruitment is sequential i.e. recruitment is suspended until all DLT results are known 
#' @param futime Follow-up time in days
#' @param accrual Expected number of patients to be recruited in a year
#' @param nsim Number of simulated trials
#' @param seed Seed for simulation
#' @return res Data frame with key numbers for each trial
#' 
#' @examples
#'
#' sim_trials(design="RollingSix",tox_rates=seq(0.1,0.5,0.1),futime=50,accrual=50,nsim=10)


# BCRM parameter: stop_bcrm,prior,constrain,method_bcrm, target
 

sim_trials <- function(design,tox_rates,cohortsize=1,start=1,
                       parallel_recruit=TRUE,futime,accrual,
                       nsim,seed=1) {
  
  set.seed(seed)
  
  # Initialize result data frame
  res <- data.frame(mtd_est=numeric(nsim),n_pat=numeric(nsim),n_dlt=numeric(nsim),
                    n_wait=numeric(nsim),median_wait=numeric(nsim),
                    total_wait=numeric(nsim),trial_duration=numeric(nsim))
  

  # Simulate individual trials and save key numbers
  for (i in 1:nsim) {
    
    print(paste("Trial",i,sep=" "))
    
    summary <- summary_trial(sim_trial(design=design,tox_rates=tox_rates,
                   cohortsize=cohortsize,start=start,parallel_recruit=parallel_recruit,
                   futime=futime,accrual=accrual))
    
    res$mtd_est[i] <-summary$mtd_est
    res$n_pat[i] <- summary$n_pat
    res$n_dlt[i] <- summary$n_dlt
    res$n_wait[i] <- summary$n_wait
    res$median_wait[i] <- summary$median_wait
    res$total_wait[i] <- summary$total_wait
    res$trial_duration[i] <- summary$trial_duration

  }
  
  
  input <- list(design=design,tox_rates=tox_rates,
                cohortsize=cohortsize,start=start,parallel_recruit=parallel_recruit,
                futime=futime,accrual=accrual,nsim=nsim,seed=seed)
  
  return(list(res=res,input=input))
}


#' Simulates a single trial
#'
#' @param design The dose-finding design which is employed. Possible options are "RollingSix" for Rolling Six.
#' @param tox_rates Vector of true toxicity rates for each dose level in ascending order
#' @param cohortsize Number of patients in a cohort
#' @param start Dose level to be used at the beginning of the trial 
#' @param parallel_recruit Whether recruitment is parallel or sequential. If FALSE recruitment is sequential i.e. recruitment is suspended until all DLT results are known 
#' @param futime Follow-up time in days
#' @param accrual Expected number of patients to be recruited in a year
#' @return res_dlt Data frame with dose level and DLT result for each patient
#' @return res_time Data frame with important time points in days since trial start for each patient
#' 
#' @examples
#'
#' sim_trial(design="RollingSix",tox_rates=seq(0.1,0.5,0.1),futime=50,accrual=50)
 
sim_trial <- function(design,tox_rates,cohortsize=1,start=1,
                      parallel_recruit=TRUE,futime,accrual) {
  
  
  # Initialize result data frames
  res_dlt <- data.frame(pat=numeric(),dose=numeric(),dlt=logical())
  res_time <- data.frame(pat=numeric(),t_start_recruit=numeric(),t_recruited=numeric(),t_start_treat=numeric(),t_end_treat=numeric())
  
  # Initialize patient number
  i <- 1
  
  # Initialize time
  t <- 0
  
  stop <- FALSE
  
  while(!stop) {
    
    # Determine time points for current cohort
    t_start_recruit <- t
    t_accrual <- sim_accrual(accrual=accrual,cohortsize=cohortsize)
    t_recruited <- t+cumsum(t_accrual)
    t <- max(t_recruited)
    
    pat <- i:(i+cohortsize-1)
    
    # Determine next dose and check if any stop criteria are reached
    dose_decision <- determine_dose(res_dlt=res_dlt,res_time=res_time,t=t,start=start,design=design,tox_rates=tox_rates)
    stop <- dose_decision$stop
    dose <- dose_decision$dose
    t_start_treat <- dose_decision$t
    
    # If trial is stopped determine the estimated MTD
    if (stop) { 
      mtd_est <- determine_mtd(design=design,res_dlt=res_dlt)
      break
    }
    
    # Simulate new DLT result
    sim_dlt_res <- sim_dlt(tox_rates=tox_rates,dose=dose,futime=futime,cohortsize=cohortsize)
    
    # Update result data frames
    new_dlt <- data.frame(pat=pat,dose=dose,dlt=sim_dlt_res$dlt)
    res_dlt <- rbind(res_dlt,new_dlt)
    new_time <- data.frame(pat=pat,t_start_recruit=t_start_recruit,t_recruited=t_recruited,t_start_treat=t_start_treat,t_end_treat=t_start_treat+sim_dlt_res$time_to_eot)
    res_time <- rbind(res_time,new_time)
    
    # Update patient counter and time
    i <- i + cohortsize
    t <- ifelse(parallel_recruit,max(res_time$t_recruited),max(res_time$t_end_treat))

  }
  
  return(list(res_dlt=res_dlt,res_time=res_time,mtd_est=mtd_est))
}



# Simulates time until a patient is recruited

# accrual Expected number of patients to be recruited in a year
# cohortsize Number of patients in a cohort

sim_accrual <- function(accrual,cohortsize) {
  
  t_accrual <- ceiling(rexp(cohortsize,accrual/365))
  return(t_accrual)
}

# Simulates whether DLT occurs or not

# tox_rates Vector of true toxicity rates for each dose level in ascending order
# dose Integer corresponding to the element of tox_rates vector
# cohortsize Number of patients in a cohort


sim_dlt <- function(tox_rates,dose,futime,cohortsize) {
  
  dlt <- rbinom(n = cohortsize, size = 1, prob = tox_rates[dose])
  time_to_eot <- ifelse(dlt,ceiling(runif(1, 0, futime)),futime)
  
  return(list(dlt=dlt,time_to_eot=time_to_eot))
}

#' Summarizes the result of a single simulated trial
#'
#' @param res Output from \code{sim_trial} 

summary_trial <- function(res) {
  
  mtd_est <- res$mtd_est
  n_pat <- max(res$res_dlt$pat)
  n_dlt <- sum(res$res_dlt$dlt)
  n_wait <- sum(res$res_time$t_recruited!=res$res_time$t_start_treat)
  ind_wait <- ifelse(res$res_time$t_recruited!=res$res_time$t_start_treat,res$res_time$t_start_treat - res$res_time$t_recruited,NA)
  median_wait <- median(ind_wait,na.rm=TRUE)
  total_wait <- sum(res$res_time$t_start_treat - res$res_time$t_recruited)
  trial_duration <- max(res$res_time$t_end_treat)
  
  return(list(mtd_est=mtd_est,n_pat=n_pat,n_dlt=n_dlt,n_wait=n_wait,median_wait=median_wait,
              total_wait=total_wait,trial_duration=trial_duration))
}


