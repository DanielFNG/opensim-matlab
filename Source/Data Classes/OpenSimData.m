classdef (Abstract) OpenSimData < handle & matlab.mixin.Copyable
    % Abstract Class for storing & working with OpenSim data.
    % 
    % Holds many methods which are generic to each type of OpenSimData. Specific
    % methods are defined as Abstract here, and are later redefined in the 
    % appropriate subclasses. 
    
    properties (Abstract, SetAccess = protected)
        Filetype
    end
    
    properties (SetAccess = protected)
        Frequency
        NFrames
        NCols
        IsCartesian = false
    end
    
    properties (SetAccess = protected, GetAccess = protected)
        Header
        Labels
        Frames
        Timesteps
        Values
        OrigNumFrames
        OrigFrequency
        EqualityTolerance = 1e-6
    end
    
    methods (Abstract)
    
        updateHeader(obj)
        printLabels(obj, fileID)
        printValues(obj, fileID)
        splined_obj = assignSpline(obj, timesteps, values)
    
    end
    
    methods (Abstract, Static)
        
        load(filename)
        convertHeader(input_header)
        convertLabels(input_labels)
        convertValues(input_values, input_labels)
        
    end
    
    methods
    
        function obj = OpenSimData(varargin)
        % Construct OpenSimData from (file) or from (values, header, labels).
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
                obj.update();
                obj.initialise();
            end
        end
        
        function writeToFile(obj, filename)
        % Write Data object with given filename - without extension.
        
            % Update header before writing to file.
            obj.updateHeader();
            
            % Open proposed filename.
            fileID = fopen([filename obj.Filetype], 'w');
            
            % Print file.
            obj.printHeader(fileID);
            obj.printLabels(fileID);
            obj.printValues(fileID);
            
            % Close file.
            fclose(fileID);
            
        end
        
        function bool = eq(obj1, obj2, tol)
        
            if nargin < 3
                tol = obj1.EqualityTolerance;
            end
        
            if all(strcmp(obj1.Labels, obj2.Labels)) && ...
                all(strcmp(obj1.Header, obj2.Header)) && ...
                all(all(abs(obj1.Values - obj2.Values) < tol))
                bool = true;
            else
                bool = false;
            end
        
        end
        
        function index = getIndex(obj, label)
        % Get index corresponding to a specific label.
            index = find(strcmpi(obj.Labels, label));
        end
        
        function indices = getSpatialIndices(obj)
        
            time = obj.getIndex('time');
            indices = (time + 1):obj.NCols;
        
        end
        
        function values = getSpatialValues(obj)
        
            indices = obj.getSpatialIndices();
            values = obj.Values(:, indices);
            
        end
      
        function vector = getColumn(obj, parameter)
        % Get column corresponding to label, index (int) or indices (row vec).
            if isa(parameter, 'char')
                vector = obj.Values(1:end, obj.getIndex(parameter));
            else
                vector = obj.Values(1:end, parameter);
            end
        end
        
        function range = getTimeRange(obj)
            range = [obj.Timesteps(1), obj.Timesteps(end)];
        end
        
        function time = getTotalTime(obj)
            time = obj.Timesteps(end) - obj.Timesteps(1);
        end
        
        function spline(obj, desired_frequency)
        % Fit data to desired frequency using spline interpolation.
        
            % Use linear interpolation to create new timesteps.
            timesteps = stretchVector(...
                obj.Timesteps, desired_frequency*obj.getTotalTime()+1);
                
            % Isolate the spatial values (e.g. no time, no frames).
            values = obj.getSpatialValues();
            
            % Spline the spatial values.
            splined_values = ...
                interp1(obj.Timesteps, values, timesteps, 'spline');
                
            % Create the new, splined Data object & update. 
            obj.assignSpline(timesteps, splined_values);
            obj.update();

        end
        
        function extend(obj, labels, values)
        % Append labels and values to a Data object. 
        
            obj.Values = [obj.Values values];
            labels = obj.convertLabels(labels);
            obj.Labels = [obj.Labels labels];
                
        end
        
        function scaleColumns(obj, indices, multiplier)
        % Scale a row vector of columns by some multiplier. 
            if any(indices <= obj.getIndex('time'))
                error('Attempting to scale non spatial data.');
            end
            obj.Values(1:end, indices) = ...
                multiplier * obj.Values(1:end, indices);
        end
        
        function setColumn(obj, parameter, array)
        
            if isa(parameter, 'char')
                index = obj.getIndex(parameter);
                obj.Values(:, index) = array;
            else
                obj.Values(:, parameter) = array;
            end
        
        end
        
        function rotate(obj, xrot, yrot, zrot)
        % Rotate the spatial data in a Cartesian data object. 
        
            if ~obj.IsCartesian
                error('Rotate only supported for Cartesian data.')
            end
            
            % Construct the rotation matrix.
            R = rotz(zrot)*roty(yrot)*rotx(xrot);
            
            % Get the labels with the X axis data.
            x_labels = ...
                obj.Labels(cellfun(@(x) strcmpi(x(end), 'x'), obj.Labels));
            
            % Step through the labels rotating the data. 
            for i=1:length(x_labels)
                label = x_labels{i}(1:end-1);
                x_index = obj.getIndex(x_labels{i});
                coordinates = transpose([obj.getColumn([label 'X']), ...
                    obj.getColumn([label 'Y']), obj.getColumn([label 'Z'])]);
                rotation = transpose(R*coordinates);
                obj.Values(:, x_index:x_index+2) = rotation;
            end
            
        end
        
        function new_obj = slice(obj, frames)
        % Take a slice of a Data object. Like pizza. 
        %
        % Originally this was done by copying the input object, but I think
        % creating a new object from scratch using the subset of values should
        % be more efficient. 
            values = obj.Values(frames,1:end);
            new_obj = OpenSimData(values, obj.Labels, obj.Header);
        end
        
        function new_obj = old_slice(obj, frames)
            new_obj = copy(obj);
            new_obj.Values = obj.Values(frames, :);
            new_obj.update();
        end
        
    end
    
    methods (Access = private)  % Checks & update calculations.
    
        function [values, labels, header] = parse(obj, filename)
        % Load filename, convert + assign Data properties. 
        
            [vals, lab, head] = obj.load(filename);
            
            obj.Header = obj.convertHeader(head);
            
            obj.Labels = obj.convertLabels(lab);
            
            obj.Values = obj.convertValues(vals, labels);
        
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
            if length(obj.getSpatialIndices()) == ...
                length(x_labels) + length(y_labels) + length(z_labels)
                obj.IsCartesian = true;
            end
        
        end
        
        function calculateFrequency(obj)
        % Calculate the frequency of a data object. Note that number of actual
        % steps in time = total time frames - 1.
            obj.Frequency = round(...
                (obj.NFrames - 1)/(obj.Timesteps(end) - obj.Timesteps(1)));
        end
        
        function update(obj)
        % Re-calculate Data properties. Call after any change in Values prop.
        %
        % Updates imesteps, number of frames & frame array, number of columns
        % and data frequency.
        
            obj.Timesteps = obj.getColumn('time');
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
            
            for i=1:length(obj.Header)
                fprintf(fileID, '%s\n', obj.Header{i});
            end
            
        end
        
    end
    
end

