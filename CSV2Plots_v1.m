function CSV2Plots_v1(filename, singleFigure, folderName)
    % plotBusAndGeneratorData - Parses a CSV file and plots data.
    %
    % Syntax: plotBusAndGeneratorData(filename, singleFigure, folderName)
    %
    % Inputs:
    %   filename - The path to the CSV file containing the data.
    %   singleFigure - Boolean flag to indicate if all plots should be
    %                  combined into subplots on a single figure.
    %   folderName - Name of the folder to save the plots as JPEG images.
    %
    % Example:
    %   plotBusAndGeneratorData('/path/to/file.csv', true, 'MyPlots');

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

    pg = genData(:, 11);
    qg = genData(:, 12);
    busNumbers = genData(:, 4);

    %% Create the folder if it doesn't exist
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end

    %% Plot the data
    if singleFigure
        figure;

        % Subplot 1: Voltage Magnitudes (VM)
        subplot(2, 2, 1);
        plot(vm, 'ro-', 'MarkerSize', 4);
        grid on;
        title('Voltage Magnitudes (VM)');
        xlabel('Bus Index');
        ylabel('VM');

        % Subplot 2: Voltage Angles (VA)
        subplot(2, 2, 2);
        plot(va, 'bo-', 'MarkerSize', 4);
        grid on;
        title('Voltage Angles (VA)');
        xlabel('Bus Index');
        ylabel('VA');

        % Subplot 3: Generator Real Power (PG)
        subplot(2, 2, 3);
        bar(busNumbers, pg, 'k'); % Black bar plot with Bus Numbers on x-axis
        grid on;
        title('Generator Real Power (PG)');
        xlabel('Bus Number');
        ylabel('PG');

        % Subplot 4: Generator Reactive Power (QG)
        subplot(2, 2, 4);
        bar(busNumbers, qg, 'r'); % Red bar plot with Bus Numbers on x-axis
        grid on;
        title('Generator Reactive Power (QG)');
        xlabel('Bus Number');
        ylabel('QG');

        % Save the figure
        saveas(gcf, fullfile(folderName, 'AllPlots.jpg'));

    else
        % Plot VM values
        figure;
        plot(vm, 'ro-', 'MarkerSize', 4);
        grid on;
        title('Voltage Magnitudes (VM)');
        xlabel('Bus Index');
        ylabel('VM');
        saveas(gcf, fullfile(folderName, 'VoltageMagnitudes.jpg'));

        % Plot VA values
        figure;
        plot(va, 'bo-', 'MarkerSize', 4);
        grid on;
        title('Voltage Angles (VA)');
        xlabel('Bus Index');
        ylabel('VA');
        saveas(gcf, fullfile(folderName, 'VoltageAngles.jpg'));

        % Plot PG values
        figure;
        bar(busNumbers, pg, 'k'); % Black bar plot with Bus Numbers on x-axis
        grid on;
        title('Generator Real Power (PG)');
        xlabel('Bus Number');
        ylabel('PG');
        saveas(gcf, fullfile(folderName, 'GeneratorRealPower.jpg'));

        % Plot QG values
        figure;
        bar(busNumbers, qg, 'r'); % Red bar plot with Bus Numbers on x-axis
        grid on;
        title('Generator Reactive Power (QG)');
        xlabel('Bus Number');
        ylabel('QG');
        saveas(gcf, fullfile(folderName, 'GeneratorReactivePower.jpg'));
    end
end
