# SubmitAnnihilatorJobs

## Purpose:
These scripts are for automated submission of Tinker dynamic jobs. It is intended to work with Poltype's AMOEBAAnnihilator.

## Input:
If using as intended, user needs to edit the script and set:
- name of poltype job file
- list of nodes that can be used

## How to use SubmitDynamicJobs.sh:
You will not need to source anything. After setting the necessary input, simply go to nova and do:

> nohup bash SubmitDynamicJobs.sh > jobs.out & disown

## How to use SubmitBarJobs.sh:

> nohup bash SubmitBarJobs.sh > jobs.out & disown

## The script will:

- create my_jobs.txt (for dynamic) or bar_jobs.txt (for bar) from poltype AMOEBAAnnihilator jobfile
- each line is a job
- for each job, the script will check for an available node
- if it finds an available node:
  - it will decide which tinker to use (based on CUDA version)
  - it will then submit the job to that node via ssh
  - job pid will be stored
  - it will proceed to the next job line
- if there is no node available:
  - it will print the status of all job pids
  - if a pid is finished, it will be removed from the list
  - it will alternate between sleeping and checking for an available node until it finds one
