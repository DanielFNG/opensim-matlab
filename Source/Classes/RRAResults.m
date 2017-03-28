classdef RRAResults
    % Just a small class for holding the results of the RRA algorithm. 
    % At some point want to add functionality for automatically analysing
    % residuals to see if they're good enough. 
    
    properties
        forces % Actuation forces 
        accelerations % Joint accelerations etc.
        velocities
        positions
        errors % Position error between desired & achieved kinematics. 
        states 
    end
    
    methods
        
        % Construct RRAResults object from a directory where the files are
        % located, trialName gives the prefix to the files. 
        function obj = RRAResults(trialName, directory)
            if nargin > 0 
                directory = getFullPath(directory);
                obj.forces = RRAData(...
                    [directory '/' trialName '_Actuation_force.sto']);
                obj.accelerations = RRAData(...
                    [directory '/' trialName '_Kinematics_dudt.sto']);
                obj.velocities = RRAData(...
                    [directory '/' trialName '_Kinematics_u.sto']);
                obj.positions = RRAData(...
                    [directory '/' trialName '_Kinematics_q.sto']);
                obj.errors = RRAData(...
                    [directory '/' trialName '_pErr.sto']);
                obj.states = RRAData(...
                    [directory '/' trialName '_states.sto']);
            end
        end
        
    end
    
end

