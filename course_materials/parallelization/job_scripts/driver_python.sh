FIRST=$(qsub -N parallel_array_example_py -pe smp 2 -terse submit_python_job_array.sh scripts/parallel_example_with_args)

FIRST_JOBID=$(echo $FIRST | cut -d'.' -f1)
echo $FIRST_JOBID

qsub -N aggregate_results_py -pe smp 1 -hold_jid $FIRST_JOBID submit_python_job.sh scripts/aggregate_results