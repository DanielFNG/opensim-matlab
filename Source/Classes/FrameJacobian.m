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
        
        function obj = FrameJacobian(OpenSimTrial, name, body, point, path)
            % Name of the frame as per the settings file, body to which it
            % is attached, point on body. Path to text file holding the
            % Jacobian over some time trajectory. 
            if nargin > 0
                obj.Trial = OpenSimTrial;
                obj.Name = name;
                obj.Body = char(body);
                obj.Point = point;
                obj.Jacobian = MatrixData(path);
            end
        end
        
    end
    
end

