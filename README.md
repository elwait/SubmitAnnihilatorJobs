This script is for automated submission of Tinker dynamic jobs.
It is intended to work with Poltype's AMOEBAAnnihilator.


If using as intended, user needs to set:                          
- name of poltype job file                                                     
- list of nodes that can be used

                        
The script will:                                                  
- create my_jobs.txt from AMOEBAAnnihilator jobfile
- each line is a job                                              
- for each job, the script will check for an available node
- if it finds an available node:
  -  it will decide which tinker to use (based on CUDA version)
  - it will then submit the job to that node via ssh
  - job pid will be stored
  - it will proceed to the next job line
- if there is no node available:
  - it will print the status of all job pids
  - if a pid is finished, it will be removed from the list
  - it will alternative between sleeping and checking for an available node until it finds one
