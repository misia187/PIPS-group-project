
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

# Additional tests of group members' functions
# will be added here when their code is ready.
