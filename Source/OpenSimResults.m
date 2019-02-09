classdef OpenSimResults < handle 
% Class for using OpenSim analysis data to perform calculations.

    properties (SetAccess = private)
        GRF = 'Not loaded.'
        IK = 'Not loaded.'
        RRA = 'Not loaded.'
        BK = 'Not loaded.'
        ID = 'Not loaded.'
        CMC = 'Not loaded.'
    end
    
    properties (GetAccess = private, SetAccess = private)
        Trial
        ResultsPaths
        StanceCutoff = 10
        CoM = 'center_of_mass_'
        RightFoot = '    ground_force1'
        LeftFoot = '    ground_force2'
        Torque = '_moment'
    end
        
    methods
    
        function obj = OpenSimResults(ost, analyses)
        % Construct OpenSimResults.
            obj.Trial = ost;
            obj.ResultsPaths = obj.Trial.results_paths;
            obj.load(analyses);
        end
        
        function load(obj, analyses)
        % Load the data from each analysis in turn.
        
            % Support for a single analysis input as a string. 
            if isa(analyses, 'char')
                analyses = {analyses};
            end
            
            for i=1:length(analyses)
            
                % Check analysis is computed - if so get results folder.
                analysis = analyses{i};
                folder = obj.preload(analysis);
                obj.(analysis) = {};
            
                % Load analysis Data. 
                switch analysis
                    case 'GRF'
                        obj.GRF.Forces = Data(obj.Trial.grfs_path);
                    case 'IK'
                        obj.IK.Kinematics = Data([folder filesep 'ik.mot']);
                        obj.IK.InputMarkers = Data(obj.Trial.input_coordinates);
                        obj.IK.OutputMarkers = Data(...
                            [folder filesep 'ik_model_marker_locations.sto']);
                    case 'RRA'
                        obj.RRA.Kinematics = ...
                            Data([folder filesep 'RRA_Kinematics_q.sto']);
                        obj.RRA.Forces = ...
                            Data([folder filesep 'RRA_Actuation_force.sto']);
                        obj.RRA.TrackingErrors = ...
                            Data([folder filesep 'RRA_Kinematics_q.sto']);
                    case 'BK'
                        obj.BK.Positions = Data([folder filesep ...
                            'Analysis_BodyKinematics_pos_global.sto']);
                        obj.BK.Velocities = Data([folder filesep ...
                            'Analysis_BodyKinematics_vel_global.sto']);
                        obj.BK.Accelerations = Data([folder filesep ...
                            'Analysis_BodyKinematics_acc_global.sto']);
                    case 'ID'
                        obj.ID.JointTorques = Data([folder filesep 'id.sto']);
                    case 'CMC'
                        % Not yet implemented - need to see which files need to
                        % be read in. Will wait until more CMC-based analysis
                        % is required.
                end
            end
        end
        
        function result = calculateCoMD(obj)
        % Calculate CoM displacement.
        
            % Analysis requirements.
            obj.require('BK');
            
            % CoMD calculation. 
            directions = {'x', 'y', 'z'};
            for i=1:length(directions)
                label = [obj.CoM directions{i}];
                data = obj.BK.Positions.getColumn(label);
                result.(directions{i}) = peak2peak(data);
            end
        end
        
        function result = calculateCoPD(obj)
        % Calculate CoP displacement at the leading foot. 
        
            % Analysis requirements.
            obj.require('GRF');
            
            % CoPD calculation.  
            directions = {'x', 'z'};
            foot = obj.identifyLeadingFoot();
            stance = obj.isolateStancePhase(foot);
            for i=1:length(directions)
                label = directions{i};
                cp = ['p' label];
                cop = obj.GRF.Forces.getColumn([foot cp]);
                result.(label) = peak2peak(cop(stance));
            end
        end
        
        function result = calculateWNPT(obj, joint)
        % Calculate weight-normalised peak torque at given joint.
        
            % Analysis requirements.
            obj.require('ID');
            
            % WNPT calculation. 
            torque = obj.ID.JointTorques.getColumn([joint obj.Torque]);
            result = peak2peak(torque)/obj.getModelMass();
        end
        
        function result = calculateROM(obj, joint)
        % Calculate weight-normalised peak torque at given joint.
        
            % Analysis requirements.
            obj.require('IK');
            
            % ROM calculation. 
            trajectory = obj.IK.Kinematics.getColumn(joint);
            result = peak2peak(trajectory);
        end
    end
    
    methods (Access = private)
    
        function require(obj, analyses)
        % Throw an error if any analyses aren't available in this object.
        
            if isa(analyses, 'char')
                analyses = {analyses};
            end
        
            for i=1:length(analyses)
                analysis = analyses{i};
                if strcmp(obj.(analysis), 'Not Loaded.')
                    error('Required analysis data not available.');
                end
            end
        
        end
        
        function folder = preload(obj, analysis)
        % Return path to folder containing analysis Data.
        %
        % Throws an error if the analysis data has not been computed.
            folder = [];
            if ~strcmp(analysis, 'GRF')
                if ~obj.Trial.computed.(analysis)
                    error([analysis ' not computed.']);
                end
                folder = obj.ResultsPaths.(analysis);
            end
            
        end
        
        function label = identifyLeadingFoot(obj)
        % Identify & return start of label for the leading foot.
        
            % Isolate vertical force data for each foot.
            vert = 'vy';
            right = obj.GRF.Forces.getColumn([obj.RightFoot vert]);
            left = obj.GRF.Forces.getColumn([obj.LeftFoot vert]);
            
            % The index at which each peak occurs.
            [~, right_peak] = max(right);
            [~, left_peak] = max(left);
            
            % Check which peaks sooner. 
            if right_peak > left_peak
                label = obj.RightFoot;
            else
                label = obj.LeftFoot;
            end
        end
        
        function indices = isolateStancePhase(obj, label)
        % Get the indices corresponding to stance phase.
        
            vert = 'vy';
            indices = find(grfs.getColumn([label vert]) > obj.StanceCutoff);
        end
        
        function mass = getModelMass(obj)
        % Calculate mass of the model for this OpenSimResult.
        
            import org.opensim.modeling.Model;
            osim = Model(obj.Trial.model_path);
            bodies = osim.getBodySet();
            masses = zeros(1, bodies.getSize() - 1);
            
            % Sum the mass of every body in the model apart from ground.
            for i=0:bodies.getSize()-1
                if ~strcmp(name, 'ground')
                    masses(min(masses == 0)) = bodies.get(i).getMass();
                end
            end
            mass = sum(masses);
        end
    
    end

end