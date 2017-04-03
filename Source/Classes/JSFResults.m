classdef JSFResults
    % Just a small class for holding the (known - i.e. no active exoskeleton
    % component) joint-space forces associated with an OpenSimTrial. Remember 
    % to at some point investigate not doing this and just using a variant of 
    % inverse dynamics. 
    
    properties (SetAccess = private)
        inertia
        coriolis 
        gravity
        external
        actuation
    end
    
    properties (GetAccess = private, SetAccess = private)
        inertia_path
        coriolis_path
        gravity_path
        external_path
        actuation_path
    end
    
    methods
        % Construct JSFResults. Requires running getJointSpaceForces with
        % the appropriate command-line arguments, printing files
        % (unfortunately - until I can MEX this) and then reading them back
        % in as Data files. 
        
    end
    
end

