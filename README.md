This script is for automated submission of tinker jobs.
It is intended to work with AMOEBAAnnihilator.


If using as intended, user needs to set:                          
- AMOEBAAnnihilator job file                                      
- name of job file to be created (my_jobs.txt)                    
- list of nodes that can be used

                        
The script will:                                                  
- create my_jobs.txt from AMOEBAAnnihilator jobfile (reformatting)
- each line is a job                                              
- for each job, the script will check for avail nodes             
- if it finds a node, will ssh to node and submit job with correct tinker for CUDA version
- job pid will be stored
- it will print the status of all job pids
- if it does not find avail node, it will alternate between sleeping and checking until it finds one
- job will be submitted and pid will be stored
- it will print the status of all job pids
- then proceed to the next line
