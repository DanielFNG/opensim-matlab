classdef Desired
    % Class for storing & setting up the desired. 
    
    properties
        mode
        IDResult = 'Not yet supplied.'
        Result = 'Not yet calculated.'
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
        
        % Desired corresponds to a percentage increase/decrease over some
        % subset of joints. 
        function obj = setupPercentageReduction(obj,IDResult)
            % Here it is assumed that varargin = [joints, mutliplier].
            % If joints is a string, 'all', it is assumed all joints are to
            % be multiplied. If joints is a cell array of joint identifiers
            % i.e. 'hip_flexion_r' then those identified are the ones to be
            % multiplied. Multiplier can either be a constant, meaning all
            % DOFS are multiplied by the same value, OR an array of the
            % same size as joints (or an n dimensional array if joints ==
            % 'all') meaning there's a 1:1 correspondence of
            % joint-multiplier.
            
            if size(obj.varargin,2) ~= 2
                error(['Need two input arguments to desired for '...
                    'percentage reduction.']);
            end
            
            obj.IDResult = IDResult;
            obj.Result = IDResult.id;
            
            % Identify which joints are to be multiplied and the
            % multipliers corresponding to each joint. 
            [identifiers, multipliers] = ...
                obj.parsePercentageReductionArguments(IDResult);
            
            % NOTE: we have to append '_moment' to the label we want
            % because this is what happens to the labels after OpenSim ID.
            % Don't like having this hard-coded here, potentially revisit
            % this. 
            for i=1:size(identifiers,2)
                index = obj.Result.getIndexCorrespondingToLabel(...
                    [char(identifiers(1,i)) '_moment']);
                obj.Result = obj.Result.scaleColumn(index, multipliers(1,i));
            end
                    
        end
        
        % Parse varargin for the percantage_reduction mode. 
        function [identifiers, multipliers] = ...
                parsePercentageReductionArguments(obj, IDResult)
            % First get the number of DOFs from the data. 
            nDofs = size(IDResult.id.Labels,2) - 1; % -1 to remove the time col
            
            if isa(obj.varargin{1}, 'char') && strcmp(obj.varargin{1}, 'all')
                identifiers = IDResult.id.Labels(2:end);
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
                % Joint size doesn't match multipliers size, but it's ok if
                % the multiplier is just a scalar. 
                if size(obj.varargin{2},2) == 1
                    multipliers = ...
                        obj.varargin{2}*ones(1,size(obj.varargin{1},2));
                else
                    error(['Attempting percentage reduction at subset of '...
                        'joints, but was given an unmatching number of '...
                        'multipliers.']);
                end
            else
                identifiers = obj.varargin{1};
                multipliers = obj.varargin{2};
            end
        end
        
        % This will be desired which is just based on matching input. However, 
        % not quite as easy as just plainly matching as will also need to
        % do stuff like matching the phase. Not yet implemented this - will
        % do this after I've tested ExOpt vs. the old implementation to see
        % if we get the same, among other things to change (e.g. updated
        % APO force model). 
        function obj = setupMatchTrajectory(obj,IDResult)
        end
        
        function obj = evaluateDesired(obj, IDResult)
            if strcmp(obj.mode, 'percentage_reduction')
                obj.mode = 'percentage_reduction';
                obj = obj.setupPercentageReduction(IDResult);
            elseif strcmp(obj.mode, 'match_trajectory')
                obj.mode = 'match_trajectory';
                obj = obj.setupMatchTrajectory(IDResult);
            else
                error('Unrecognized desired mode.')
            end
        end
    end
    
end

