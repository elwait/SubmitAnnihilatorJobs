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
- if it finds 1, will ssh to node and submit job w correct tinker 
- job pid will be stored                                          
- if it does not find avail node, it will check status of pids    
- when pid no longer running, it will search for node and submit  
- then proceed to the next line                                   
