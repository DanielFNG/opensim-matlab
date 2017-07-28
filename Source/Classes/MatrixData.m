classdef MatrixData
    % Class for storing and working with data corresponding to a
    % time-indexed sequence of matrices. I'm going to make the assumption
    % that we don't have a header or labels. Typically I'll be working with
    % Jacobians calculated from getFrameJacobians which are unlablled with
    % no header so this should be fine. Also because of this I typically
    % won't be worrying about whether or not the data is at a consistent
    % frequency. The matrices are all of constant row and column size. 
    
    properties (SetAccess = private)
        nRows
        nCols 
        Values % cell array of nRowsxnCols matrices 
        Timesteps
        Frequency
    end
    
    methods
        
        % Construct MatrixData.
        function obj = MatrixData(filename, expectedRows, expectedCols)
            % Function supports 0 input arguments for empty object as
            % usual. 1 argument to construct MatrixData object from
            % filename and calculate the dimensions of the matrices.
            % Precisely 3 arguments to check whether the data is being
            % interpreted as expected. 
            if nargin > 0
                if nargin == 1 || nargin == 3
                    temp = importdata(filename);
                    % Remove time column when calculating size. 
                    obj.nCols = size(temp,2) - 1;
                    [frames, obj.Timesteps] = ... 
                        MatrixData.getTimesteps(temp(1:end,1));
                    % Assume frequency = 1/(frame 2 - frame 1).
                    obj.Frequency = 1/(obj.Timesteps(2,1) - obj.Timesteps(1,1));
                    obj.nRows = size(temp,1)/frames;
                    obj.Values = ...
                        MatrixData.getMatrixArray(obj.nRows, temp(:,2:end));
                    if (nargin == 3) && ...
                            ( (obj.nRows ~= expectedRows) ...
                            || (obj.nCols ~= expectedCols) )
                        error('Calculated columns or rows differ from input.');
                    end
                else
                    error('Expected 0, 1 or 3 arguments to MatrixData.');
                end
            end
        end
       
    end
    
    methods (Static)
        
        % Given a column vector containing timesteps, where some elements
        % of the vector are NaN, return the reduced vector containing the
        % timesteps and the number of timesteps. 
        function [frames, timesteps] = getTimesteps(column_vector)
            timesteps = [];
            for i=1:size(column_vector,1)
                if ~isnan(column_vector(i,1))
                    timesteps = [timesteps; column_vector(i,1)];
                end
            end
            frames = size(timesteps,1);
        end
        
        % Given an array of data corresponding to a sequence of matrices
        % (NO TIMESTEPS) of a given rowsize, return a cell array containing the
        % individual matrices. 
        function matrix_array = getMatrixArray(rows, data)
            matrix_array = cell(size(data,1)/rows,1);
            index = 1;
            for i=1:size(data,1)/rows
                matrix_array{i} = data(index:index+rows-1,1:end);
                index = index + rows;
            end
        end
        
    end
    
end

