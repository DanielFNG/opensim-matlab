classdef GaitCycle < Motion
% Class for using OpenSim analysis data to perform calculations.

    properties (GetAccess = private, SetAccess = private)
        GRFRightFoot = 'ground_force1_' 
        GRFLeftFoot = 'ground_force2_'
        ToeMarker = '_MTP1_'
        HeelMarker = '_Heel_'
        AnkleMarker = '_Ankle_Lat_'
        Sideways = 'Z'
    end
        
    methods
        
        function result = calculateStepFrequency(obj)
            
            % Analysis requirements.
            obj.require('GRF');
            
            % Frequency calculation.
            result = 1/obj.getTotalTime();
            
        end
        
        function result = calculateStepWidth(obj, adjacent)
            
            % Analysis requirements.
            obj.require('IK');
            adjacent.require('IK');
            
            % Identify the leading foot.
            [side, other_side] = obj.identifyLeadingFootIK();
            
            % Construct labels.
            first = [side obj.HeelMarker obj.Sideways];
            second = [other_side obj.HeelMarker obj.Sideways];
            
            % Get data.
            first = obj.Trial.data.IK.InputMarkers.getColumn(first);
            second = adjacent.Trial.data.IK.InputMarkers.getColumn(second);
            
            % Compute step width.
            result = abs(second(1) - first(1));
        
        end
        
        function result = calculateCoMD(obj, direction, speed)
        % Calculate CoM displacement.
        
            if nargin == 1 || any(strcmp({'y', 'z'}, direction))
                result = Motion.calculateCoMD(obj, direction);
            else
                obj.require('BK');
                label = [obj.CoM direction];
                data = obj.accountForTreadmill(...
                    obj.Trial.data.BK.Positions.getColumn(label), speed);
                result = peak2peak(data);
            end
        end
        
        function result = calculateCoPD(obj, cutoff, direction)
        % Calculate CoP displacement at the leading foot. 
        
            % Analysis requirements.
            obj.require('GRF');
            
            % CoPD calculation.  
            directions = {'x', 'z'};
            foot = obj.identifyLeadingFootGRF();
            stance = obj.isolateStancePhase(foot, cutoff);
            for i=1:length(directions)
                label = directions{i};
                cp = ['_p' label];
                cop = obj.Trial.data.GRF.Forces.getColumn([foot cp]);
                result.(directions{i}) = peak2peak(cop(stance));
            end
            
            % Optionally, return only one direction.
            if nargin == 3
                result = result.(direction);
            end
        end
        
        function result = calculateMoS(...
                obj, stance_cutoff, speed, leg_length, direction)
            
            % Analysis requirements.
            obj.require({'GRF', 'IK', 'BK'});
            
            % Get the start and end time of stance.
            [foot, side] = obj.identifyLeadingFootGRF();
            timesteps = obj.Trial.data.GRF.Forces.getColumn('time');
            stance_indices = obj.isolateStancePhase(foot, stance_cutoff);
            start_time = timesteps(stance_indices(1));
            end_time = timesteps(stance_indices(end));
            
            % MoS calculations.
            if nargin < 5
                directions = {'x', 'z'};
            else
                directions = {direction};
            end
            
            for i=1:length(directions)
                
                pos = obj.Trial.data.BK.Positions.slice(start_time, end_time);
                vel = obj.Trial.data.BK.Velocities.slice(start_time, end_time);
                com_label = [obj.CoM directions{i}];
                com_pos = pos.getColumn(com_label);
                com_vel = vel.getColumn(com_label);
                
                switch directions{i}
                    case 'x'
                        marker = obj.HeelMarker;
                        test = obj.AnkleMarker;
                    case 'z'
                        marker = obj.AnkleMarker;
                end
                
                markers = ...
                    obj.Trial.data.IK.InputMarkers.slice(start_time, end_time);
                test_label = [side test directions{i}];
                bos_label = [side marker directions{i}];
                bos = markers.getColumn(bos_label)/1000;  % Convert to m
                test = markers.getColumn(test_label)/1000;
                
                switch directions{i}
                    case 'x'
                        com_pos = GaitCycle.accountForTreadmill(com_pos, speed);
                        com_vel = com_vel + speed;
                        bos = GaitCycle.accountForTreadmill(bos, speed);
                        test = GaitCycle.accountForTreadmill(test, speed);
                end
                
                xcom = com_pos + com_vel*sqrt(leg_length/obj.Gravity);
                mos = min(bos - xcom);
                result.(directions{i}) = max(0, mos); 
            end
        end
    end
    
    methods (Access = private)
        
        function [side, other_side] = identifyLeadingFootIK(obj)
            
            right = obj.Trial.data.IK.Kinematics.getColumn('hip_flexion_r');
            left = obj.Trial.data.IK.Kinematics.getColumn('hip_flexion_l');
            
            if right(1) > left(1)
                side = 'R';
                other_side = 'L';
            else
                side = 'L';
                other_side = 'R';
            end
        end
        
        function [foot, side] = identifyLeadingFootGRF(obj)
        
            % Isolate vertical force data for each foot.
            vert = 'vy';
            right = obj.Trial.data.GRF.Forces.getColumn([obj.GRFRightFoot vert]);
            left = obj.Trial.data.GRF.Forces.getColumn([obj.GRFLeftFoot vert]);
            
            % The index at which each peak occurs.
            right_zeros = find(right == 0);
            left_zeros = find(left == 0);
            
            % Check which peaks sooner. 
            if right_zeros(1) > left_zeros(1)
                foot = obj.GRFRightFoot;
                side = 'R';
            else
                foot = obj.GRFLeftFoot;
                side = 'L';
            end
        end
        
        function indices = isolateStancePhase(obj, foot, cutoff)
        % Get the indices corresponding to stance phase using GRF data.
        
            vert = 'vy';
            indices = ...
                find(obj.Trial.data.GRF.Forces.getColumn([foot vert]) > cutoff);
            if ~all(diff(indices) == 1)
                error('Multiple stance phases detected.');
            end
            
        end
        
    end
    
    methods (Static)
        
        function corrected_positions = accountForTreadmill(positions, speed)
            
            n_frames = length(positions);
            dx = speed/n_frames;
            travel = (0:n_frames - 1)*dx;
            corrected_positions = positions + travel';
            
        end
    
    end

end