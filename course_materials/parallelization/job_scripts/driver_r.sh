FIRST=$(qsub -N parallel_array_example_r -pe smp 2 -terse submit_r_job_array.sh scripts/parallel_example_with_args)

FIRST_JOBID=$(echo $FIRST | cut -d'.' -f1)
echo $FIRST_JOBID

qsub -N aggregate_results_r -pe smp 1 -hold_jid $FIRST_JOBID submit_r_job.sh scripts/aggregate_results