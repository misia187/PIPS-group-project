# Script: analyses.R
# Purpose: Run the statistical analyses on the Mentalillness dataset and
#          save the result tables:
#            (1) one chi-square test 
#            (2) every symptom x every diagnosis (265 tests, FDR-corrected)
#            (3) comorbidity: observed vs expected for every pair of diagnoses
#            (4) proportion diagnosed at each symptom count
#          Uses the functions in functions_analysis.R and functions_dsm_rules.R.
#          Run from the project folder (where data/ is).
# Date: 2026-10-19

#-------------------------------------------------------------------
# 1. LOAD FUNCTIONS & DATA
# dplyr is loaded in functions_dsm_rules.R; the tests themselves are base R.
#-------------------------------------------------------------------
source("src/r/functions_data.R")          # load_mental_illness()
source("src/r/functions_variable_key.R")  # make_variable_key()
source("src/r/functions_dsm_rules.R")     # apply_dsm_rules()
source("src/r/functions_analysis.R")      # 2x2 tests, test_comorbidity()

variable_key <- make_variable_key()
clindata <- load_mental_illness("data/Mentalillness.csv", variable_key)
clindata <- apply_dsm_rules(clindata, variable_key)  # adds the n_ count columns

disorders <- c("bipolar", "schizophrenia", "depression", "anxiety", "ptsd")

# Folder for the result tables
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)

#-------------------------------------------------------------------
# 2. WORKED EXAMPLE: ONE TEST
# Is "depressed mood" related to the depression diagnosis?
# Section 3 repeats exactly these steps for all symptom-diagnosis pairs.
#-------------------------------------------------------------------

# Step 1: 2x2 table (rows = symptom 0/1, columns = diagnosis 0/1)
example_table <- make_2x2_table(clindata$dep_depressed_mood, clindata$dx_depression)
print(example_table)

# Step 2: chi-square test. Compares the observed counts with the counts
# expected if symptom and diagnosis were unrelated.
example_test <- chisq.test(example_table)
print(example_test)            # chi-square, df, p-value
print(example_test$expected)   # expected counts if unrelated

# Step 3: effect size. Phi is the correlation between two 0/1 variables.
example_phi <- phi_coefficient(example_table)
print(round(example_phi, 3))

#-------------------------------------------------------------------
# 3. SYMPTOMS x DIAGNOSES
# Every symptom against every diagnosis: 53 x 5 = 265 tests.
# With that many tests some would be "significant" by chance, so the
# p-values are corrected with the false discovery rate (FDR,
# Benjamini-Hochberg).
#-------------------------------------------------------------------
symptoms <- variable_key$name[variable_key$criterion != "diagnosis"]
associations <- data.frame()

for (symptom in symptoms) {
  symptom_disorder <- variable_key$disorder[variable_key$name == symptom]
  
  for (disorder in disorders) {
    tab  <- make_2x2_table(clindata[[symptom]], clindata[[paste0("dx_", disorder)]])
    test <- test_2x2(tab)
    
    associations <- rbind(associations, data.frame(
      symptom          = symptom,
      symptom_disorder = symptom_disorder,   # disorder the symptom belongs to
      diagnosis        = disorder,
      same_disorder    = symptom_disorder == disorder,
      phi              = phi_coefficient(tab),
      test             = test$test,
      statistic        = test$statistic,
      p                = test$p
    ))
  }
}

# Correct all 265 p-values together
associations$p_fdr <- p.adjust(associations$p, method = "BH")
associations$significant <- associations$p_fdr < .05

# Summary: symptoms vs their own diagnosis, and vs the other diagnoses
association_summary <- data.frame()

for (same in c(TRUE, FALSE)) {
  rows <- associations[associations$same_disorder == same, ]
  
  association_summary <- rbind(association_summary, data.frame(
    symptom_vs_diagnosis = ifelse(same, "same disorder", "other disorder"),
    n_tests       = nrow(rows),
    n_significant = sum(rows$significant),
    phi_min       = round(min(rows$phi), 3),
    phi_max       = round(max(rows$phi), 3)
  ))
}
print(association_summary)

# The significant relations
print(associations[associations$significant, c("symptom", "diagnosis", "phi", "p_fdr")])

write.csv(associations, "output/tables/symptom_associations.csv", row.names = FALSE)

#-------------------------------------------------------------------
# 4. COMORBIDITY: OBSERVED vs EXPECTED
# 10 pairs of diagnoses, FDR-corrected (see test_comorbidity())
#-------------------------------------------------------------------
comorbidity <- test_comorbidity(clindata)
print(comorbidity)

write.csv(comorbidity, "output/tables/comorbidity.csv", row.names = FALSE)

#-------------------------------------------------------------------
# 5. SYMPTOM COUNT vs DIAGNOSIS
# For each possible symptom count, the proportion of people who have the
# diagnosis. With a pure counting rule this jumps from 0 to 1 at the cutoff.
# PTSD is left out: it has five separate counts (A to E), so one count
# cannot show its rule. Schizophrenia uses the total item count.
#-------------------------------------------------------------------
count_columns <- c(bipolar       = "n_bipolar",
                   depression    = "n_depression",
                   anxiety       = "n_anxiety",
                   schizophrenia = "n_scz_total")
count_steps <- data.frame()

for (disorder in names(count_columns)) {
  counts    <- clindata[[count_columns[disorder]]]
  diagnosis <- clindata[[paste0("dx_", disorder)]]
  
  for (n in sort(unique(counts))) {
    has_count <- counts == n
    
    count_steps <- rbind(count_steps, data.frame(
      disorder       = disorder,
      n_symptoms     = n,
      n_people       = sum(has_count),
      n_diagnosed    = sum(diagnosis[has_count]),
      prop_diagnosed = round(mean(diagnosis[has_count]), 3)
    ))
  }
}
print(count_steps)

write.csv(count_steps, "output/tables/count_vs_diagnosis.csv", row.names = FALSE)

