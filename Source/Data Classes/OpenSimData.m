classdef (Abstract) OpenSimData < handle & matlab.mixin.Copyable
    % Abstract Class for storing & working with OpenSim data.
    % 
    % Holds many methods which are generic to each type of OpenSimData. Specific
    % methods are defined as Abstract here, and are later redefined in the 
    % appropriate subclasses. 
    
    properties (Abstract, SetAccess = protected)
        Filetype
    end
    
    properties (Abstract, Access = protected)
        NonStateLabels
    end
    
    properties %(SetAccess = protected)
        Frequency
        NFrames
        NCols
        Labels
        IsCartesian = false
    end
    
    properties %(Access = protected)
        Header
        TimeLabel
        Frames
        Timesteps
        Values
        OrigNumFrames
        OrigFrequency = 'Not defined';
        EqualityTolerance = 1e-6
    end
    
    methods (Abstract, Access = protected)
        
        updateHeader(obj)
        setTimeLabel(obj)
        printLabels(obj, fileID)
        printValues(obj, fileID)
        splined_obj = assignSpline(obj, timesteps, values)
    
    end
    
    methods (Abstract, Static)
       
        load(filename)
        
    end
    
    methods (Abstract, Access = protected, Static)
       
        convertHeader(input_header)
        convertLabels(input_labels)
        convertValues(input_values)
        
    end
    
    methods
    
        function obj = OpenSimData(varargin)
        % Construct OpenSimData from (file) or from 
        % (values, header, labels, name).
            if nargin > 0
                if nargin == 1
                    try
                        obj.parse(varargin{1});
                    catch err
                        fprintf('Data loading failed.\n')
                        rethrow(err);
                    end
                elseif nargin == 3
                    obj.Values = varargin{1};
                    obj.Header = varargin{2};
                    obj.Labels = varargin{3};
                else
                    error('Incorrect number of arguments.');
                end
                obj.setTimeLabel();
                obj.initialise();
            end
        end
        
        function bool = eq(obj1, obj2, tol)
        % Overload equality.
        %
        % Two data objects are deemed to be equivalent if their labels are
        % equivalent, and their values are equivalent to some tolerance. 
        
            if nargin < 3
                tol = obj1.EqualityTolerance;
            end
        
            bool = false;
            if all(strcmp(obj1.Labels, obj2.Labels)) && ...
                all(all(abs(obj1.Values - obj2.Values) < tol))
                bool = true;
            end
        
        end
        
        function [obj, another_obj] = synchronise(obj, another_obj, delay)
            
            % Access & adjust object timesteps.
            reference_times = obj.Timesteps;
            adjusted_times = another_obj.Timesteps + delay;
            
            % Zero each object.
            reference_times = reference_times - reference_times(1);
            obj.setTimesteps(reference_times);
            adjusted_times = adjusted_times - adjusted_times(1);
            another_obj.setTimesteps(adjusted_times);
            
            % Compute earliest start & latest finish.
            earliest_start = max(reference_times(1), adjusted_times(1));
            latest_finish = min(reference_times(end), adjusted_times(end));
            
            % Slice the objects to the synchronised times.
            obj = obj.slice(earliest_start, latest_finish);
            another_obj = another_obj.slice(earliest_start, latest_finish);
            
        end
        
        function new_obj = subsample(obj, increment)
        % Subsample data at timesteps from the beginning to end in even
        % steps of size increment. 
        %
        % This can be useful when dealing with RRA data which is at high
        % frequency and contains intermediate timesteps, without changing
        % the data by fitting it to a spline. 
            
            timesteps = obj.Timesteps;
            desired_timesteps = ...
                round(timesteps(1), 2):increment:round(timesteps(end), 2);
            
            if desired_timesteps(end) > timesteps(end)
                desired_timesteps(end) = [];
            end
            
            if desired_timesteps(1) < timesteps(1)
                desired_timesteps(1) = [];
            end
            
            desired_frames = zeros(size(desired_timesteps));
            for i=1:length(desired_timesteps)
                [~, loc] = min(abs(timesteps - desired_timesteps(i)));
                desired_frames(i) = loc;
            end
            
            new_obj = obj.slice(desired_frames);
            
        end
        
        function spline(obj, input, method)
        % Fit data to desired frequency using spline interpolation.
        %
        % If input is of length 1, it is assumed to be a desired frequency
        % at which to use linear interpolation to produce timesteps between
        % the object start and end frames. If it is of length > 1, it is
        % assumed to be an array of timesteps to use. 
        
            if nargin < 3
                method = 'spline';
            end
        
            switch length(input)
                case 1
                    % Use linear interpolation to create new timesteps.
                    timesteps = transpose(stretchVector(...
                        obj.Timesteps, input*obj.getTotalTime()+1));
                otherwise
                    timesteps = input;
            end
                
            % Isolate the spatial values (e.g. no time, no frames).
            values = obj.getStateData();
            
            % Spline the spatial values.
            splined_values = ...
                interp1(obj.Timesteps, values, timesteps, method);
                
            % Create the new, splined Data object & update. 
            obj.assignSpline(timesteps, splined_values);
            obj.update();

        end
        
        function filter4LP(obj, frequency)
            
            if isa(obj.Frequency, 'char')
                error('Frequency undefined - cannot filter.\n');
            else
                dt = 1/obj.Frequency;
                indices = obj.getStateIndices();
                for index = indices
                    input = obj.getColumn(index);
                    obj.setColumn(index, ...
                        ZeroLagButtFiltfilt(dt, frequency, 4, 'lp', input));
                end
            end
            
        end
        
        function extrapolate(obj, n)
        % Extrapolate forward by n timesteps.
        %
        % Tested using both spline and pchip. Pchip seemed to perform
        % better for lower values of n.
        
            if isa(obj.Frequency, 'char')
                error('Frequency undefined - cannot extrapolate.\n');
            else
                % Construct the new time array.
                timestep = 1/obj.Frequency;
                range = obj.getTimeRange();
                new_timesteps = transpose(range(1):timestep:range(2) + n*timestep);

                % Isolate the spatial values.
                values = obj.getStateData();

                % Spline these values.
                splined_values = ...
                    interp1(obj.Timesteps, values, new_timesteps, 'pchip');

                % Assign the splines values and update.
                obj.assignSpline(new_timesteps, splined_values);
                obj.update();
            end
            
        end
        
        function extend(obj, labels, values)
        % Append labels and values to a Data object. 
        
            obj.Values = [obj.Values values];
            labels = obj.convertLabels(labels);
            obj.Labels = [obj.Labels labels];
            obj.update();
                
        end
        
        function convert(obj, system)
        % Converts Cartesian data in to OpenSim co-ordinates. 
        %
        % See the convertSystem function for a fuller explanation and
        % description of the system input parameter. 
           
            if ~obj.IsCartesian
                error('Can only perform system conversion on Cartesian data.');
            end
            
            % Get the X, Y & Z labels.
            x_labels = ...
                obj.Labels(cellfun(@(x) strcmpi(x(end), 'x'), obj.Labels));
            y_labels = ...
                obj.Labels(cellfun(@(x) strcmpi(x(end), 'y'), obj.Labels));
            z_labels = ...
                obj.Labels(cellfun(@(x) strcmpi(x(end), 'z'), obj.Labels));
            
            % Step through the labels rotating the data. 
            for i=1:length(x_labels)
                coordinates = transpose([obj.getColumn(x_labels{i}), ...
                    obj.getColumn(y_labels{i}), obj.getColumn(z_labels{i})]);
                coordinates = convertSystem(coordinates, system); 
                indices = [obj.getIndex(x_labels{i}); ...
                    obj.getIndex(y_labels{i}); obj.getIndex(z_labels{i})];
                obj.Values(:, indices) = transpose(coordinates);
            end
            
            
        end
        
        function translate(obj, offsets)
           
            if ~obj.IsCartesian
                error('Rotate only supported for Cartesian data.');
            end
            
            % Get the labels with the data for each axis.
            checkLastChar = @(c) @(t) strcmpi(t(end), c);  
            x_labels = obj.Labels(cellfun(checkLastChar('x'), obj.Labels));
            y_labels = obj.Labels(cellfun(checkLastChar('y'), obj.Labels));
            z_labels = obj.Labels(cellfun(checkLastChar('z'), obj.Labels));
            
            % Step through the labels translating the data 
            unit_col = ones(obj.NFrames, 1);
            labels = {x_labels, y_labels, z_labels};
            for i = 1:3
                for j = 1:length(x_labels)
                    index = obj.getIndex(labels{i}{j});
                    obj.Values(:, index) = obj.Values(:, index) + ...
                        unit_col*offsets(i);              
                end
            end
            
        end
        
        function rotate(obj, rotations, left_handed)
        % Rotate the spatial data in a Cartesian data object. 
        
            if ~obj.IsCartesian
                error('Rotate only supported for Cartesian data.')
            end
            
            if nargin < 3
                left_handed = false;
            end
            
            % Construct the rotation matrix. Note: we take the transpose
            % here since we are rotating the axes (i.e. clockwise rotation
            % of vectors) rather than the points themselves (which would be
            % anticlockwise rotation). 
            R = transpose(...
                rotz(rotations(3))*roty(rotations(2))*rotx(rotations(1)));
            
            if left_handed
                R = transpose(R);
            end
            
            % Get the labels with the data for each axis.
            checkLastChar = @(c) @(t) strcmpi(t(end), c);
            x_labels = obj.Labels(cellfun(checkLastChar('x'), obj.Labels));
            y_labels = obj.Labels(cellfun(checkLastChar('y'), obj.Labels));
            z_labels = obj.Labels(cellfun(checkLastChar('z'), obj.Labels));
           
            % Step through the labels rotating the data. 
            for i=1:length(x_labels)
                indices = [obj.getIndex(x_labels{i}), ...
                    obj.getIndex(y_labels{i}), obj.getIndex(z_labels{i})];
                coordinates = transpose([obj.getColumn(indices(1)), ...
                    obj.getColumn(indices(2)), obj.getColumn(indices(3))]);
                rotation = transpose(R*coordinates);
                obj.Values(:, indices) = rotation;
            end
            
        end
        
        function new_obj = slice(obj, varargin)
        % Take a slice of a Data object. 
        %
        % More efficient to construct new object rather than creating a copy.
        % If nargin == 2, input is a vector of frames at which to slice. If 
        % nargin == 3, inputs are start and end times at which to slice.
        
            if nargin == 3
                timesteps = obj.Timesteps;
                frames = timesteps >= varargin{1} & timesteps <= varargin{2};
            else
                frames = varargin{1};
            end
        
            values = obj.Values(frames,1:end);
            constructor = class(obj);
            new_obj = feval(constructor, values, obj.Header, obj.Labels);
        end
        
        function new_obj = computeGradients(obj)
            
            new_obj = copy(obj);
            indices = new_obj.getStateIndices();
            time = new_obj.Timesteps;
            for i=indices
                current_val = new_obj.getColumn(i);
                diff = gradient(current_val, time);
                new_obj.setColumn(i, diff);
            end
            
        end
        
        function removeOutliers(obj, parameter, varargin)
           
            index = obj.getIndex(parameter);
            outliers = isoutlier(obj.Values(:, index), varargin{:});
            state_indices = obj.getStateIndices();
            obj.Values(:, state_indices) = filloutliers(...
                obj.Values(:, state_indices), 'linear', ...
                'OutlierLocations', repmat(outliers, 1, length(state_indices)));
            
            obj.update();
            
            
        end
        
        function writeToFile(obj, filename)
        % Write Data object with given filename - without extension.
        
            [path, name, ~] = fileparts(filename);
        
            % Update header before writing to file.
            obj.updateHeader();
            
            % Open proposed filename.
            if isempty(path)
                str = [name obj.Filetype];
            else
                str = [path filesep name obj.Filetype];
            end
            fileID = fopen(str, 'w');
            
            % Print file.
            obj.printHeader(fileID);
            obj.printLabels(fileID);
            obj.printValues(fileID);
            
            % Close file.
            fclose(fileID);
            
        end
        
        function vector = getFrames(obj)
        % Get the frames of this OpenSimData object.
           
                vector = obj.Frames;
            
        end
        
        function index = getFrame(obj, time)
           
            % Check that the time is in our timerange.
            range = obj.getTimeRange();
            if time >= range(1) && time <= range(2)
                [~, index] = min(abs(obj.Timesteps - time));
            else
                error('Time outwith timerange of data object.');
            end
            
        end
        
        function value = getValue(obj, row_parameter, col_parameter)
        % Get value corresponding to a certain row and column.
        %
        % The column may be referred to either by a label or an index. The
        % row must be referred to via an integer frame number.
        
            if isa(col_parameter, 'char')
                col_parameter = obj.getIndex(col_parameter);
            end
            value = obj.Values(row_parameter, col_parameter);
            
        end
        
        function vector = getColumn(obj, parameter)
        % Get column corresponding to label, index (int) or indices (row vec).
            if isa(parameter, 'char')
                vector = obj.Values(1:end, obj.getIndex(parameter));
            else
                vector = obj.Values(1:end, parameter);
            end
        end
        
        function setColumn(obj, parameter, array)
        % Set column corresponding to label, index (int) or indices (row vec).
        
            if isa(parameter, 'char')
                parameter = obj.getIndex(parameter);
            end
            
            time_index = obj.getIndex(obj.TimeLabel);
            if time_index == parameter
                error(['Attempting to set timesteps column - use ' ...
                    'setTimesteps instead.']);
            end
            
            obj.Values(:, parameter) = array;
        
        end
        
        function timesteps = getTimesteps(obj)
           
            index = obj.getIndex(obj.TimeLabel);
            timesteps = obj.getColumn(index);
            
        end
        
        function setTimesteps(obj, array)
            
            index = obj.getIndex(obj.TimeLabel);
            obj.Values(:, index) = array;
            obj.update();
            if obj.Frequency ~= obj.OrigFrequency
                fprintf(['Warning: setting new timesteps has caused ' ...
                    'changed in data frequency.\n']);
            end
            
        end
        
        function scaleColumns(obj, multiplier, indices)
        % Scale state data by some multiplier.
        %
        % Input indices can be a cell array of column names or a row vector
        % of column indices. Use only 2 arguments to scale all state
        % values.
            if nargin < 3
                indices = obj.getStateIndices();
            end
            
            if ~isempty(intersect(obj.getNonStateIndices(), indices))
                error('Attempting to scale non-state data.');
            end
            
            if isa(indices, 'cell')
                indices = cellfun(@obj.getIndex, indices); 
            end
            
            obj.Values(1:end, indices) = ...
                multiplier * obj.Values(1:end, indices);
        end
        
        function range = getTimeRange(obj)
        % Return [start_time, end_time] as row vector.
            range = [obj.Timesteps(1), obj.Timesteps(end)];
        end
        
        function time = getTotalTime(obj)
        % Return total time.
            time = obj.Timesteps(end) - obj.Timesteps(1);
        end
        
        function state_indices = getStateIndices(obj)
        % Get indices of state data.
        
            indices = 1:obj.NCols;
            non_state_indices = obj.getNonStateIndices();
            state_indices = setdiff(indices, non_state_indices);
        
        end
        
    end
    
    methods (Access = private)
    
        function parse(obj, filename)
        % Load filename, convert + assign Data properties. 
            
            % Load data from filename.
            [vals, lab, head] = obj.load(filename);
            
            % Convert data in to useable format & assign. Using static methods
            % within subclasses.
            obj.Header = obj.convertHeader(head);
            obj.Labels = obj.convertLabels(lab);
            obj.Values = obj.convertValues(vals);
        
        end
        
        function checkValues(obj)
        % Ensure that the entries of the Values array are well defined.
            if sum(sum(isnan(obj.Values))) ~= 0
                error('Data:NaNValues', ['One or more elements of the data '...
                       'array interpreted as NaN.'])
            end
        end
        
        function checkCartesian(obj)
        % Classifies Data objects as Cartesian or not.
        % Checks for the existence of X/Y/Z components in the column labels.
        
            % Define local function to compare the last character in a cell 
            % with a given character.
            function h = compare(character)
                h = @(c) strcmpi(c(end), character);
            end
      
            % Use cellfun & compare to isolate every x, y and z label - e.g
            % a label where the final character is X, Y or Z.
            x_labels = obj.Labels(cellfun(compare('x'), obj.Labels));
            y_labels = obj.Labels(cellfun(compare('y'), obj.Labels));
            z_labels = obj.Labels(cellfun(compare('z'), obj.Labels));
                
            % Check if the number of labels identified matches the number of
            % columns of spatial data. If so - Cartesian. 
            if length(obj.getStateIndices()) == ...
                length(x_labels) + length(y_labels) + length(z_labels)
                obj.IsCartesian = true;
            end
        
        end
        
        function calculateFrequency(obj)
        % Calculate the frequency of a data object. Note that number of actual
        % steps in time = total time frames - 1.
            if obj.getTotalTime ~= 0
                obj.Frequency = round((obj.NFrames - 1)/(obj.getTotalTime()));
            else
                obj.Frequency = obj.OrigFrequency;
            end
        end
        
        function update(obj)
        % Re-calculate Data properties. Call after any change in Values prop.
        %
        % Updates imesteps, number of frames & frame array, number of columns
        % and data frequency.
        
            obj.Timesteps = obj.getColumn(obj.TimeLabel);
            obj.NFrames = length(obj.Timesteps);
            obj.NCols = length(obj.Labels);
            obj.Frames = 1:obj.NFrames;
            obj.calculateFrequency();
        
        end
    
        function initialise(obj)
        % Store initial data pertaining to a data object, & check for errors.
        %
        % Specifically keeps a record of original number of frames and 
        % original frequency. Additionally, checks whether Data is Cartesian
        % and contains no NaN entries. 
        
            obj.update();
            obj.OrigNumFrames = length(obj.Timesteps);
            obj.OrigFrequency = obj.Frequency;
            obj.checkValues();
            obj.checkCartesian();
        
        end
        
        function printHeader(obj, fileID)
        % Print header information to a given fileID. 
            
            spec = repmat('%s\n', 1, length(obj.Header));
            fprintf(fileID, spec, obj.Header{:});
            
        end
        
        function index = getIndex(obj, label)
        % Get index corresponding to a specific label.
            index = find(strcmpi(strtrim(obj.Labels), strtrim(label)));
        end
        
        function indices = getNonStateIndices(obj)
            
            n_indices = length(obj.NonStateLabels);
            indices = zeros(1, n_indices);
            for i = 1:n_indices
                indices(i) = obj.getIndex(obj.NonStateLabels{i});
            end
            
        end
        
        function values = getStateData(obj)
        % Get state data - values without timesteps/frames.
        
            indices = obj.getStateIndices();
            values = obj.Values(:, indices);
            
        end
        
    end
    
end

