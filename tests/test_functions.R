
# ==================================================
# PIPS GROUP PROJECT - ERROR CHECKS
# Person 1: Project structure and testing
# ==================================================

# 1. Check that the dataset exists

stopifnot(file.exists("data/Mentalillness.csv"))


# 2. Load the dataset

clindata <- read.csv("data/Mentalillness.csv")


# 3. Check that the data has the expected structure

stopifnot(
  is.data.frame(clindata),
  nrow(clindata) > 0,
  ncol(clindata) > 0
)


# 4. Check that the variables have valid names

stopifnot(
  all(nzchar(names(clindata))),
  !anyDuplicated(names(clindata))
)


# 5. Check that the main R Markdown file exists

stopifnot(file.exists("main.Rmd"))


# 6. Display a message when everything passes

cat("All preliminary checks passed!\n")


# ==================================================
# FUTURE CHECKS
# ==================================================


# ==============================================
# INDEPENDENT FUNCTION TESTS: BINARY DATA
# ==============================================

source("src/r/functions_data.R")

# Create a small artificial dataset
test_data <- data.frame(
  symptom_a = c(0, 1, 0, 1),
  symptom_b = c(1, 0, 1, 0)
)

# Test 1: Valid binary data should be accepted
valid_result <- try(
  check_binary(test_data, c("symptom_a", "symptom_b")),
  silent = TRUE
)

stopifnot(!inherits(valid_result, "try-error"))

# Test 2: Invalid values should be rejected
invalid_data <- test_data
invalid_data$symptom_a[1] <- 2

stopifnot(inherits(
  try(check_binary(invalid_data, "symptom_a"), silent = TRUE),
  "try-error"
))

# Test 3: Missing values should be rejected
missing_data <- test_data
missing_data$symptom_a[2] <- NA

stopifnot(inherits(
  try(check_binary(missing_data, "symptom_a"), silent = TRUE),
  "try-error"
))

# Test 4: A nonexistent column should be rejected
stopifnot(inherits(
  try(check_binary(test_data, "missing_symptom"),
      silent = TRUE),
  "try-error"
))

# Test 5: Character values should be rejected
character_data <- data.frame(
  symptom_a = c("yes", "no", "yes")
)

stopifnot(inherits(
  try(check_binary(character_data, "symptom_a"),
      silent = TRUE),
  "try-error"
))

cat("Binary validation tests passed!\n")


# ==============================================
# INDEPENDENT TESTS: DATA LOADING
# ==============================================

source("src/r/functions_variable_key.R")

# Create the project's variable key
test_key <- make_variable_key()

# Test 6: The real dataset should load correctly
loaded_data <- load_mental_illness(
  path = "data/Mentalillness.csv",
  key = test_key
)

stopifnot(
  is.data.frame(loaded_data),
  nrow(loaded_data) == 3753,
  all(test_key$name %in% names(loaded_data))
)

cat("Dataset loading test passed!\n")


# Test 7: A nonexistent file should trigger an error
missing_file_result <- try(
  load_mental_illness(
    path = "data/nonexistent_file.csv",
    key = test_key
  ),
  silent = TRUE
)

stopifnot(inherits(missing_file_result, "try-error"))

cat("Missing-file test passed!\n")


# ==============================================
# INDEPENDENT TESTS: VARIABLE KEY
# ==============================================

# Test 8: Variable key has the required columns

stopifnot(
  is.data.frame(test_key),
  all(c("original", "name", "disorder", "criterion") %in%
        names(test_key))
)

cat("Variable key structure test passed!\n")


# Test 9: Every variable has a unique short name

stopifnot(
  !anyDuplicated(test_key$name)
)

cat("Variable name uniqueness test passed!\n")

# Test 10: No variable has a missing or empty name

stopifnot(
  !anyNA(test_key$name),
  all(nzchar(trimws(test_key$name)))
)

cat("Variable name completeness test passed!\n")

# Test 11: Variable key has the expected number of entries

stopifnot(nrow(test_key) == 58)

