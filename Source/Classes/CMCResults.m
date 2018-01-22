classdef CMCResults
    % A class for holding the results of a CMC, and doing any calculations
    % based on these results. 
    
    properties (SetAccess = private)
        OpenSimTrial
        start
        final
        forces
        powers
        speeds
        controls
        accelerations
        velocities
        positions
        errors
        states
        
        forces_path
        powers_path
        speeds_path
        controls_path
        accelerations_path
        velocities_path
        positions_path
        errors_path
        states_path
    end
    
    methods
        
        % Construct CMCResults from directory files are located and the
        % OpenSimTrial.
        function obj = CMCResults(OpenSimTrial, directory)
            if nargin > 0
                obj.OpenSimTrial = OpenSimTrial;
                directory = getFullPath(directory);
                obj.forces_path = ...
                    [directory '_Actuation_force.sto'];
                obj.powers_path = ...
                    [directory '_Actuation_power.sto'];
                obj.speeds_path = ...
                    [directory '_Actuation_speed.sto'];
                obj.controls_path = ...
                    [directory '_controls.sto'];
                obj.accelerations_path = ...
                    [directory '_Kinematics_dudt.sto'];
                obj.velocities_path = ...
                    [directory '_Kinematics_u.sto'];
                obj.positions_path = ...
                    [directory '_Kinematics_q.sto'];
                obj.errors_path = ...
                    [directory '_pErr.sto'];
                obj.states_path = ...
                    [directory '_states.sto'];
                obj.forces = Data(obj.forces_path);
                obj.powers = Data(obj.powers_path);
                obj.speeds = Data(obj.speeds_path);
                obj.controls = Data(obj.controls_path);
                obj.accelerations = Data(obj.accelerations_path);
                obj.velocities = Data(obj.velocities_path);
                obj.positions = Data(obj.positions_path);
                obj.errors = Data(obj.errors_path);
                obj.states = Data(obj.states_path);
                obj.start = obj.forces.Timesteps(1);
                obj.final = obj.forces.Timesteps(end);
            end
        end
            
    end
end