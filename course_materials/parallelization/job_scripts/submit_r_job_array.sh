#!/bin/bash

#$ -M netid@nd.edu   # Email address for job notification
#$ -m abe            # Send mail when job begins, ends and aborts
#$ -pe smp 24        # Specify parallel environment and legal core size
#$ -q long           # Specify queue
#$ -N job_name       # Specify job name
#$ -t 1-2            # Specify array job

module load R

cd ../  # run the R script from the project root directory to activate renv
Rscript ${1}.R --array_id ${SGE_TASK_ID}
