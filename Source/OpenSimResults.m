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
        
    methods
    
        % Construct OpenSimResults.
        function obj = OpenSimResults(ost, analyses)
            obj.Trial = ost;
            obj.ResultsPaths = ost.getResultsPaths();
            obj.createDataStruct(analyses);
        end
        
    end
    
    methods (Access = private)
        
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
    
    end

end