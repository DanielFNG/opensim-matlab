function [MoS] = getMoS(Analysis, Velocities, GRF, Positions , foot, subject, leg, speed)
%get the MoS

g = 9.80665;

switch foot
    case 1
    heel_pos_ap = Positions.getDataCorrespondingToLabel('R_HeelX')/1000;
    ankle_pos_ml = Positions.getDataCorrespondingToLabel('R_Ankle_LatZ')/1000;

    case 2
    heel_pos_ap = Positions.getDataCorrespondingToLabel('L_HeelX')/1000;
    ankle_pos_ml = Positions.getDataCorrespondingToLabel('L_Ankle_LatZ')/1000;
end

% Find start of swing phase
grf_data = GRF.getDataCorrespondingToLabel(['    ground_force' num2str(foot) '_vy']);
grf_data = normaliseData(grf_data);
Swing_start = find(grf_data(6:end)<10);

if isempty(Swing_start)
    Swing_start = 60;
    
end

com_pos_x = Analysis.getDataCorrespondingToLabel('center_of_mass_X');
com_pos_z = Analysis.getDataCorrespondingToLabel('center_of_mass_Z');

com_vel_x = Velocities.getDataCorrespondingToLabel('center_of_mass_X');
com_vel_z = Velocities.getDataCorrespondingToLabel('center_of_mass_Z');

% Calculate belt travel and speed
xStart = 0;
dx_com = speed/1000;
dx_pos = speed/100;
N_com = length(com_pos_x);
N_pos = length(heel_pos_ap);
Belt_travel_com = (xStart + (0:N_com-1)*dx_com)';
Belt_travel_pos = (xStart + (0:N_pos-1)*dx_pos)';
Belt_vel = speed;

com_pos_x = com_pos_x + Belt_travel_com;
com_vel_x = com_vel_x + Belt_vel;
heel_pos_ap = heel_pos_ap + Belt_travel_pos;

% Normalise data
com_pos_x = normaliseData(com_pos_x);
com_pos_z = normaliseData(com_pos_z);
com_vel_x = normaliseData(com_vel_x);
com_vel_z = normaliseData(com_vel_z);
ankle_pos_ml = normaliseData(ankle_pos_ml);
heel_pos_ap = normaliseData(heel_pos_ap);

Xcom_ap = com_pos_x + (com_vel_x*(sqrt(leg(subject)/g)));
Xcom_ml = com_pos_z + (com_vel_z*(sqrt(leg(subject)/g)));

MoS_AP = min(Xcom_ap(1:Swing_start(1)) - heel_pos_ap(1:Swing_start(1)))*-1;

switch foot
    case 1
    MoS_ML = min(ankle_pos_ml(1:Swing_start(1)) - Xcom_ml(1:Swing_start(1)));
    
    case 2
    MoS_ML = max(ankle_pos_ml(1:Swing_start(1)) - Xcom_ml(1:Swing_start(1)))*-1; 
end

MoS = [MoS_AP MoS_ML];


        

