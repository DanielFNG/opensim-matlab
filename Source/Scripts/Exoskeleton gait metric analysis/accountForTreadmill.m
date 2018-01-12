function corrected_trajectory = accountForTreadmill(T, F, S)
% Given a positional trajectory T measured at frequency F on a treadmill
% whose belt is moving at speed S, calculate the travel due to the
% treadmill and return a corrected trajectory which accounts for the
% treadmill movement. Input units should be compatible. 

dx = S/F;
travel = (0:length(T)-1)*dx;
corrected_trajectory = T + travel;

end
