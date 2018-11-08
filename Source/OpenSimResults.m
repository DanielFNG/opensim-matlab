classdef OpenSimResults < handle 

    properties (SetAccess = private)
        IK = 'Not loaded.'
        RRA = 'Not loaded.'
        BK = 'Not loaded.'
        ID = 'Not loaded.'
        CMC = 'Not loaded.'
    end
    
    properties (GetAccess = private, SetAccess = private)
        Trial
        Analyses
    methods
    
        % Construct OpenSimResults.
        function obj = OpenSimResults(ost, analyses)
            obj.Trial = ost;
            obj.Analyses = analyses;
            obj.createDataStruct();
        end
        
    end
    
    methods (Access = private)
        
        function createDataStruct(obj, analyses)
            if any(strcmp(analyses, 'IK'))
                obj.loadIK();
            elseif any(strcmp(analyses, 'RRA'))
                obj.loadRRA();
            elseif any(strcmp(analyses, 'BK'))
                obj.loadBK();
            elseif any(strcmp(analyses, 'ID'))
                obj.loadID();
            elseif any(strcmp(analyses, 'CMC'))
                obj.loadCMC();
            end
        end
        
        function loadIK(obj)
            if ~obj.Trial.computed.IK
                error('IK not computed.');
            end
            
            obj.IK.Kinematics = 0;
            obj.IK.InputMarkers = 0;
            obj.IK.OutputMarkers = 0;
        end
        
        function loadRRA(obj)
            if ~obj.Trial.computed.RRA
                error('RRA not computed.');
            end
            
            obj.RRA.Kinematics = 0;
        end
        
        function loadBK(obj)
            if ~obj.Trial.computed.BK
                error('BK not computed.');
            end
            
            obj.BK.Positions = 0;
            obj.BK.Velocities = 0;
            obj.BK.Accelerations = 0;
        end
        
        function loadID(obj)
            if ~obj.Trial.computed.ID
                error('ID not computed.');
            end
            
            obj.ID.JointTorques = 0;
        end
        
        function loadCMC(obj)
            if ~obj.Trial.computed.CMC
                error('CMC not computed.');
            end
        end
    
    end

end