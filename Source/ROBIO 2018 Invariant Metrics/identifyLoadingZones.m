function [l1, u1, l2, u2, lo] = identifyLoadingZones(torque)
% This function accepts a torque vector which is assumed to be bimodal with 
% peaks of opposite sign. It returns 4 sets of 
% indices corresponding to the first/second loading/unloading zones. 

n_indices = length(torque);
indices = (1:n_indices).';
halfway = round(n_indices/2);

% Find the global peaks and the interior crossing point.
[~, pk1] = max(abs(torque(1:halfway)));
[~, pk2] = max(abs(torque(halfway+1:end)));
pk2 = pk2 + halfway;
points = (sign(torque) == -sign(torque(pk1))) & (indices > pk1);
interior_crossing_point = find(points, 1, 'first') - 1;
points = (indices > pk1) & (indices < pk2) & ...
    (sign(torque) == -sign(torque(pk2)));
exterior_crossing_point = find(points, 1, 'last');
points = (indices > pk2) & (sign(torque) == sign(torque(pk2)));
final_crossing_point = find(points, 1, 'last');

% % Find the start of the second loading zone as the longest slice of one 
% % consistent gradient direction + remaining points until second peak. 
% new_points = torque(interior_crossing_point:pk2 - 1) - ...
%     torque(interior_crossing_point + 1:pk2);
% best = 0;
% current = 0;
% start_index = 1;
% best_index = 0;
% for i=1:length(new_points) - 1
%     if sign(new_points(i+1)) == sign(new_points(i))
%         current = current + 1;
%         if current > best
%             best = current; 
%             best_index = start_index;
%         end
%     else
%         current = 1;
%         start_index = i;
%     end
% end         

% Assign the correct indices.
l1 = 1:pk1;
u1 = pk1 + 1:interior_crossing_point;
l2 = exterior_crossing_point:pk2;
u2 = pk2 + 1:final_crossing_point;

if interior_crossing_point + 1 ~= exterior_crossing_point
    lo = interior_crossing_point + 1:exterior_crossing_point - 1;
end

end