cat("Variable key size test passed!\n")


# ==============================================
# INDEPENDENT TESTS: DSM RULE FUNCTIONS
# ==============================================

source("src/r/functions_dsm_rules.R")

# Use a small subset of the existing dataset
sample_data <- loaded_data[1:10, , drop = FALSE]

# Keep an untouched copy for comparison
original_data <- sample_data

# Test 12: Applying rules returns a data frame
result_data <- apply_dsm_rules(
  sample_data,
  test_key
)

stopifnot(
  is.data.frame(result_data),
  nrow(result_data) == 10
)

cat("DSM output structure test passed!\n")


# Test 13: All five rebuilt diagnosis columns exist
expected_rules <- paste0(
  "rule_",
  c("bipolar", "depression", "anxiety",
    "schizophrenia", "ptsd")
)

stopifnot(
  all(expected_rules %in% names(result_data))
)

cat("DSM diagnosis column test passed!\n")


# Test 14: Original input data remain unchanged
stopifnot(
  identical(sample_data, original_data)
)

cat("DSM input preservation test passed!\n")


# Test 15: Repeated execution produces identical results
result_again <- apply_dsm_rules(
  sample_data,
  test_key
)

stopifnot(
  identical(result_data, result_again)
)

cat("DSM reproducibility test passed!\n")


# ==============================================
# INDEPENDENT TEST: SYMPTOM CHANGE
# ==============================================

# Identify the seven bipolar symptom variables
bipolar_columns <- get_columns(
  test_key,
  disorder = "bipolar",
  criterion = "symptom"
)

stopifnot(length(bipolar_columns) == 7)

# Create one artificial participant
test_person <- loaded_data[1, , drop = FALSE]

# Set all bipolar symptoms to absent
test_person[1, bipolar_columns] <- 0

# Give the participant exactly two bipolar symptoms
test_person[1, bipolar_columns[1:2]] <- 1

# Calculate the diagnosis before the change
before <- apply_dsm_rules(test_person, test_key)

stopifnot(before$rule_bipolar[1] == 0)

# Add a third bipolar symptom
test_person[1, bipolar_columns[3]] <- 1

# Recalculate the diagnosis
after <- apply_dsm_rules(test_person, test_key)

stopifnot(after$rule_bipolar[1] == 1)

# Changing bipolar symptoms should not change
# the other reconstructed diagnostic classifications
other_rules <- c(
  "rule_depression",
  "rule_anxiety",
  "rule_schizophrenia",
  "rule_ptsd"
)

stopifnot(
  identical(
    before[1, other_rules, drop = FALSE],
    after[1, other_rules, drop = FALSE]
  )
)

cat("Symptom-change classification test passed!\n")


# ==============================================
# INDEPENDENT TESTS: SHINY APPLICATION
# ==============================================

# Extract the R code without modifying Shiny_Sim.Rmd
shiny_script <- tempfile(fileext = ".R")

knitr::purl(
  "Shiny_Sim.Rmd",
  output = shiny_script,
  documentation = 0,
  quiet = TRUE
)

invisible(capture.output(
  source(shiny_script, local = TRUE)
))

# Test: Empty datasets should be rejected
empty_data <- loaded_data[0, , drop = FALSE]

stopifnot(
  inherits(
    try(
      create_shiny_app(empty_data, test_key),
      silent = TRUE
    ),
    "try-error"
  )
)

cat("Shiny empty-dataset test passed!\n")


# Test: Invalid variable keys should be rejected
invalid_key <- data.frame(
  name = "symptom_a"
)

stopifnot(
  inherits(
    try(
      create_shiny_app(loaded_data, invalid_key),
      silent = TRUE
    ),
    "try-error"
  )
)

cat("Shiny invalid-key test passed!\n")


# Test: Valid inputs should create an app object
valid_app <- create_shiny_app(
  loaded_data,
  test_key
)

stopifnot(
  inherits(valid_app, "shiny.appobj")
)

cat("Shiny application creation test passed!\n")
