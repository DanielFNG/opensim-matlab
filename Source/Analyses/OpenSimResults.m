classdef OpenSimResults < handle 

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
    end
    
    properties (GetAccess = private, SetAccess = private)
        StanceCutoff = 10
        CoM = 'center_of_mass_'
        RightFoot = '    ground_force1'
        LeftFoot = '    ground_force2'
        Torque = '_moment'
    end
        
    methods
    
        % Construct OpenSimResults.
        function obj = OpenSimResults(ost, analyses)
            obj.Trial = ost;
            obj.ResultsPaths = ost.getResultsPaths();
            obj.createDataStruct(analyses);
        end
        
        function result = calculateCoMD(obj)
            directions = {'x', 'y', 'z'};
            for i=1:length(directions)
                label = [obj.CoM directions{i}];
                data = obj.BK.Positions.getColumn(label);
                result.(directions{i}) = max(data) - min(data);
            end
        end
        
        function result = calculateCoPD(obj)
            directions = {'x', 'z'};
            foot = obj.identifyLeadingFoot();
            stance = obj.isolateStancePhase(foot);
            for i=1:length(directions)
                label = directions{i};
                cp = ['p' label];
                cop = obj.GRF.Forces.getColumn([foot cp]);
                result.(label) = max(cop(stance)) - min(cop(stance));
            end
        end
        
        function result = calculateWNPT(obj, joint)
            torque = obj.ID.JointTorques.getColumn([joint obj.Torque]);
            result = (max(torque) - min(torque))/obj.getModelMass();
        end
        
        function result = calculateROM(obj, joint)
            trajectory = obj.IK.Kinematics.getColumn(joint);
            result = max(trajectory) - min(trajectory);
        end
    end
    
    methods (Access = private)
        
        function checkDataAvailability(obj, analysis)
            if strcmp(obj.(analysis), 'Not loaded.')
                error('Analysis data not available.');
            end
        end
        
        function createDataStruct(obj, analyses)
            for i=1:length(analyses)
                obj.load(analyses{i});
            end
        end
        
        function folder = preload(obj, analysis)
            if ~obj.Trial.computed.(analysis)
                error([analysis ' not computed.']);
            end
            
            folder = obj.ResultsPaths.(analysis);
        end
        
        function load(obj, analysis)
            
            folder = obj.preload(analysis);
            obj.(analysis) = {};
            
            switch analysis
                case 'GRF'
                    obj.GRF.Forces = Data(obj.Trial.grfs_path);
                case 'IK'
                    obj.IK.Kinematics = Data([folder filesep 'ik.mot']);
                    obj.IK.InputMarkers = Data(obj.Trial.input_coordinates);
                    obj.IK.OutputMarkers = ...
                        Data([folder filesep 'ik_model_marker_locations.sto']);
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
        
        function label = identifyLeadingFoot(obj)
            vert = 'vy';
            right = obj.GRF.Forces.getColumn([obj.RightFoot vert]);
            left = obj.GRF.Forces.getColumn([obj.LeftFoot vert]);
            if right(1) > left(1)
                label = obj.LeftFoot;
            else
                label = obj.RightFoot;
            end
        end
        
        function indices = isolateStancePhase(obj, label)
            vert = 'vy';
            indices = find(grfs.getColumn([label vert]) > obj.StanceCutoff);
        end
        
        function mass = getModelMass(obj)
            import org.opensim.modeling.Model;
            osim = Model(obj.Trial.model_path);
            bodies = osim.getBodySet();
            masses = zeros(1, bodies.getSize() - 1);
            for i=0:bodies.getSize()-1
                if ~strcmp(name, 'ground')
                    masses(min(masses == 0)) = bodies.get(i).getMass();
                end
            end
            mass = sum(masses);
        end
    
    end

end