function CSV2Plots_v1(baseFilePath, singleFigure, numFiles, folderName)
    % CSV2Plots_v1 - Loops through multiple CSV files and generates plots.
    %
    % Syntax: CSV2Plots_v1(baseFilePath, singleFigure, numFiles, folderName)
    %
    % Inputs:
    %   baseFilePath - The base path of the CSV files (e.g., '/path/to/BZ_fix-opf').
    %   singleFigure - Boolean flag to indicate if all plots should be
    %                  combined into subplots on a single figure.
    %   numFiles - Number of files to process (e.g., 23).
    %   folderName - Name of the folder to save the plots for all files.
    %
    % Example:
    %   CSV2Plots_v1('/output/UT_equal/BZ_fix-opf', true, 23, 'UT_equal plots');

    %% Initialize aggregated arrays for PG and QG
    allPg = [];
    allQg = [];
    allvm2 = [];
    allva2 = [];
    %% Create the main folder if it doesn't exist
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end

    %% Loop through all files
    for i = 1:numFiles
        % Construct the filename
        currentFile = sprintf('%s%d.csv', baseFilePath, i);

        % Call the plot function for each file
        try
            [pg, qg, vm2, va2] = plotBusAndGeneratorData(currentFile, singleFigure, folderName, i);
            % Aggregate the data
            if isempty(allPg)
                allPg = pg;
                allQg = qg;
                allvm2=vm2;
                allva2=va2;
            else
                allPg = [allPg, pg];
                allQg = [allQg, qg];
                allvm2=[allvm2, vm2];
                allva2=[allva2, va2];
            end
            fprintf('Processed and saved plots for %s\n', currentFile);
        catch ME
            fprintf('Failed to process %s: %s\n', currentFile, ME.message);
        end
    end

    %% Plot PG data
    figure;
    hold on;
    colors = lines(size(allPg, 1)); % Generate distinct colors for each generator
    for genIdx = 1:size(allPg, 1)
        plot(1:numFiles, allPg(genIdx, :), '-o', 'Color', colors(genIdx, :), 'DisplayName', sprintf('PG Generator %d', genIdx));
    end
    grid on;
    title('Generator Real Power (PG)');
    xlabel('Timestep Index');
    ylabel('Power (MW)');
    legend('show');
    hold off;

    %% Save PG plot
    saveas(gcf, fullfile(folderName, 'Aggregated_PG_Plot.jpg'));

    %% Plot QG data
    figure;
    hold on;
    for genIdx = 1:size(allQg, 1)
        plot(1:numFiles, allQg(genIdx, :), '-o', 'Color', colors(genIdx, :), 'DisplayName', sprintf('QG Generator %d', genIdx));
    end
    grid on;
    title('Generator Reactive Power (QG)');
    xlabel('Timestep Index');
    ylabel('Power (MVar)');
    legend('show');
    hold off;

    %% Save QG plot
    saveas(gcf, fullfile(folderName, 'Aggregated_QG_Plot.jpg'));
      %% Plot VM data
    figure;
    hold on;
    for busIdx = 1:size(allvm2, 1)
        plot(1:numFiles, allvm2(busIdx, :), '-o', 'Color', colors(busIdx, :), 'DisplayName', sprintf('VM Bus %d', busIdx));
    end
    grid on;
    title('Bus Voltage Magnitude Drop (VM)');
    xlabel('Timestep Index');
    ylabel('Voltage Magnitude Drop (pu)');
    legend('show');
    hold off;

    %% Save VM plot
    saveas(gcf, fullfile(folderName, 'Aggregated_VM_Plot.jpg'));

    %% Plot VA data
    figure;
    hold on;
    for busIdx = 1:size(allva2, 1)
        plot(1:numFiles, allva2(busIdx, :), '-o', 'Color', colors(busIdx, :), 'DisplayName', sprintf('VA Bus %d', busIdx));
    end
    grid on;
    title('Bus Voltage Angle (VA)');
    xlabel('Timestep Index');
    ylabel('Voltage Angle Deviation (degrees)');
    legend('show');
    hold off;

    %% Save VA plot
    saveas(gcf, fullfile(folderName, 'Aggregated_VA_Plot.jpg'));
end

