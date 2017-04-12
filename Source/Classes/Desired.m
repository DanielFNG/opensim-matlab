classdef Desired
    % Class for storing & setting up the desired. 
    
    properties
        mode
        value = 'Not yet calculated.'
    end
    
    properties (SetAccess = private, GetAccess = private)
        varargin % Column cell array!
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
            % be multiplied. If joints is a cell array of joint identifiers
            % i.e. 'r_hip_f' then those identified are the ones to be
            % multiplied. Multiplier can either be a constant, meaning all
            % DOFS are multiplied by the same value, OR an array of the
            % same size as joints (or an n dimensional array if joints ==
            % 'all') meaning there's a 1:1 correspondence of
            % joint-multiplier.
            
            if size(obj.varargin,2) ~= 2
                error(['Need two input arguments to desired for '...
                    'percentage reduction.']);
            end
            
            % First get the number of DOFs from the data. 
            nDofs = size(IDTrial.Labels,2) - 1; % -1 to remove the time col
            
            [identifiers, multipliers] = ...
                obj.parsePercentageReductionArguments(IDTrial);
                    
        end
        
        function [identifiers, multipliers] = ...
                parsePercentageReductionArguments(obj, IDTrial)
            if isa(obj.varargin{1}, 'char') && strcmp(obj.varargin{1}, 'all')
                identifiers = IDTrial.Labels(2:end);
                if size(obj.varargin{2},2) == 1
                    multipliers = obj.varargin{2}*ones(1,nDofs);
                elseif size(obj.varargin{2},2) < nDofs
                    error(['Attempting percentage reduction across all' ...
                        ' joints, but received fixed number of multipliers' ...
                        ' less than total number of joints.']);
                elseif size(obj.varargin{2},2) == nDofs
                    multipliers = obj.varargin{2};
                else
                    error('Received more multipliers than model DOFS.');
                end
            elseif size(obj.varargin{1},2) ~= size(obj.varargin{2},2)
                error(['Attempting percentage reduction at subset of '...
                    'joints, but was given an unmatching number of '...
                    'multipliers.']);
            else
                identifiers = obj.varargin{1};
                multipliers = obj.varargin{2};
            end
        end
        
        function obj = setupMatchTrajectory(obj,IDTrial)
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

