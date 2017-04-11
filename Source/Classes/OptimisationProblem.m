classdef OptimisationProblem
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    % Work in progress.
    % Variable builds in to VariableSet.
    % Constraint is a function of VariableSet, and builds in to
    % ConstraintSet.
    % Then you have OptimisationProblem class.
    
    % Think I'm biting off a bit too much atm and I'm going to have to have
    % a think on what this sort of thing is going to achieve - is it
    % actully necessary and will it provide any benefit at all?

    % For the time being I think I'll potentially just do the optimisation
    % as a common function rather than a class in its own right.
    
    % The overall problem will still be a class though. With a suite of
    % optimisation functions.
    
    % But eventually I do think it would be nice to have a class for this.
    
    properties
        ConstraintSet
        VariableSet
    end
    
    methods
    end
    
end

