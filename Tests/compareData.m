for i=1:length(test_data.Labels)
    
    test_vec = test_data.getColumn(test_data.Labels{i});
    true_vec = true_data.getColumn(test_data.Labels{i});
    
    figure;
    plot(test_vec);
    hold on
    plot(true_vec);
    title(test_data.Labels{i});
    legend('test', 'true');
    
end