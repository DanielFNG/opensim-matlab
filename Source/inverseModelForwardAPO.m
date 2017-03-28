function inverseModelForwardAPO( description, varargin )
    % A temporary implementation of automatedInverseModel based on a
    % recommendation of tests to run from Sethu.
    %
    % I'm going to do this in two ways: 
    % 
    % 1) take some of the data we've already collected of the
    % human walking with the exoskeleton in active mode. The 'input torque'
    % is the corresponding transparent trial. The 'desired torque' is the
    % human component of the net torque from the active trial -
    % disambugation from the net torque is done using the APO force
    % model* using APO readings.. Compare to see how they match up to the 
    % APO readings. 
    %
    % 2) take some of the data we've already collected of the human walking
    % with the exoskeleton in active mode. This is the 'input torque'.
    % Provide the corresponding net torque from the transparent trial as a
    % 'desired torque'. Compare to see how the output values match the APO
    % readings. 
    
    % Actually, there are so many components to this that I'm of the view
    % that it might be better to do the code tidying up first. 

end

