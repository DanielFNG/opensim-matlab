classdef Data < handle 
    % Class for storing and working with OpenSim data. 
    %   Easy access to reading and writing of data files in the correct
    %   format to be used within OpenSim. Methods for data handling
    %   including subsampling, ensuring time syncronisation of various data
    %   inputs, etc. Filenames are not stored since the data is designed to
    %   be worked with and so the original filename is likely to be out of
    %   date anyway. Data should be numerical. Text can appear in labels or
    %   in the header, but text in the main body of the data leads to
    %   incompatability. 
    
    properties
        Values 
        Labels
        Header
        Frames
        Timesteps
        Frequency
    end
    
    properties
        Filetype
    end
    
    methods
    
        % Construct Data object from filename.
        function obj = Data(filename)
            if nargin > 0
                % Different behaviour for TRC files.
                [~, ~, ext] = fileparts(filename);
                if strcmpi('.trc', ext)
                    obj.loadTRC(filename);
                    obj.Filetype = 'TRC';
                else
                    obj.loadMOTSTO(filename);
                    if strcmp('.sto', ext)
                        obj.Filetype = 'STO';
                    elseif strcmp('.mot', ext)
                        obj.Filetype = 'MOT';
                    else
                        obj.Filetype = 'Unrecognised';
                    end
                end
                % Check for NaN's in the data file. 
                obj.checkValues();
                
                % Get the timesteps.
                obj.Timesteps = obj.getColumn('time');
                
                % Store the # of frames and the frequency of the data.
                obj.Frames = length(obj.Timesteps);
                obj.getFrequency();
            end
        end
        
        % Construct Data object for a TRC file. 
        function loadTRC(obj, filename)
            % Open the file.
            id = fopen(filename);
            
            % Read in the header to a cell array.
            for i=1:6
                line = fgetl(id);
                obj.Header{i} = line;
            end
            
            % Construct the labels.
            labels = strsplit(obj.Header{4});
            
            obj.Labels{1} = labels{1};
            obj.Labels{2} = labels{2};
            k = 3;
            for i=3:size(labels,2)-1
                obj.Labels{k} = labels{i};
                obj.Labels{k+1} = '';
                obj.Labels{k+2} = '';
                k = k + 3;
            end
            
            % Now get the values.
            n_cols = length(obj.Labels);
            count = 1;
            while true
                line = fgetl(id);
                if ~ischar(line)
                    break;
                end
                str_values{count} = strsplit(line);
                % Sometimes the last column can be just a new
                % line, which we don't want.
                if isempty(str_values{count}{end})
                    str_values{count} = str_values{count}(1:end-1);
                end
                count = count + 1;
            end
            values = zeros(size(str_values,2), n_cols);
            for i=1:size(str_values,2)
                values(i,1:end) = str2double(str_values{1,i});
            end
            obj.Values = values;
            
            % Close the file.
            fclose(id);
        end
        
        % Get header and column labels from textdata. 
        function obj = loadMOTSTO(obj, filename)
            data_array = importdata(filename);
            try
                obj.Values = data_array.data;
                obj.Header = data_array.textdata(1:end-1, 1);
                obj.Labels = data_array.colheaders;
            catch
                error('Data parsing failed.');
            end
        end
        
        % Check that the entries of the Values array are well defined, if not 
        % return an error.
        function checkValues(obj)
            if sum(sum(isnan(obj.Values))) ~= 0
                error('Data:NaNValues', ['One or more elements of the data '...
                       'array interpreted as NaN.'])
            end
        end
        
        function getFrequency(obj)
            obj.Frequency = obj.Frames/(obj.Timesteps(end) - obj.Timesteps(1));
        end

