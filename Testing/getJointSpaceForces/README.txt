TESTING STEPS:

1) Create an OpenSimTrial from the model, IK and grf data files. Choose a 
    results directory. 
2) Run RRA on this OpenSimTrial. 
3) Create an OpenSimTrial from the same model and grf data as in 1), but using 
    the RRA_kinematics result from 2. Choose a results directory. 
4) Run ID on this second OpenSimTrial over the same timeframe as in 2). 
5) Copied the relevant inputs for getJointSpaceForces (see source file) in to a 
    new directory for convenience.
6) Remove all the headers from files. 
6) Run getJointSpaceForces. 

NOTE: TO DO THIS I HAD TO EDIT getJointSpaceForces FOR THE TIME BEING SINCE IT
CHECKS FOR TIME ALIGNMENT. HOWEVER, THE GRF FILE IS NOT BY DEFAULT ALIGNED 
WITH RRA, AND ACTUALLY (I DIDN'T FORESEE THIS) NEITHER IS THE ID FILE FROM 