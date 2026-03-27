# Lab 4 Documentation

# Lab 4 Parallelization

## File Structure 
- `R/fit_rf_fold.R`: function to train and evaluate random forest on one fold
- `scripts/run_cv_sequential.R`: sequential cross-validation
- `scripts/run_cv_parallel.R`: parallel cross-validation using 5 workers
- `job scripts/`: contains job submission scripts and output files

## Output Files
- Sequential run: `cv_seq.o742367`
- Parallel run: `cv_par.o742156`

## Results

### Sequential
- Fold accuracies: 0.9572730, 0.9589782, 0.9603239, 0.9617178, 0.9592666
- Mean accuracy: 0.9595119
- Variance: 2.720791e-06
- Runtime: 1.825786 minutes

### Parallel
- Fold accuracies: 0.9580420, 0.9590503, 0.9607325, 0.9615736, 0.9606604
- Mean accuracy: 0.9600117
- Variance: 2.046007e-06
- Runtime: 24.91396 seconds

## Comparison
Both implementations produced nearly identical cross-validation results, with mean accuracy around 0.96 and extremely low variance across folds, indicating stable model performance.
The parallel implementation was significantly faster, completing in about 25 seconds compared to about 1.83 minutes for the sequential version. This demonstrates the benefit of parallelization for reducing computation time.

