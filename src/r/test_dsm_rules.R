# Script: test_dsm_rules.R
# Purpose: Check the DSM rules from functions_dsm_rules.R in two ways:
#            (1) on the real data: do the rebuilt diagnoses (rule_) match
#                the diagnoses in the dataset (dx_) for every participant?
#            (2) on made-up participants placed exactly at a cutoff (or just
#                below it), because that is where mistakes like ">" instead
#                of ">=" would show up.
#          Run from the project folder (where data/ is).
# Date: 2026-10-18

#-------------------------------------------------------------------
# 1. LOAD FUNCTIONS & DATA
# dplyr is loaded in functions_dsm_rules.R
#-------------------------------------------------------------------
source("src/r/functions_data.R")          # load_mental_illness()
source("src/r/functions_variable_key.R")  # make_variable_key()
source("src/r/functions_dsm_rules.R")     # apply_dsm_rules() and the test helpers

variable_key <- make_variable_key()
clindata <- load_mental_illness("data/Mentalillness.csv", variable_key)
clindata <- apply_dsm_rules(clindata, variable_key)


#-------------------------------------------------------------------
# 2. CHECK 1: DO THE RULES REPRODUCE THE DATASET?
# For each disorder: how many participants have the diagnosis in the
# data, how many by our rule, and for how many rows the two agree.
#-------------------------------------------------------------------
disorders <- c("bipolar", "depression", "anxiety", "schizophrenia", "ptsd")
rule_check <- data.frame()

for (disorder in disorders) {
  observed <- clindata[[paste0("dx_", disorder)]]
  rebuilt  <- clindata[[paste0("rule_", disorder)]]
  n_match  <- sum(observed == rebuilt)
  
  rule_check <- rbind(rule_check, data.frame(
    disorder      = disorder,
    n_observed    = sum(observed),
    n_rebuilt     = sum(rebuilt),
    n_match       = n_match,
    percent_match = round(100 * n_match / nrow(clindata), 2)
  ))
}

print(rule_check)

if (all(rule_check$n_match == nrow(clindata))) {
  message("All five diagnoses are reproduced exactly (",
          nrow(clindata), " of ", nrow(clindata), " rows).")
} else {
  message("Not all diagnoses match: see the n_match column.")
}

#-------------------------------------------------------------------
# 3. CHECK 2: EDGE CASES ON MADE-UP PARTICIPANTS
# Each block below:
#   a) makes a few test people with all symptoms at 0
#   b) switches on the symptoms needed for the test
#   c) runs apply_dsm_rules() and checks the diagnosis
#-------------------------------------------------------------------
test_names <- c()
test_passed <- c()

# --- Bipolar: at least 3 of 7 symptoms ---
bip <- get_columns(variable_key, "bipolar", "symptom")
people <- make_test_people(clindata, variable_key, 2)
people[1, bip[1:3]] <- 1   # exactly 3 -> diagnosed
people[2, bip[1:2]] <- 1   # only 2    -> not diagnosed
result <- apply_dsm_rules(people, variable_key)

name <- "Bipolar: 3 symptoms = yes, 2 = no"
test_names <- c(test_names, name)
test_passed <- c(test_passed, check_result(name, result$rule_bipolar, c(1, 0)))

# --- Depression: at least 5 of 9 symptoms ---
dep <- get_columns(variable_key, "depression", "symptom")
people <- make_test_people(clindata, variable_key, 2)
people[1, dep[1:5]] <- 1   # exactly 5 -> diagnosed
people[2, dep[1:4]] <- 1   # only 4    -> not diagnosed
result <- apply_dsm_rules(people, variable_key)

name <- "Depression: 5 symptoms = yes, 4 = no"
test_names <- c(test_names, name)
test_passed <- c(test_passed, check_result(name, result$rule_depression, c(1, 0)))

