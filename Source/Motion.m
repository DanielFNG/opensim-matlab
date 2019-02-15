classdef Motion < handle
% Class for using OpenSim analysis data to perform calculations.

    properties (SetAccess = private)
        Trial
    end
    
    % Model-specific properties; should be modified if alternative models
    % are used e.g. not gait2392.
    properties (Access = protected)
        Gravity = 9.80665;
        CoM = 'center_of_mass_'
        Torque = '_moment'
    end
        
    methods
        
        function obj = Motion(trial)
            if nargin > 0
                obj.Trial = trial;
            end
        end
        
        function require(obj, analyses)
        % Throw an error if any input analyses haven't been loaded.
        
            if isa(analyses, 'char')
                analyses = {analyses};
            end
        
            for i=1:length(analyses)
                analysis = analyses{i};
                if ~obj.Trial.loaded.(analysis)
                    error('Required analysis data not loaded.');
                end
            end
        
        end
        
        function result = getTotalTime(obj)
           
            % Analysis requirements.
            obj.require('IK');
            
            % Cycle time calculation.
            range = obj.Trial.data.IK.Kinematics.getTimeRange();
            result = range(2) - range(1);
            
        end
        
        function result = calculateCoMD(obj, direction)
        % Calculate CoM displacement.
        
            % Analysis requirements.
            obj.require('BK');
            
            % CoMD calculation. 
            directions = {'y', 'z'};
            for i=1:length(directions)
                label = [obj.CoM directions{i}];
                data = obj.Trial.data.BK.Positions.getColumn(label);
                result.(directions{i}) = peak2peak(data);
            end
            
            % Optionally, return only one direction.
            if nargin == 2
                result = result.(direction);
            end
        end
        
        function result = calculateWNPPT(obj, joint)
        % Calculate weight-normalised peak-to-peak torque at given joint.
        
            % Analysis requirements.
            obj.require('ID');
            
            % WNPT calculation. 
            torque = ...
                obj.Trial.data.ID.JointTorques.getColumn([joint obj.Torque]);
            mass = obj.Trial.getInputModelMass();
            result = peak2peak(torque)/mass;
        end
        
        function result = calculateROM(obj, joint)
        % Calculate weight-normalised peak torque at given joint.
        
            % Analysis requirements.
            obj.require('IK');
            
            % ROM calculation. 
            trajectory = obj.Trial.data.IK.Kinematics.getColumn(joint);
            result = peak2peak(trajectory);
        end
        
    end

end