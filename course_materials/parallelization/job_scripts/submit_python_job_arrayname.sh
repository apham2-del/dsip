#!/bin/bash

#$ -M netid@nd.edu   # Email address for job notification
#$ -m abe            # Send mail when job begins, ends and aborts
#$ -pe smp 24        # Specify parallel environment and legal core size
#$ -q long           # Specify queue
#$ -N job_name       # Specify job name
#$ -t 1-2            # Specify array job

module load python
module load conda
conda activate dsip_parallel

cd ../

models=( "rf" "knn" )
python ${1}.py --model ${models[$SGE_TASK_ID-1]}
