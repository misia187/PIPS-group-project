# PIPS Group Project

This repository contains a group project for the Programming in Psychological Science course at the University of Amsterdam.

The project uses psychological data and will include an interactive component, statistical analyses, and data visualisations.

## Project structure

- `data/` — Dataset used in the project.
- `src/` — R scripts and reusable functions.
- `tests/` — Independent tests and error checks.
- `main.Rmd` — Main R Markdown document.
- `README.md` — Documentation and instructions.

## Getting started

1. Download or clone the GitHub repository.
2. Open `PIPS-group-project.Rproj` in RStudio.
3. Install the packages required for R Markdown if they are not already installed:

   `install.packages(c("rmarkdown", "knitr"))`

4. Open `main.Rmd`.
5. Click **Knit** to produce the HTML document.

The interactive component and analyses will be integrated once completed.

## Dataset

The dataset is stored in `data/Mentalillness.csv`.

The data source, relevant variables, and references will be documented in the final version.

## Testing

To run the preliminary project checks, enter the following in the R console from the project's main directory:

`source("tests/test_functions.R")`

The testing script currently verifies that the dataset and essential files exist and that the data has a valid basic structure.

Additional tests for the group's functions will be added as development progresses.

## Project status

Work in progress.