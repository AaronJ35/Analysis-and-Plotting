function generatePVCases_neg(inputFile, pvValues, numGenerators, keepExistingLoads, pvBusNumbers)
    % Function to add PV units as negative loads in the system.
    % If pvBusNumbers is provided, PVs are placed at those bus numbers.
    % Otherwise, PVs are randomly placed at load buses.
    %
    % Parameters:
    %   inputFile (string): Full path to the input PSSE .raw file
    %   pvValues (vector): Required vector of PV generation values (in MW)
    %   numGenerators (integer): Number of PV units to place
    %   keepExistingLoads (optional): Boolean to keep original load values
    %   pvBusNumbers (optional): Vector of specific bus numbers for PV placement

    % Validate input file
    if ~isfile(inputFile)
        error('The specified input file does not exist: %s', inputFile);
    end

    % Validate pvValues
    if nargin < 2 || isempty(pvValues)
        error('pvValues is required and cannot be empty.');
    end

    % Validate numGenerators
    if nargin < 3
        numGenerators = 3; % Default to placing 3 PV units
    elseif numGenerators > length(pvValues)
        error('The number of generators cannot exceed the number of PV values provided.');
    end

    % Default value for keepExistingLoads
    if nargin < 4
        keepExistingLoads = 1; % Default is to keep existing loads
    end

    % Ensure pvValues is a row vector
    pvValues = pvValues(:)'; 

    % Get the base name of the input file without extension
    [inputDir, baseName, ~] = fileparts(inputFile);

    % Determine the output folder name based on the input file and the sum of PV values
    pvSum = sum(pvValues);
    outputDirName = sprintf('%s_PV_%.2f', baseName, pvSum);
    outputDir = fullfile(inputDir, outputDirName);

    % Create the "output" folder if it doesn't exist
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Power factor options
    powerFactors = [0.7, 0.8, 0.9];

    % Read the .raw file
    fileContent = fileread(inputFile);
    lines = splitlines(fileContent);

    % Find the load section markers
    loadSectionStart = find(contains(lines, 'LOAD'), 1);
    endLoadDataIndex = find(contains(lines, '0 / END OF LOAD DATA, BEGIN FIXED SHUNT DATA'), 1);
    if isempty(loadSectionStart) || isempty(endLoadDataIndex)
        error('Could not find the "LOAD" or "END OF LOAD DATA" markers in the file.');
    end

    % Extract all load lines
    loadLines = lines(loadSectionStart+1:endLoadDataIndex-1);

    % Find all load buses
    loadBuses = [];
    for i = 1:length(loadLines)
        if contains(loadLines{i}, '/')
            continue; % Skip comments
        end
        fields = strsplit(loadLines{i}, ',');
        if numel(fields) > 2
            loadBuses(end+1) = str2double(fields{1}); % Load bus ID
        end
    end

    % Validate or extend bus placement
    selectedBuses = pvBusNumbers;
    if exist('pvBusNumbers', 'var') && ~isempty(pvBusNumbers)
        missingBuses = setdiff(pvBusNumbers, loadBuses);
        if ~isempty(missingBuses) && keepExistingLoads
            fprintf('Adding missing buses: %s\n', strjoin(string(missingBuses), ', '));
            loadBuses = [loadBuses, missingBuses];
        elseif ~isempty(missingBuses)
            error('Some specified bus numbers are not valid load buses: %s', strjoin(string(missingBuses), ', '));
        end
    else
        % Original random selection logic
        selectedBuses = randsample(loadBuses, numGenerators);
    end

    % Generate files for one set of buses with multiple power factors
    for pf = powerFactors
        % Copy the original lines
        modifiedLines = lines;
        modifiedLoadLines = loadLines;
        additionalLoadLines = {};

        % Prepare updated load entries
        for k = 1:length(selectedBuses)
            bus = selectedBuses(k);
            pvLoad = -pvValues(k); % Negative active power to represent PV generation
            qg = -pvValues(k) * sqrt(1 - pf^2) / pf; % Reactive power based on power factor

            if keepExistingLoads
                % Add a new line for the PV unit instead of modifying existing loads
                newLine = sprintf('%d, 1, 1, 1, 1, %.6f, %.6f, 0, 0, 0, 0, 1, 0, 0', bus, pvLoad, qg);
                additionalLoadLines{end+1} = newLine; % Collect new lines to add later
            else
                % Modify the existing load line
                for i = 1:length(modifiedLoadLines)
                    if contains(modifiedLoadLines{i}, '/')
                        continue; % Skip comments
                    end
                    fields = strsplit(modifiedLoadLines{i}, ',');
                    if str2double(fields{1}) == bus
                        % Modify the active power (P) and reactive power (Q) fields
                        fields{6} = sprintf('%.6f', pvLoad); % PG in the 6th column
                        fields{7} = sprintf('%.6f', qg); % QG in the 7th column
                        modifiedLoadLines{i} = strjoin(fields, ',');
                        break;
                    end
                end
            end
        end

        % Append additional PV load lines if keeping existing loads
        if keepExistingLoads
            modifiedLoadLines = [modifiedLoadLines; additionalLoadLines'];
        end

        % Replace the load section with updated entries
        modifiedLines = [lines(1:loadSectionStart); modifiedLoadLines; lines(endLoadDataIndex:end)];

        % Generate the output file name with bus numbers and power factor
        busNumbersStr = strjoin(string(selectedBuses), '_');
        outputFile = fullfile(outputDir, sprintf('%s_with_PV_buses_%s_pf_%.1f.raw', baseName, busNumbersStr, pf));
        fileID = fopen(outputFile, 'w');
        fprintf(fileID, '%s\n', modifiedLines{:});
        fclose(fileID);

        fprintf('Generated file: %s\n', outputFile);
    end
end
