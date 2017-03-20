BASE_OPTIMISATION_RESULTS_DIRECTORY = 'C:/Users/Daniel/Desktop/Automating Inverse Model/Results/p1_c1/opt';

OPTIMISATION_RESULTS_DIRECTORIES = cell(4,1);
OPENSIM_ID_RESULTS_DIRECTORIES = cell(4,1);
DISPLAY_NAMES = cell(4,1);

OPTIMISATION_RESULTS_DIRECTORIES{1,1} = [BASE_OPTIMISATION_RESULTS_DIRECTORY '/LLS'];
OPTIMISATION_RESULTS_DIRECTORIES{2,1} = [BASE_OPTIMISATION_RESULTS_DIRECTORY '/LLSE'];
OPTIMISATION_RESULTS_DIRECTORIES{3,1} = [BASE_OPTIMISATION_RESULTS_DIRECTORY '/LLSEE'];
OPTIMISATION_RESULTS_DIRECTORIES{4,1} = [BASE_OPTIMISATION_RESULTS_DIRECTORY '/HQP'];

DISPLAY_NAMES{1,1} = 'lls';
DISPLAY_NAMES{2,1} = 'llse';
DISPLAY_NAMES{3,1} = 'llsee';
DISPLAY_NAMES{4,1} = 'hqp';

nGraphs = size(OPTIMISATION_RESULTS_DIRECTORIES,1);

apo_torques = figure;

x = 0.005 * (1:400);

for i=1:nGraphs
    load([OPTIMISATION_RESULTS_DIRECTORIES{i,1} '/multiplier=0.5/optimisation_results.mat']);
    figure(apo_torques);
    hold on;
    plot(x, saved_results(2:401,1), 'DisplayName', [DISPLAY_NAMES{i,1} ' right']);
    plot(x, saved_results(2:401,2), 'DisplayName', [DISPLAY_NAMES{i,1} ' left']);
end

figure(apo_torques);
legend('show');