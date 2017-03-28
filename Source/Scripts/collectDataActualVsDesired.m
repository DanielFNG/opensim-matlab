BASE_OPTIMISATION_RESULTS_DIRECTORY = 'C:/Users/Daniel/Desktop/Automating Inverse Model/Results/p1_c1/opt';
BASE_OPENSIM_ID_RESULTS_DIRECTORY = 'C:/Users/Daniel/Desktop/Automating Inverse Model/Results/p1_c1/osim_opt';

OPTIMISATION_RESULTS_DIRECTORIES = cell(4,1);
OPENSIM_ID_RESULTS_DIRECTORIES = cell(4,1);
DISPLAY_NAMES = cell(13,1);

OPTIMISATION_RESULTS_DIRECTORIES{1,1} = [BASE_OPTIMISATION_RESULTS_DIRECTORY '/LLS'];
OPTIMISATION_RESULTS_DIRECTORIES{2,1} = [BASE_OPTIMISATION_RESULTS_DIRECTORY '/LLSE'];
OPTIMISATION_RESULTS_DIRECTORIES{3,1} = [BASE_OPTIMISATION_RESULTS_DIRECTORY '/LLSEE'];
OPTIMISATION_RESULTS_DIRECTORIES{4,1} = [BASE_OPTIMISATION_RESULTS_DIRECTORY '/HQP'];

OPENSIM_ID_RESULTS_DIRECTORIES{1,1} = [BASE_OPENSIM_ID_RESULTS_DIRECTORY '/LLS'];
OPENSIM_ID_RESULTS_DIRECTORIES{2,1} = [BASE_OPENSIM_ID_RESULTS_DIRECTORY '/LLSE'];
OPENSIM_ID_RESULTS_DIRECTORIES{3,1} = [BASE_OPENSIM_ID_RESULTS_DIRECTORY '/LLSEE'];
OPENSIM_ID_RESULTS_DIRECTORIES{4,1} = [BASE_OPENSIM_ID_RESULTS_DIRECTORY '/HQP'];

DISPLAY_NAMES{1,1} = 'lls';
DISPLAY_NAMES{2,1} = 'llse';
DISPLAY_NAMES{3,1} = 'llsee';
DISPLAY_NAMES{4,1} = 'hqp';
DISPLAY_NAMES{5,1} = 'actual';
DISPLAY_NAMES{6,1} = 'lls error';
DISPLAY_NAMES{7,1} = 'llse error';
DISPLAY_NAMES{8,1} = 'llsee error';
DISPLAY_NAMES{9,1} = 'hqp error';

nGraphs = size(OPTIMISATION_RESULTS_DIRECTORIES,1);

overall = figure;
error = figure;
% filtered_error = figure;

% area_under_curves = [];

x = 0.005 * (1:400);


figure(overall);
test = Data([OPENSIM_ID_RESULTS_DIRECTORIES{1,1} '/multiplier=0.5/id.sto']);
test = test.subsample(200);
plot(x, test.Values(1:400,8), 'DisplayName', DISPLAY_NAMES{5,1});
hold on;
plot(x, net_internal(2:401,7), 'DisplayName', 'input');
load([OPTIMISATION_RESULTS_DIRECTORIES{i,1} '/multiplier=0.5/optimisation_results.mat']);
plot(x, 0.5*net_internal(2:401,7), 'DisplayName', 'desired');

figure(error);
plot(x, test.Values(1:400,8) - 0.5*(net_internal(2:401,7)), 'DisplayName', 'actual - desired');

% for i=1:nGraphs
%     load([OPTIMISATION_RESULTS_DIRECTORIES{i,1} '/multiplier=0.5/optimisation_results.mat']);
%     figure(overall);
%     hold on;
%     if i == 1
%         graph = saved_results(2:401,9);
%     else
%         graph = saved_results(2:401,32);
%     end
%     plot(x, graph, 'DisplayName', DISPLAY_NAMES{i,1});
%     %plot(0.5*net_internal(1:400,7));
%     %plot(net_internal(1:400,7));
% %     test = Data([OPENSIM_ID_RESULTS_DIRECTORIES{i,1} '/multiplier=0.5/id.sto']);
% %     test = test.subsample(200);
% %     plot(test.Values(1:400,8), 'DisplayName', DISPLAY_NAMES{5,1});
%     figure(error);
%     hold on;
%     plot(x, graph - test.Values(1:400,8), 'DisplayName', DISPLAY_NAMES{i+5,1});
% %     figure(filtered_error);
% %     hold on;
% %     windowSize = 5;
% %     b = (1/windowSize)*ones(1,windowSize);
% %     a = 1;
% %     y = filter(b,a,graph - test.Values(1:400,8));
% %     plot(y, 'DisplayName', DISPLAY_NAMES{i+9,1});
% %     area_under_curves = [area_under_curves, trapz(graph)];
% end

figure(overall);
legend('show');
figure(error);
legend('show');
% figure(filtered_error);
% legend('show');