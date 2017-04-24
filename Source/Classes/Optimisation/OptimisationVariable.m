classdef OptimisationVariable
    % A variable in a VariableSet for an OptimisationProblem. A variable is
    % a vector of the given size, and has an identifying name.
    
    properties
        name
        size
    end
    
    methods
        
        function obj = OptimisationVariable(name, size)
            % Name should be a string associating this variable with a
            % name. Size should be an integer giving its size as a column
            % vector. 
            if nargin > 0
                obj.name = name;
                obj.size = size;
            end
        end
        
    end
    
end