# --- Anxiety: at least 2 of 6 symptoms AND 6-month duration ---
anx <- get_columns(variable_key, "anxiety", "symptom")
people <- make_test_people(clindata, variable_key, 3)
people[1, anx[1:2]] <- 1                 # 2 symptoms + duration -> yes
people[1, "anx_duration_6_months"] <- 1
people[2, anx[1:2]] <- 1                 # 2 symptoms, no duration -> no
people[3, anx[1]] <- 1                   # 1 symptom + duration -> no
people[3, "anx_duration_6_months"] <- 1
result <- apply_dsm_rules(people, variable_key)

name <- "Anxiety: needs 2 symptoms AND duration"
test_names <- c(test_names, name)
test_passed <- c(test_passed, check_result(name, result$rule_anxiety, c(1, 0, 0)))

# --- Schizophrenia: >= 1 positive AND >= 2 items in total ---
scz_positive <- get_columns(variable_key, "schizophrenia", "positive")
scz_other    <- get_columns(variable_key, "schizophrenia", "other")
people <- make_test_people(clindata, variable_key, 4)
people[1, scz_positive[1]] <- 1          # 1 positive + 1 other -> yes
people[1, scz_other[1]] <- 1
people[2, scz_positive[1]] <- 1          # 1 positive + duration -> yes
people[2, "scz_duration_1_month"] <- 1   # (duration counts as an item)
people[3, scz_other[1:2]] <- 1           # 2 other, no positive -> no
people[4, scz_positive[1]] <- 1          # 1 positive only -> no
result <- apply_dsm_rules(people, variable_key)

name <- "Schizophrenia: positive symptom needed, 2 items in total"
test_names <- c(test_names, name)
test_passed <- c(test_passed, check_result(name, result$rule_schizophrenia, c(1, 1, 0, 0)))

# --- PTSD: A>=1, B>=1, C>=1, D>=2, E>=2, and F, G, H present ---
ptsd_A <- get_columns(variable_key, "ptsd", "A_exposure")
ptsd_B <- get_columns(variable_key, "ptsd", "B_intrusion")
ptsd_C <- get_columns(variable_key, "ptsd", "C_avoidance")
ptsd_D <- get_columns(variable_key, "ptsd", "D_cognition_mood")
ptsd_E <- get_columns(variable_key, "ptsd", "E_arousal")
ptsd_FGH <- get_columns(variable_key, "ptsd", c("F_duration", "G_distress", "H_not_substance"))

# The smallest set of items that meets every criterion
ptsd_minimum <- c(ptsd_A[1], ptsd_B[1], ptsd_C[1],
                  ptsd_D[1:2], ptsd_E[1:2], ptsd_FGH)

people <- make_test_people(clindata, variable_key, 3)
people[1:3, ptsd_minimum] <- 1           # everyone starts at the minimum
people[2, "ptsd_clinical_distress"] <- 0 # person 2: no G -> no
people[3, ptsd_D[2]] <- 0                # person 3: only 1 D item -> no
result <- apply_dsm_rules(people, variable_key)

name <- "PTSD: all minimums = yes, missing G or 1 D item = no"
test_names <- c(test_names, name)
test_passed <- c(test_passed, check_result(name, result$rule_ptsd, c(1, 0, 0)))

# --- Thresholds: changing a threshold changes the diagnosis ---
people <- make_test_people(clindata, variable_key, 1)
people[1, bip[1:2]] <- 1                 # 2 bipolar symptoms
th <- default_thresholds
th$bipolar <- 2                          # lower the cutoff to 2
result <- apply_dsm_rules(people, variable_key, th)

name <- "Thresholds: bipolar cutoff 2 diagnoses someone with 2 symptoms"
test_names <- c(test_names, name)
test_passed <- c(test_passed, check_result(name, result$rule_bipolar, 1))

#-------------------------------------------------------------------
# 4. SUMMARY
#-------------------------------------------------------------------
test_results <- data.frame(test = test_names, passed = test_passed)
print(test_results)

n_failed <- sum(!test_passed)
if (n_failed == 0) {
  message("All ", length(test_passed), " tests passed.")
} else {
  message(n_failed, " of ", length(test_passed), " tests failed.")
}

