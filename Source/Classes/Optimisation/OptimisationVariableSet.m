classdef OptimisationVariableSet
    % Set of optimisation variables corresponding to an optimisation
    % problem.
    
    properties
        names 
        sizes
    end
    
    methods
        
        function obj = OptimisationVariableSet(names, sizes)
            % names should be a column character vector of the names of each
            % variable. Sizes should be a column vector of the same size giving
            % the size of the corresponding variable. Alternatively,
            % initialise an empty VariableSet and add the variables in. 
            if nargin > 0
                obj.names = names;
                obj.sizes = sizes;
            end
        end
        
        function obj = addVariable(obj,variable)
            obj.names{end+1} = variable.name;
            obj.sizes = [obj.sizes variable.size];
        end
        
    end
    
end

