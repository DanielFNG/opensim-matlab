classdef Data
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
    end
    
    properties (SetAccess = private)
        % Should be most (all?) of the properties above. 
        HasHeader = false
        IsLabelled = false
    end
    
    methods
        
        % Construct Data object from filename.
        function obj = Data(filename)
            if nargin > 0
                if ischar(filename)
                    % Different behaviour for TRC files. 
                    if strcmp(filename(end-3:end), '.trc')
                        obj.HasHeader = true;
                        obj.IsLabelled = true;
                        
                        % Open the file.
                        id = fopen(filename);
                        
                        % Read in the header to a cell array.
                        line = fgetl(id);
                        obj.Header{1,1} = line;
                        line = fgetl(id);
                        obj.Header{2,1} = line;
                        line = fgetl(id);
                        obj.Header{3,1} = line;
                        line = fgetl(id);
                        obj.Header{4,1} = line;
                        
                        % Construct the labels.
                        labels = strsplit(line);
                        
                        obj.Labels{1} = labels{1,1};
                        obj.Labels{2} = labels{1,2};
                        k = 3;
                        for i=3:size(labels,2)-1
                            obj.Labels{k} = [labels{1,i} 'X'];
                            obj.Labels{k+1} = [labels{1,i} 'Y'];
                            obj.Labels{k+2} = [labels{1,i} 'Z'];
                            k = k + 3;
                        end
                        
                        % Construct the last bit of the header. 
                        line = fgetl(id);
                        obj.Header{5,1} = line;
                        line = fgetl(id);
                        obj.Header{6,1} = line; % this is the empty line
                        
                        % Now get the values.
                        n_cols = size(obj.Labels,2);
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
                        obj.Frames = size(values,1);
                        
                        % Close the file.
                        fclose(id);
                    else
                        dataArray = importdata(filename);
                        % If there is a textdata property, check the last
                        % (potentially only) row. If this is a single cell
                        % (i.e. 1x1 rather than 1xn), run it through detectSpaces
                        % to see if it's a long string of headers. If it is
                        % (i.e. you get at least a 1x2 cell array) OR if the
                        % original thing was at least a 1x2 cell array, assume
                        % that this row corresponds to labels.

                        % If there is anything else in textdata before this,
                        % put it as a header. 

                        % Not using colheaders of the importdata function because 
                        % sometimes in my testcases this property doesn't exist 
                        % even when the data is labelled. 
                        if isa(dataArray,'struct')
                            obj = obj.getHeaderAndLabels(dataArray.textdata);
                            if sum(strcmp('',obj.Labels)) > 0 
                                error('Data file has one or more empty labels.')
                            end
                            obj.Values = dataArray.data;
                            if size(obj.Labels, 2) ~= size(obj.Values, 2)
                                error(['Number of labels does not match the '...
                                       'number of columns of data.'])
                            end
                            obj.Frames = size(dataArray.data,1);
                        elseif isa(dataArray,'double')
                            obj.Values = dataArray;
                            obj.Frames = size(dataArray,1);
                        else
                            error('Unrecognised data file format.')
                        end
                    end
                else
                    error(['Error in construction: expected input filename '...
                           'as string, got %s.'], class(filename))
                end
                obj.checkValues();
                if sum(strcmpi('time',obj.Labels)) == 1
                    % Use TimeSeriesData instead.
                elseif sum(strcmpi('time',obj.Labels)) > 1
                    error(['More than one column recognised as time data. '...
                           'Check column labels in data file.'])
                end
            end
        end
        
        % Get header and column labels from textdata. 
        function obj = getHeaderAndLabels(obj, textData)
            if size(textData(end,:),2) == 1
                potentialLabels = obj.detectSpaces(textData(end,:));
                if size(potentialLabels, 2) == 1
                    obj.isLabelled = false;
                    obj.hasHeader = true;
                    obj.Header = textData;
                else
                    obj.Labels = potentialLabels;
                    obj.isLabelled = true;
                end
            else
                obj.Labels = textData(end,:);
                obj.IsLabelled = true;
            end
            if obj.IsLabelled
                if size(textData,1) > 1
                    obj.HasHeader = true;
                    obj.Header = textData(1:end-1,1);
                end
            end
        end
        
        % Check that the entries of the Values array are well defined, if not 
        % return an error.
        function obj = checkValues(obj)
            if sum(sum(isnan(obj.Values))) ~= 0
                error('Data:NaNValues', ['One or more elements of the data '...
                       'array interpreted as NaN. Could be an error in the '...
                       'data set, or a blank cell/row/column. There should '...
                       'be no space between the data labels/header '...
                       '(if they exist) and the beginning of the data '...
                       'entries. Check your data set.'])
            end
        end
        
        % Typically OpenSim data formats will have an 'nColumns' and
        % 'nRows' entry in the header. Identify if this is the case and
        % update these values following changes to a data file. 
        function obj = updateHeader(obj)
            checkingForMultipleNRows = 0;
            checkingForMultipleNColumns = 0;
            for i=1:size(obj.Header)
                if cell2mat(strfind(obj.Header(i),'nRows'))
                    obj.Header(i) = ...
                            cellstr(['nRows=', int2str(size(obj.Values,1))]);
                    checkingForMultipleNRows = checkingForMultipleNRows + 1;
                elseif cell2mat(strfind(obj.Header(i),'datarows'))
                    obj.Header(i) = ...
                            cellstr(['datarows ', int2str(size(obj.Values,1))]);
                        checkingForMultipleNRows = checkingForMultipleNRows + 1;
                elseif cell2mat(strfind(obj.Header(i),'nColumns')) 
                    obj.Header(i) = ...
                            cellstr(['nColumns=', int2str(size(obj.Values,2))]);
                    checkingForMultipleNColumns = ...
                            checkingForMultipleNColumns + 1;
                elseif cell2mat(strfind(obj.Header(i),'datacolumns'))
                    obj.Header(i) = ...
                            cellstr(['datacolumns ', int2str(size(obj.Values,2))]);
                        checkingForMultipleNColumns = ...
                            checkingForMultipleNColumns + 1;
                end
            end
            if checkingForMultipleNRows > 1 || checkingForMultipleNColumns > 1
                error('Found multiple row/column sizes in header!');
            end
        end
        
        % Write data object to a tab delimited file. 
        % TRC files should be written with headers ONLY because of the
        % difference in labelling between the actual file and the Data
        % interpretation.
        function writeToFile(obj, filename, withHeader, withLabels)
            fileID = fopen(filename,'w');
            if obj.hasHeader && (withHeader == 1)
                for i=1:size(obj.Header,1)
                    fprintf(fileID,'%s\n', char(obj.Header(i)));
                end
            end
            if obj.isLabelled && (withLabels == 1)
                for i=1:size(obj.Labels,2)
                    fprintf(fileID,'%s\t', char(obj.Labels(i)));
                end
                fprintf(fileID,'\n');
            end
            for i=1:size(obj.Values,1)
                for j=1:size(obj.Values,2)
                    fprintf(fileID,'%12.14f\t', obj.Values(i,j));
                end
                fprintf(fileID,'\n');
            end
            fclose(fileID);
        end
        
        % Write TRC files. Header only and require ints for the first
        % column.
        function writeTRCToFile(obj, filename, withHeader)
            fileID = fopen(filename,'w');
            if obj.hasHeader && (withHeader == 1)
                for i=1:size(obj.Header,1)
                    fprintf(fileID,'%s\n', char(obj.Header(i)));
                end
            end
            for i=1:size(obj.Values,1)
                fprintf(fileID,'%d\t', obj.Values(i,1));
                for j=2:size(obj.Values,2)
                    fprintf(fileID,'%12.14f\t', obj.Values(i,j));
                end
                fprintf(fileID,'\n');
            end
            fclose(fileID);
        end
        
        function logical = eq(obj1, obj2)
            
            if all(size(obj1.Values) == size(obj2.Values)) && ...
                    all(size(obj1.Labels) == size(obj2.Labels)) && ...
                    all(size(obj1.Header) == size(obj2.Header)) && ...
                    all(all(obj1.Values == obj2.Values)) && ...
                    all(strcmp(obj1.Labels, obj2.Labels)) && ...
                    all(strcmp(obj1.Header, obj2.Header))
                logical = true;
            else
                logical = false;
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
        function vector = getDataCorrespondingToLabel(obj,label)
            vector = 0;
            for i=1:size(obj.Labels,2)
                if strcmp(label, char(obj.Labels{i}))
                    vector = obj.Values(1:end,i);
                end
            end     
        end
        
        % Get, as an int, the index corresponding to a specific label.
        % Returns 0 if the label could not be matched. 
        function index = getIndexCorrespondingToLabel(obj, label)
            index = 0;
            for i=1:size(obj.Labels,2)
                if strcmp(label, char(obj.Labels{i}))
                    index = i;
                end
            end
        end
        
        function index = getIndexCorrespondingToTimestep(obj, timestep)
            index = 0;
            for i=1:size(obj.Timesteps,2)
                if obj.Timesteps(i) == timestep
                    index = i;
                end
            end
        end
        
        function obj = scaleColumn(obj,index,multiplier)
            if strcmp(obj.Labels(index), 'time') 
                error('You probably dont want to be scaling time col.');
            end
            obj.Values(1:end,index) = multiplier*obj.Values(1:end,index);
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

