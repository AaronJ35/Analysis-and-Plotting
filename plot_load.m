function plot_load(fileName)
    % Load the data from the specified Excel file
    data = readtable(fileName);

    % Extract time and load values
    time = data.Time_index;  % Assuming the column is named 'Time_index'
    load_values = data{:, 2:end}; % Extract all columns except the first

    % Calculate the aggregated total for each row (time step)
    aggregated_total = sum(load_values, 2);

    % Plot the results
    figure;
    plot(time, aggregated_total, '-o', 'LineWidth', 1.5);
    grid on;

    % Enhance title and labels
    title('Aggregated Load Over Time', 'FontSize', 16);
    xlabel('Time Index', 'FontSize', 14);
    ylabel('Total Load (MW)', 'FontSize', 14);

    % Increase tick font size
    set(gca, 'FontSize', 12);

    % Generate a filename for the plot based on the input file name
    [~, name, ~] = fileparts(fileName);
    outputFileName = sprintf('%s.png', name);

    % Save the plot
    saveas(gcf, outputFileName);

    % Notify user of saved file
    fprintf('Plot saved as: %s\n', outputFileName);
end
