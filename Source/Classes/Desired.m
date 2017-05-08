classdef Desired
    % Class for storing & setting up the desired. 
    
    properties
        mode
        Joints = 'Not yet parsed.' % Joints for which there are constraints
        IDResult = 'Not yet supplied.'
        Result = 'Not yet calculated.'
        CoefficientMatrix = 'Not yet calculated.'
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
            % Proceed by scaling the provided IDResult by a % across all
            % joints or a subset of joints.
            %
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
            
            obj.Joints = identifiers;
            
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
                    identifiers = obj.varargin{1};
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
        
        % Desired based on matching some input IDResult. Can also scale the
        % desired to appropriately match the phase of the input IDResult. 
        function obj = setupMatchID(obj, IDResult)
            % Proceed by matching a provided desired IDResult across all 
            % joints or a subset of the joints present in InputID.  
            
            % Here it is assumed that varargin = {joints, desired, shift}. 
            % Joints can be 'all' or a cell array giving the identifiers 
            % (names) of the joints for which we have constraints. Desired 
            % should be an IDResult. Shift, optional, says whether the desired 
            % should be shifted to match the phase of the input. It should
            % be a string, describing the joint that is used for comparison
            % to do the shifting. 
            
            % Clearly, for meaningful results the desired should ideally
            % share some parameters with the IDResult i.e. end_time - start_time
            % should be the same, so this is included in a check. The 'shift' 
            % optional argument is designed to account for the IDResult 
            % beginning at different points of the gait cycle in each case.
            % An error will be thrown if the end_time - start_time is too
            % different. THIS WILL NOT BE ACCURATE IF THE DATA WAS TAKEN AT
            % DIFFERENT WALKING SPEEDS! 
            
            % Check input arguments. 
            if size(obj.varargin,2) < 1 || size(obj.varargin,2) > 3
                error(['The MatchID Desired mode supports 2 or 3'...
                     ' input arguments, only.']);
            end
            
            % Save the IDResult.
            obj.IDResult = IDResult;
            
            % Parse input arguments. 
            [identifiers, des, shift] = ...
                parseMatchIDArguments(obj, IDResult);
            
            obj.Joints = identifiers;
            
            % Check that the input desired isn't silly. 
            if abs(abs(des.final - des.start) ...
                    - abs(IDResult.final - IDResult.start)) ...
                    > 0.05 * abs(IDResult.final - IDResult.start)
                error(['Timescale discrepancy between input ID and ' ...
                    'desired ID is too large (>5%).']);
            end 
            
            % Spline the desired ID so that it is on the same number of
            % points as the input IDResult.
            
            % Now set the result to be the data object.
            obj.Result = des.id;
            
            % If required shift the desired.
            if shift ~= 0
                des = des.shift(IDResult.id, shift);
            end
        end
        
        % Parse varargin for the match_id mode. 
        function [identifiers, des, shift] = ...
                parseMatchIDArguments(obj, IDResult)
            % First get the number of DOFs from the data. 
            nDofs = size(IDResult.id.Labels,2) - 1; % -1 to remove the time col
            
            % Determine whether shifting is to be used or not. 
            if size(obj.varargin) == 3
                if isa(obj.varargin{3}, 'char')
                    shift = obj.varargin{3};
                else
                    error(['If used, third argument for Match ID'...
                        ' mode should be a string.']);
                end
            else
                shift = 0;
            end
            
            % Detemine the joint identifiers. 
            if isa(obj.varargin{1}, 'char') && strcmp(obj.varargin{1}, 'all')
                identifiers = IDResult.id.Labels(2:end);
            else
                identifiers = obj.varargin{1};
            end
            
            % Determine the desired. 
            if isa(obj.varargin{2}, 'IDResult')
                des = obj.varargin{2};
            else
                error('Input desired should be an IDResult.');
            end
            
            % Throw an error if the desired has a different number of
            % coordinates that the input ID.
            if size(IDResult.id.Labels(2:end) ...
                    ~= size(obj.varargin{2}.id.Labels(2:end))
                error('Discrepancy in size between input ID and desired ID.');
            end
        end
        
        function obj = evaluateDesired(obj, IDResult)
            if strcmp(obj.mode, 'percentage_reduction')
                obj.mode = 'percentage_reduction';
                obj = obj.setupPercentageReduction(IDResult);
            elseif strcmp(obj.mode, 'match_id')
                obj.mode = 'match_id';
                obj = obj.setupMatchID(IDResult);
            else
                error('Unrecognized desired mode.')
            end
        end
        
        function obj = formConstraintCoefficientMatrix(obj)
            matrix = zeros(size(obj.IDResult.Labels(2:end),2));
            
        end
    end
    
end

