function result = readAPOData(filename)
% Read and plot the saved variables in the RT Labview routine 

    Fid     = fopen(filename, 'r', 's'); % read the file name of your saved dataset.
    DataSet = fread(Fid, [9 inf], 'double');                      % read the 9 variables
    fclose(Fid);                                                  % close the file

    result.H_RightJointAngle    = DataSet(1, 2:end-1); % [deg],joint angle of the right joint of APO           
    result.H_RightActualTorque  = DataSet(2, 2:end-1); % [Nm], output torque of the right joint of APO
    result.H_LeftJointAngle     = DataSet(5, 2:end-1); % [deg], joint angle of the left joint of APO 
    result.H_LeftActualTorque   = DataSet(6, 2:end-1); % [Nm], output torque of the left joint of APO
    result.Time                 = DataSet(9, 2:end-1); % [s], time variable

end





