%% THIS NEEDS TO BE UPDATED
%         % Typically OpenSim data formats will have an 'nColumns' and
%         % 'nRows' entry in the header. Identify if this is the case and
%         % allow update of these values following changes to a data file. 
%         function obj = updateHeader(obj)
%             for i=1:size(obj.Header)
%                 if cell2mat(strfind(obj.Header(i),'nRows'))
%                     obj.Header(i) = ...
%                             cellstr(['nRows=', int2str(size(obj.Values,1))]);
%                     checkingForMultipleNRows = checkingForMultipleNRows + 1;
%                 elseif cell2mat(strfind(obj.Header(i),'datarows'))
%                     obj.Header(i) = ...
%                             cellstr(['datarows ', int2str(size(obj.Values,1))]);
%                         checkingForMultipleNRows = checkingForMultipleNRows + 1;
%                 elseif cell2mat(strfind(obj.Header(i),'nColumns')) 
%                     obj.Header(i) = ...
%                             cellstr(['nColumns=', int2str(size(obj.Values,2))]);
%                     checkingForMultipleNColumns = ...
%                             checkingForMultipleNColumns + 1;
%                 elseif cell2mat(strfind(obj.Header(i),'datacolumns'))
%                     obj.Header(i) = ...
%                             cellstr(['datacolumns ', int2str(size(obj.Values,2))]);
%                         checkingForMultipleNColumns = ...
%                             checkingForMultipleNColumns + 1;
%                 end
%             end
%         end
%%
        % Write data object to a tab delimited file. 
        % TRC files should be written with headers only because of the
        % difference in labelling between the actual file and the Data
        % interpretation.
        function writeToFile(obj, filename)
            fileID = fopen(filename,'w');
                for i=1:size(obj.Header,1)
                    fprintf(fileID,'%s\n', char(obj.Header(i)));
                end
            if  ~strcmp(obj.Filetype, 'TRC')
                for i=1:size(obj.Labels,2)
                    fprintf(fileID,'%s\t', char(obj.Labels(i)));
                end
                fprintf(fileID,'\n');
            end
            for i=1:size(obj.Values,1)
                for j=1:size(obj.Values,2)
                    if strcmp(obj.Filetype, 'TRC') && j == 1
                        fprintf(fileID, '%d\t', obj.Values(i,j));
                    else
                        fprintf(fileID,'%12.14f\t', obj.Values(i,j));
                    end
                end
                fprintf(fileID,'\n');
            end
            fclose(fileID);
        end
        
        % Overload equality.
        function bool = eq(obj1, obj2)
            
            if all(size(obj1.Values) == size(obj2.Values)) && ...
                    all(size(obj1.Labels) == size(obj2.Labels)) && ...
                    all(size(obj1.Header) == size(obj2.Header)) && ...
                    all(all(obj1.Values == obj2.Values)) && ...
                    all(strcmp(obj1.Labels, obj2.Labels)) && ...
                    all(strcmp(obj1.Header, obj2.Header))
                bool = true;
            else
                bool = false;
            end
            
        end
        
        function bool = eqToTolerance(obj1, obj2, tol)
            
            if all(size(obj1.Values) == size(obj2.Values)) && ...
                    all(size(obj1.Labels) == size(obj2.Labels)) && ...
                    all(size(obj1.Header) == size(obj2.Header)) && ...
                    all(all(abs(obj1.Values - obj2.Values) < tol)) && ...
                    all(strcmp(obj1.Labels, obj2.Labels)) && ...
                    all(strcmp(obj1.Header, obj2.Header))
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
            % Check that the data objects have equal frames and timesteps,
            % giving a specific error message to each case. 
            if ~(size(obj1.Frames) == size(obj2.Frames))
                error(['Data objects can only be added if they have the '...
                    'same number of frames.']);
            end
            if sum(round(obj1.Timesteps,3) ~= round(obj2.Timesteps,3)) ~= 0
                error(['Timesteps must match precisely to use Data '...
                    'addition. If necessary, spline your Data objects.']);
            end
            
            % Define some sizes - number of colums of data in each object. 
            size1 = size(obj1.Values,2);
            size2 = size(obj2.Values,2);
            
            % Set up and result and re-allocate the Values.
            new_col_size = size1 + size2 - 1;
            % We need to -1 above because they both have a time-step
            % column, if we don't this will be counted twice!
            result = obj1;
            result.Values = zeros(size(obj1.Timesteps,1),new_col_size);
            
            % Copy over the values from the input objects. 
            result.Values(1:end,1) = result.Timesteps(1:end,1);
            result.Values(1:end,2:size1) = obj1.Values(1:end,2:end);
            result.Values(1:end,size1+1:end) = obj2.Values(1:end,2:end);
            
            % Add labels together, and update header to reflect changes.
            for i=size1+1:size1+size2-1
                result.Labels{1,i} = obj2.Labels{1,i+1-size1};
            end
            result = result.updateHeader();
        end
      
        % Get, as a vector, the data corresponding to a specific label.
        % Returns 0 if the label could not be matched. 
        function vector = getColumn(obj, parameter)
            if isa(parameter, 'char')
                vector = obj.Values(1:end, strcmpi(obj.Labels, parameter));
            else
                vector = obj.Values(1:end, parameter);
            end
        end
        
        % Get, as an int, the index corresponding to a specific label.
        function index = getIndex(obj, label)
            index = find(strcmp(obj.Labels, label));
        end
        
        % Scale columns by some multiplier. 
        function obj = scaleColumns(obj, indices, multiplier)
            if strcmpi(obj.Labels(indices), 'time') 
                warning('Are you sure you meant to scale the time column?');
            end
            obj.Values(1:end, indices) = ...
                multiplier * obj.Values(1:end, indices);
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
            
            % Update header file to reflect changes. 
            obj = obj.updateHeader();
            
            % Update frequency information.
            obj.Frames = length(obj.Timesteps);
            obj.Frequency = desired_frequency;
        end
        
    end
    
    methods(Static)
        
        % Given a cell containing 'time vx vy vz...' etc which is 1x1
        % separate it in to 1 x n by detecting the spaces. 
        function headers = detectSpaces(cell)
            cellToString = char(cell);
            headers = strsplit(cellToString);
            % Occasionally headers can have its last entry as ''. This is 
            % undesirable so it is removed if it exists. Likewise for the 
            % first entry.
            if strcmp(headers(end),'')
                headers(end) = [];
            end
            if strcmp(headers(1),'')
                headers(1) = [];
            end
        end
    end
    
end

