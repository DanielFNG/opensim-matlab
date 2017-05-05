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
        internal
        residual
    end
    
    properties (GetAccess = private, SetAccess = private)
        inertia_path
        coriolis_path
        gravity_path
        external_path
        actuation_path
        internal_path
        residual_path
    end
    
    methods
        % Construct JSFResults. Requires running getJointSpaceForces with
        % the appropriate command-line arguments, printing files
        % (unfortunately - until I can MEX this) and then reading them back
        % in as Data files. The actual running is done as a method in the
        % OpenSimTrial class. 
        
        function obj = JSFResults(directory)
            if nargin > 0
                directory = getFullPath(directory);
                obj.inertia_path = [directory '/inertia.txt'];
                obj.coriolis_path = [directory '/coriolis.txt'];
                obj.gravity_path = [directory '/gravity.txt'];
                obj.external_path = [directory '/external.txt'];
                obj.actuation_path = [directory '/actuation.txt'];
                obj.internal_path = [direcotry '/internal.txt'];
                obj.residual_path = [directory '/residual.txt'];
                obj.inertia = Data(obj.inertia_path);
                obj.coriolis = Data(obj.coriolis_path);
                obj.gravity = Data(obj.gravity_path);
                obj.external = Data(obj.external_path);
                obj.actuation = Data(obj.actuation_path);
                obj.internal = Data(obj.internal_path);
                obj.residual = Data(obj.residual_path);
            end
        end
        
    end
    
end

