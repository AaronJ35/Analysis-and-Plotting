function [pg, qg, loss, va2, fload, va3, OS_V, OS_P, OS_Q] = plotBusAndGeneratorData(filename, fileIndex)
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
maxColumns = 0;

% First pass: Determine the maximum number of columns
for i = 1:length(dataLines)
    line = strtrim(dataLines{i});
    if isempty(line)
        continue;
    end
    % Split and count numeric entries
    lineParts = split(line, ',');
    numValues = sum(~isnan(str2double(lineParts)));
    maxColumns = max(maxColumns, numValues);
end

% Second pass: Extract numeric data and pad rows
for i = 1:length(dataLines)
    line = strtrim(dataLines{i});
    if isempty(line)
        continue;
    end
    
    % Split the line into individual components
    lineParts = split(line, ',');
    numbers = [];
    
    % Loop through each part and convert to numeric if possible
    for j = 1:length(lineParts)
        value = str2double(strtrim(lineParts{j}));
        if ~isnan(value) % Only include numeric values
            numbers = [numbers, value];
        end
    end
    
    % Pad the row to match the maximum number of columns
    if length(numbers) < maxColumns
        numbers = [numbers, NaN(1, maxColumns - length(numbers))];
    end
    
    % Append the numeric values as a row to busData
    busData = [busData; numbers];
end

    %% Extract the VM and VA columns (10th and 8th columns)
    if size(busData, 2) < 25
        error('The BUSES data does not have 25 columns.');
    end

    vm = busData(:, 10);
    va = busData(:, 7);
    va2=min(va);
    OS_V = busData(:,23);
    OS_P = abs(busData(:,24));
    OS_P = max(OS_P);
    OS_Q = busData(:,25);

    vm2=min(vm);
    vm3=max(vm);
    va3=max(va);
%% Separate the COST row from the rest of the CSV
startIdx = strfind(fileData, '0 / COST:');
endIdx = strfind(fileData, '0 / BUSES:');

if isempty(startIdx) || isempty(endIdx)
    error('Could not find the COST section or the boundary with BUSES.');
end

% Extract the COST row and the remaining data
costRow = fileData(startIdx:endIdx-1);

% Parse the COST row to extract necessary values
lines = splitlines(costRow);
costLine = lines{3}; % Assuming the second line has the relevant data
costValues = sscanf(costLine, '%f,');

% Extract the required data for fixedloadp, adjloadp, and acplosses
fload = costValues(4); % 5th column for fixedloadp
aload = costValues(5);   % 6th column for adjloadp
loss = costValues(6)*1000;  % 7th column for acplosses

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
function colormap = blackToBlue(N)
    % Create a black-to-blue colormap with N colors
    colormap = [linspace(0, 0, N)', ... % Red channel (all zeros)
                linspace(0, 0, N)', ... % Green channel (all zeros)
                linspace(0, 1, N)'];   % Blue channel (black to blue)
end