function [pg, qg, vm2, va2] = plotBusAndGeneratorData(filename, singleFigure, folderName, fileIndex)
    %% Load the file
    fileData = fileread(filename);

    %% Extract the "BUSES" section
    startIdx = strfind(fileData, '0 / BUSES:');
    endIdx = strfind(fileData, '0 / FIXED');

    if isempty(startIdx) || isempty(endIdx)
        error('Could not find the BUSES section in the file.');
    end

    busesSection = fileData(startIdx:endIdx-1);

    %% Parse the BUSES data
    lines = splitlines(busesSection);
    dataLines = lines(2:end); % Skip the header lines

    % Convert the numeric data to a matrix
    busData = [];
    for i = 1:length(dataLines)
        line = strtrim(dataLines{i});
        if isempty(line)
            continue;
        end
        numbers = sscanf(line, '%f,');
        busData = [busData; numbers']; % Append the row
    end

    %% Extract the VM and VA columns (10th and 8th columns)
    if size(busData, 2) < 10
        error('The BUSES data does not have 10 columns.');
    end

    vm = busData(:, 10);
    va = busData(:, 7);
    vm2=range(vm);
    va2=range(va);

    %% Extract the "GENERATORS" section
    startIdx = strfind(fileData, '0 / GENERATORS:');
    endIdx = strfind(fileData, '0 / AC LINES:');

    if isempty(startIdx) || isempty(endIdx)
        error('Could not find the GENERATORS section in the file.');
    end

    generatorsSection = fileData(startIdx:endIdx-1);

    %% Parse the GENERATORS data
    lines = splitlines(generatorsSection);
    dataLines = lines(2:end); % Skip the header lines

    % Convert the numeric data to a matrix
    genData = [];
    for i = 1:length(dataLines)
        line = strtrim(dataLines{i});
        if isempty(line)
            continue;
        end
        numbers = sscanf(line, '%f,');
        genData = [genData; numbers']; % Append the row
    end

    %% Extract the PG, QG, and Bus Number columns (11th, 12th, and 4th columns)
    if size(genData, 2) < 12
        error('The GENERATORS data does not have 12 columns.');
    end

    qg = genData(:, 11) * 100;
    pg = genData(:, 12) * 100;
    busNumbers = genData(:, 4);

    %% Plot the data
    if singleFigure
        f = figure('Visible', 'off');

        % Subplot 1: Voltage Magnitudes (VM)
        subplot(2, 2, 1);
        plot(vm, 'k-', 'MarkerSize', 2);
        grid on;
        title('Voltage Magnitudes (VM)', 'FontSize', 10);
        xlabel('Bus Index', 'FontSize', 9);
        ylabel('VM (pu at 12.5 base)', 'FontSize', 9);

        % Subplot 2: Voltage Angles (VA)
        subplot(2, 2, 2);
        plot(va, 'r-', 'MarkerSize', 2);
        grid on;
        title('Voltage Angles (VA)', 'FontSize', 10);
        xlabel('Bus Index', 'FontSize', 9);
        ylabel('VA (degrees)', 'FontSize', 9);

        % Subplot 3: Generator Real Power (PG)
        subplot(2, 2, 3);
        bar(busNumbers, pg, 'k'); % Black bar plot with Bus Numbers on x-axis
        grid on;
        title('Generator Real Power (PG)', 'FontSize', 10);
        xlabel('Bus Number', 'FontSize', 9);
        ylabel('PG (MW)', 'FontSize', 9);

        % Subplot 4: Generator Reactive Power (QG)
        subplot(2, 2, 4);
        bar(busNumbers, qg, 'r'); % Red bar plot with Bus Numbers on x-axis
        grid on;
        title('Generator Reactive Power (QG)', 'FontSize', 10);
        xlabel('Bus Number', 'FontSize', 9);
        ylabel('QG (Mvar)', 'FontSize', 9);

        % Save the figure
        saveas(f, fullfile(folderName, sprintf('AllPlots_File_%d.jpg', fileIndex)));
        close(f);

    else
        % Plot VM values
        f1 = figure('Visible', 'off');
        plot(vm, 'ro-', 'MarkerSize', 2);
        grid on;
        title('Voltage Magnitudes (VM)', 'FontSize', 10);
        xlabel('Bus Index', 'FontSize', 9);
        ylabel('VM (pu at 12.5 base)', 'FontSize', 9);
        saveas(f1, fullfile(folderName, sprintf('VoltageMagnitudes_File_%d.jpg', fileIndex)));
        close(f1);

        % Plot VA values
        f2 = figure('Visible', 'off');
        plot(va, 'bo-', 'MarkerSize', 2);
        grid on;
        title('Voltage Angles (VA)', 'FontSize', 10);
        xlabel('Bus Index', 'FontSize', 9);
        ylabel('VA (degrees)', 'FontSize', 9);
        saveas(f2, fullfile(folderName, sprintf('VoltageAngles_File_%d.jpg', fileIndex)));
        close(f2);

        % Plot PG values
        f3 = figure('Visible', 'off');
        bar(busNumbers, pg, 'k'); % Black bar plot with Bus Numbers on x-axis
        grid on;
        title('Generator Real Power (PG)', 'FontSize', 10);
        xlabel('Bus Number', 'FontSize', 9);
        ylabel('PG (MW)', 'FontSize', 9);
        saveas(f3, fullfile(folderName, sprintf('GeneratorRealPower_File_%d.jpg', fileIndex)));
        close(f3);

        % Plot QG values
        f4 = figure('Visible', 'off');
        bar(busNumbers, qg, 'r'); % Red bar plot with Bus Numbers on x-axis
        grid on;
        title('Generator Reactive Power (QG)', 'FontSize', 10);
        xlabel('Bus Number', 'FontSize', 9);
        ylabel('QG (Mvar)', 'FontSize', 9);
        saveas(f4, fullfile(folderName, sprintf('GeneratorReactivePower_File_%d.jpg', fileIndex)));
        close(f4);
    end
end