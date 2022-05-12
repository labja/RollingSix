# RollingSix

## Installation

You can install this package from GitHub with
``` r
# install.packages("devtools")
devtools::install_github("labja/RollingSix")
```

## Example

### Setting parameters 
``` r
library(IntraPat)
design <- "RollingSix"
tox_rates <- seq(0.1,0.5,0.1)
futime <- 50
accrual <- 50
nsim <- 10
seed <- 1
```
So far there are no alternative design choices. futime is follow up time in days and accrual is expected number of patients recruited in a year.

### Simulating a single trial
``` r
set.seed(seed)
single_trial <- sim_trial(tox_rates=tox_rates,design=design,futime=futime,accrual=accrual)
single_trial$res
# Result of simulated trial
```
