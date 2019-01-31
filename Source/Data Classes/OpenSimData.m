classdef (Abstract) OpenSimData < handle & matlab.mixin.Copyable
    % Class for storing and working with OpenSim data. 
    %   Easy access to reading and writing of data files in the correct
    %   format to be used within OpenSim. Methods for data handling
    %   including spline fitting and combining data objects. Compliance
    %   with the OpenSim data file formats (.trc, .mot, .sto) is assumed.
    
    properties (Abstract, SetAccess = protected)
        Filetype
    end
    
    properties (SetAccess = protected)
        IsCartesian = false
        Frequency
        NFrames
        NCols
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
    
    end
    
    methods (Abstract, Static)
        
        load(filename)
        parse(filename)
        
    end
    
    methods
    
        function obj = OpenSimData(varargin)
        % Construct OpenSimData from (file) or from (values, header, labels).
            if nargin > 0
                if nargin == 1
                    try
                        [values, labels, header] = obj.parse(varargin{1});
                        obj.Values = values;
                        obj.Header = header;
                        obj.Labels = labels;
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
    
        function update(obj)
        
            obj.Timesteps = obj.getColumn('time');
            obj.NFrames = length(obj.Timesteps);
            obj.NCols = length(obj.Labels);
            obj.Frames = 1:obj.NFrames;
            obj.calculateFrequency();
        
        end
    
        function initialise(obj)
        
            obj.update();
            obj.OrigNumFrames = length(obj.Timesteps);
            obj.OrigFrequency = obj.Frequency;
            obj.checkValues();
            obj.checkCartesian();
        
        end
        
        function printHeader(obj, fileID)
            
            for i=1:length(obj.Header)
                fprintf(fileID, '%s\n', obj.Header{i});
            end
            
        end
        
        function writeToFile(obj, filename)
        
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
        
        function new_obj = slice(obj, frames)
            new_obj = copy(obj);
            new_obj.Values = obj.Values(frames,1:end);
            new_obj.update();
        end
        
        function extend(obj, labels, values)
            obj.Values = [obj.Values values];
            if strcmp(obj.Filetype, 'TRC')
                k = length(obj.Labels);
                for i=1:length(labels)
                    obj.Labels{k + 1} = [labels{i} '_X'];
                    obj.Labels{k + 2} = [labels{i} '_Y'];
                    obj.Labels{k + 3} = [labels{i} '_Z'];
                    k = k + 3;
                end
            else
                obj.Labels(end + 1:end + length(labels)) = labels;
            end
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
        
        % Overload addition. Data objects which share an identical timestep
        % array can be added together. One is essentially appended on to
        % the other, and the labels and header are updated accordingly. NOTE: 
        % THE HEADER IS TAKEN FROM THE FIRST ARGUMENT!
        function result = plus(obj1,obj2)
            % No addition due to more complicated header setup and unlikely
            % need to add markers in this way. 
            if strcmp(obj1.Filetype, 'TRC')
                error('Addition not supported for TRC files.');
            elseif ~strcmp(obj1.Filetype, obj2.Filetype)
                error('Files must have same filetype.');
            end
            
            % Check that the data objects have equal frames and timesteps,
            % giving a specific error message to each case. 
            if ~(size(obj1.NFrames) == size(obj2.NFrames))
                error(['Data objects can only be added if they have the '...
                    'same number of frames.']);
            end
            if sum(round(obj1.Timesteps,3) ~= round(obj2.Timesteps,3)) ~= 0
                error(['Timesteps must match precisely to use Data '...
                    'addition. If necessary, spline your Data objects.']);
            end
            
            % Define some sizes - number of colums of data in each object. 
            size1 = size(obj1.Values,2) - 1;
            size2 = size(obj2.Values,2) - 1;
            
            % Set up and result and re-allocate the Values.
            new_col_size = size1 + size2;
            
            result = copy(obj1);
            result.Values = zeros(size(obj1.Timesteps,1),new_col_size + 1);
            
            % Copy over the values from the input objects.
            result.Values(1:end, 1) = obj1.Timesteps;
            result.Values(1:end,2:size1) = obj1.Values;
            result.Values(1:end,size1+1:end) = obj2.Values;
            
            % Add labels together, and update header to reflect changes.
            for i=size1+2:1+size1+size2
                result.Labels{1,i} = obj2.Labels{1,i-size1};
            end
        end
        
        function rotate(obj, xrot, yrot, zrot)
        
            if ~obj.IsCartesian
                error('Rotate only supported for Cartesian data.')
            end
            
            % Construct the rotation matrix.
            R = rotz(zrot)*roty(yrot)*rotx(xrot);
            
            % Get the labels with the X axis data.
            x_labels = ...
                obj.Labels(cellfun(@(x) strcmpi(x(end), 'x'), obj.Labels));
            
            % Step through rotating the data. 
            for i=1:length(x_labels)
                label = x_labels{i}(1:end-1);
                x_index = obj.getIndex(x_labels{i});
                coordinates = transpose([obj.getColumn([label 'X']), ...
                    obj.getColumn([label 'Y']), obj.getColumn([label 'Z'])]);
                rotation = transpose(R*coordinates);
                obj.Values(:, x_index:x_index+2) = rotation;
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
      
        function vector = getColumn(obj, parameter)
        % Get column corresponding to label, index (int) or indices (row vec).
            if isa(parameter, 'char')
                vector = obj.Values(1:end, obj.getIndex(parameter));
            else
                vector = obj.Values(1:end, parameter);
            end
        end
        
        function setColumn(obj, parameter, array)
        
            if isa(parameter, 'char')
                index = obj.getIndex(parameter);
                obj.Values(:, index) = array;
            else
                obj.Values(:, parameter) = array;
            end
        
        end
        
        % Scale row vec of columns by some multiplier. 
        function obj = scaleColumns(obj, indices, multiplier)
            if any(indices <= obj.getIndex('time'))
                error('Attempting to scale non spatial data.');
            end
            obj.Values(1:end, indices) = ...
                multiplier * obj.Values(1:end, indices);
        end
        
        function range = getTimeRange(obj)
            range = [obj.Timesteps(1), obj.Timesteps(end)];
        end
        
        % Use splines to obtain smooth data of the desired frequency.
        function obj = fitToSpline(obj, desired_frequency)
            % Generate the desired sample points. Rounding is necessary to
            % ensure that the resultant array properly goes from the start
            % to the end point, inclusive. 
            x = (round(obj.Timesteps(1),4): ...
                round(1/desired_frequency,4): ...
                round(obj.Timesteps(end),4))';
            
            % Isolate the matrix of values.
            y = obj.Values(1:end,2:end);

            % Re-allocate the values array. 
            obj.Values = zeros(size(x,1), size(obj.Values,2));
            
            % Fit to spline.
            obj.Values(1:end,2:end) = interp1(obj.Timesteps, y, x, 'spline');
            
            % Re-allocate and set timesteps.
            obj.Timesteps = zeros(size(x,1),1);
            obj.Timesteps(1:end,1) = x;
            obj.Values(1:end,1) = x;
            
            % Update frequency information.
            obj.NFrames = length(obj.Timesteps);
            obj.Frequency = desired_frequency;
        end
        
    end
    
    methods (Access = private)        
        
        % Check that the entries of the Values array are well defined, if not 
        % return an error.
        function checkValues(obj)
            if sum(sum(isnan(obj.Values))) ~= 0
                error('Data:NaNValues', ['One or more elements of the data '...
                       'array interpreted as NaN.'])
            end
        end
        
        function checkCartesian(obj)
        
            function h = compare(direction)
                h = @(c) strcmpi(c(end), direction);
            end
      
            x_labels = obj.Labels(cellfun(compare('x'), obj.Labels));
            y_labels = obj.Labels(cellfun(compare('y'), obj.Labels));
            z_labels = obj.Labels(cellfun(compare('z'), obj.Labels));
                
            if length(obj.Labels) == obj.getIndex('time') + ...
                length(x_labels) + length(y_labels) + length(z_labels)
                obj.IsCartesian = true;
            end
        
        end
        
        function calculateFrequency(obj)
            obj.Frequency = round(...
                (obj.NFrames - 1)/(obj.Timesteps(end) - obj.Timesteps(1)));
        end
        
    end
    
end

