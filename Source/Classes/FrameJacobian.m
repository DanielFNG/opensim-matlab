classdef FrameJacobian
    % An individual FrameJacobian.
    %   This is associated with a name, a body, a point on that body to
    %   which some force could be applied (for example). Finally, a MatrixData
    %   object which stores the Jacobian itself (including the timesteps).
    %   There is also an association to an OpenSimTrial which is required
    %   to be calculated up to RRA. 
    %
    %   Note that FrameJacobians are calculated in sets and so
    %   FrameJacobianSet is what actually does the calculation. This is
    %   just a holder class for the individual data segments. 
    
    properties (SetAccess = private)
        Name
        Body
        Point
        Jacobian
        Trial
    end
    
    methods
        
        function obj = FrameJacobian(OpenSimTrial, 
        
    end
    
end

