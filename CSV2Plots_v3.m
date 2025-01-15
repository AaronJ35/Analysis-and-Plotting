function CSV2Plots_v3(baseFilePath, numFiles, folderName)
    % CSV2Plots_v1 - Loops through multiple CSV files and generates plots.
    %
    % Syntax: CSV2Plots_v1(baseFilePath, singleFigure, numFiles, folderName)
    %
    % Inputs:
    %   baseFilePath - The base path of the CSV files (e.g., '/path/to/BZ_fix-opf').
    %   numFiles - Number of files to process (e.g., 23).
    %   folderName - Name of the folder to save the plots for all files.
    %
    % Example:
    %   CSV2Plots_v1('/output/UT_equal/BZ_fix-opf', 23, 'UT_equal plots');

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
            [pg, qg, vm2, va2, vm3, va3] = plotBusAndGeneratorData(currentFile, i);
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
        catch ME
            fprintf('Failed to process %s: %s\n', currentFile, ME.message);
        end
    end

    %% Plot PG data
    subplot(2, 1, 1);
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

    %% Plot QG data
    subplot(2, 1, 2);
    hold on;
    for genIdx = 1:size(allQg, 1)
        plot(1:numFiles, allQg(genIdx, :), '-o', 'Color', colors(genIdx, :), 'DisplayName', sprintf('QG Generator %d', genIdx));
    end
    grid on;
    title('Generator Reactive Power (QG)');
    xlabel('Timestep Index');
    ylabel('Power (MVar)');
    hold off;
%% Save the combined plot
saveas(gcf, fullfile(folderName, 'PG_QG_.jpg'));
      %% Plot VM data
    figure;
    subplot(2, 1, 1);
    hold on;
    for busIdx = 1:size(allvm2, 1)
        plot(1:numFiles, allvm2(busIdx, :), '-o', 'Color', 'r', 'DisplayName', sprintf('VM Bus %d', busIdx));
                plot(1:numFiles, vm3(busIdx, :), '-o', 'Color', 'g', 'DisplayName', sprintf('VM Bus %d', busIdx));
    end
    grid on;
    title('Bus Voltage Magnitude(VM)');
    xlabel('Timestep Index');
    ylabel('Voltage Magnitude Ragne(pu)');
    legend({'Min', 'Max'});
    hold off;

    %% Plot VA data
    subplot(2, 1, 2);
    hold on;
    for busIdx = 1:size(allva2, 1)
        plot(1:numFiles, allva2(busIdx, :), '-o', 'Color', 'g', 'DisplayName', sprintf('VA Bus %d', busIdx));
           plot(1:numFiles, va3(busIdx, :), '-o', 'Color', 'r', 'DisplayName', sprintf('VM Bus %d', busIdx));
    end
    grid on;
    title('Bus Voltage Angle (VA)');
    xlabel('Timestep Index');
    ylabel('Voltage Angle Deviation (degrees)');
    hold off;

    %% Save VA plot
    saveas(gcf, fullfile(folderName, 'VM_VA_.jpg'));
    close all
end

function [pg, qg, vm2, va2, vm3, va3] = plotBusAndGeneratorData(filename, fileIndex)
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
    vm2=min(vm);
    va2=min(va);
    vm3=max(vm);
    va3=max(va);

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

   
end