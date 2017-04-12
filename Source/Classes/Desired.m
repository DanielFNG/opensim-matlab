classdef Desired
    % Class for storing & setting up the desired. 
    
    properties
        mode
        value = 'Not yet calculated.'
    end
    
    properties (SetAccess = private, GetAccess = private)
        varargin
    end
    
    methods
        
        function obj = Desired(mode, varargin)
            if nargin > 0
                obj.mode = mode;
                obj.varargin = varargin;
            end
        end
        
        function obj = setupPercentageReduction(obj,IDTrial)
            % Here it is assumed that varargin = [joints, mutliplier].
            % If joints is a string, 'all', it is assumed all joints are to
            % be multiplied. If joints is an array of joint identifiers
            % i.e. 'r_hip_f' then those identified are the ones to be
            % multiplied. Multiplier can either be a constant, meaning all
            % DOFS are multiplied by the same value, OR an array of the
            % same size as joints (or an n dimensional array if joints ==
            % 'all') meaning there's a 1:1 correspondence of
            % joint-multiplier.
        end
        
        function obj = setupMatchTrajectory(obj)
        end
        
        function obj = evaluateDesired(obj, IDTrial)
            if strcmp(obj.mode, 'percentage_reduction')
                obj.mode = 'percentage_reduction';
                obj = obj.setupPercentageReduction(IDTrial);
            elseif strcmp(obj.mode, 'match_trajectory')
                obj.mode = 'match_trajectory';
                obj = obj.setupMatchTrajectory(IDTrial);
            else
                error('Unrecognized desired mode.')
            end
        end
    end
    
end

