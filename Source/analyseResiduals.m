function analyseResiduals(rra)
% Produce a graphical analysis of residual performance given input
% actuation force data from an RRA.

    % Goodness parameters - from OpenSim website
    f_max = [10, 25];
    f_rms = [5, 10];
    m_max = [50, 75];
    m_rms = [30, 50];
    
    % Colour parameters
    good_patch = 0.8*[1 1 1];
    okay_patch = 0.6*[1 1 1];
    bad_patch = 0.4*[1 1 1];
    x_colour = '#0072BD';
    y_colour = '#7E2F8E';
    z_colour = '#D95319';
    rms_bar_colour = '#0072BD';
    
    % Style parameters
    line_width = 2;
    font_size = 15;

    % X Coordinates
    x_shade_max = [rra.Timesteps(1) rra.Timesteps(end) ...
        rra.Timesteps(end) rra.Timesteps(1)];
    x_shade_rms = [0 4 4 0];

    % Guidelines for F max
    max_window = [-1 -1 1 1];
    good_f_max = f_max(1)*max_window;
    okay_f_max = f_max(2)*max_window;
    bad_f_max = (2*f_max(2) - f_max(1))*max_window;

    % Guidelines for F RMS
    rms_window = [0 0 1 1];
    f_rms_diff = f_rms(2) - f_rms(1);
    good_f_rms = f_rms(1)*rms_window;
    okay_f_rms = f_rms_diff + good_f_rms;
    bad_f_rms = f_rms_diff + okay_f_rms;

    % Guidelines for M max
    good_m_max = m_max(1)*max_window;
    okay_m_max = m_max(2)*max_window;
    bad_m_max = (2*m_max(2) - m_max(1))*max_window;

    % Guidelines for M RMS
    m_rms_diff = m_rms(2) - m_rms(1);
    good_m_rms = m_rms(1)*rms_window;
    okay_m_rms = m_rms_diff + good_m_rms;
    bad_m_rms = m_rms_diff + okay_m_rms;

    % Get forces & moments
    fx = rra.getColumn('FX');
    fy = rra.getColumn('FY');
    fz = rra.getColumn('FZ');
    mx = rra.getColumn('MX');
    my = rra.getColumn('MY');
    mz = rra.getColumn('MZ');

    % Create plots figure
    figure;
    
    % Force max 
    subplot(2, 2, 1);
    createMaxPlot(fx, fy, fz, ...
        bad_f_max, okay_f_max, good_f_max, 'Force (N)', 'F');

    % Force RMS
    subplot(2, 2, 2);
    createRMSPlot(fx, fy, fz, ...
        bad_f_rms, okay_f_rms, good_f_rms, 'RMS Force', 'F');
        
    
    % Moments max
    subplot(2, 2, 3);
    createMaxPlot(mx, my, mz, ...
        bad_m_max, okay_m_max, good_m_max, 'Moment (Nm)', 'M');
    
    % Moments RMS
    subplot(2, 2, 4);
    createRMSPlot(mx, my, mz, ...
        bad_m_rms, okay_m_rms, good_m_rms, 'RMS Moment', 'M');
    
    % Title
    sgtitle('Residual Analysis', 'FontWeight', 'bold');
    
    function createMaxPlot(dx, dy, dz, bad, okay, good, ytitle, leg_pre)
        
        hold on;
        patch(x_shade_max, bad, bad_patch, 'LineStyle', 'none');
        patch(x_shade_max, okay, okay_patch, 'LineStyle', 'none');
        patch(x_shade_max, good, good_patch, 'LineStyle', 'none');
        plot(rra.Timesteps, dx, 'Color', x_colour, 'LineWidth', line_width);
        plot(rra.Timesteps, dy, 'Color', y_colour, 'LineWidth', line_width);
        plot(rra.Timesteps, dz, 'Color', z_colour, 'LineWidth', line_width);
        xlabel('Time (s)');
        ylabel(ytitle);
        xlim([rra.Timesteps(1), rra.Timesteps(end)]);
        ylim([bad(1), bad(end)]);
        legend('Bad', 'Okay', 'Good', ...
            [leg_pre 'X'], [leg_pre 'Y'], [leg_pre 'Z']);
        set(gca, 'FontSize', font_size);
        
    end
    
    function createRMSPlot(...
            dx, dy, dz, bad, okay, good, ytitle, leg_pre)
        
        hold on;
        patch(x_shade_rms, bad, bad_patch, 'LineStyle', 'none');
        patch(x_shade_rms, okay, okay_patch, 'LineStyle', 'none');
        patch(x_shade_max, good, good_patch, 'LineStyle', 'none');
        bar([rms(dx), rms(dy), rms(dz)], 'FaceColor', rms_bar_colour);
        xticks([1 2 3]);
        xticklabels({[leg_pre 'X'], [leg_pre 'Y'], [leg_pre 'Z']});
        ylabel(ytitle);
        xlim(x_shade_rms(1:2));
        ylim([0 bad(end)]);
        legend('Bad', 'Okay', 'Good');
        set(gca, 'FontSize', font_size);
        
    end


end