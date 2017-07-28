classdef Desired
    % Class for storing & setting up the desired. 
    %
    % Note: Joints are input as normal i.e. 'hip_flexion_r', but for comparison 
    % since we are using IDTrials we need them to be like 
    % 'hip_flexion_r_moment'. This concatenation is done automatically where 
    % necessary.
    
    properties (SetAccess = private)
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
        
        % Return the vector of desired torques at a given time index. This
        % is given as a column vector, and has no time column. This is used
        % during the optimisation. 
        function desired_vector = getDesiredVector(obj, index)
            desired_vector = obj.Result.Values(index,2:end).';
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
            obj = obj.formConstraintCoefficientMatrix();
        end
        

    end
    
    methods (Access = private)
        
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
            % joint-multiplier. Joints which are not included are assumed
            % to be unconstrained, as reflected in the coefficient matrix. 
            
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
            
            for i=1:size(identifiers,2)
                index = obj.Result.getIndexCorrespondingToLabel(...
                    char(identifiers(1,i)));
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
                    identifiers = strcat(obj.varargin{1},'_moment');
                    multipliers = ...
                        obj.varargin{2}*ones(1,size(obj.varargin{1},2));
                else
                    error(['Attempting percentage reduction at subset of '...
                        'joints, but was given an unmatching number of '...
                        'multipliers.']);
                end
            else
                identifiers = strcat(obj.varargin{1},'_moment');
                multipliers = obj.varargin{2};
            end
        end
        
        % Desired based on matching some input IDResult. Can also scale the
        % desired to appropriately match the phase of the input IDResult.
        % Only really suitable when working with data that is at least 2
        % gait cycles long. 
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
            
            % Note that the desired ID trial is required in addition to the
            % input id trial, used as part of evaluateDesired.
            
            % Joints which are not included are assumed
            % to be unconstrained, as reflected in the coefficient matrix. 
            
            % Clearly, for meaningful results the desired should ideally
            % share some parameters with the IDResult i.e. end_time - start_time
            % should be the same. Indeed, the 'shift' optional argument is 
            % designed to account for the IDResult beginning at different 
            % points of the gait cycle in each case, but it requires the number
            % of frames to be the same. To account for this, a check is
            % performed that the end_time - start_time is pretty much the
            % same for the desired/input IDTrial, then the desired trial is
            % splined so that it's on the exact same # of frames as the
            % input trial. 
            %
            % THIS TYPE OF DESIRED IS NOT SUITABLE FOR DATA AT DIFFERING
            % WALKING SPEEDS!
            
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
            
            % Spline the desired ID so that it is at the same frequency as
            % the input IDResult.
            des = des.id.fitToSpline(IDResult.id.Frequency);
            
            % Stretch/compress the desired ID so that it is on the exact
            % same number of frames as the input IDResult.
            des = des.stretchOrCompress(IDResult.id.Frames);
            
            % If required shift the desired.
            if shift ~= 0
                des = des.shift(IDResult.id, shift);
            end
            
            % Now set the resulting desired.
            obj.Result = des;
        end
        
        % Parse varargin for the match_id mode. 
        function [identifiers, des, shift] = ...
                parseMatchIDArguments(obj, IDResult)
            % Determine whether shifting is to be used or not. 
            if size(obj.varargin,2) == 3
                if isa(obj.varargin{3}, 'char')
                    shift = strcat(obj.varargin{3},'_moment'); % add on _moment
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
                identifiers = strcat(obj.varargin{1}, '_moment');
            end
            
            % Determine the desired. 
            if isa(obj.varargin{2}, 'IDResult')
                des = obj.varargin{2};
            else
                error('Input desired should be an IDResult.');
            end
            
            % Throw an error if the desired has a different number of
            % coordinates that the input ID.
            if size(IDResult.id.Labels(2:end),2) ...
                    ~= size(obj.varargin{2}.id.Labels(2:end),2)
                error('Discrepancy in size between input ID and desired ID.');
            end
        end
        
        % Form the constraint coefficient matrix for use in the
        % optimisation.
        function obj = formConstraintCoefficientMatrix(obj)
            all_joints = obj.IDResult.id.Labels(2:end);
            n = size(all_joints,2);
            obj.CoefficientMatrix = zeros(n);
            for i=1:n
                for j=1:size(obj.Joints,2)
                    if strcmp(all_joints(i),obj.Joints{j})
                        obj.CoefficientMatrix(i,i) = 1;
                    end
                end
            end
        end
        
    end
    
end

