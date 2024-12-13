function generatePVCases_fixed(inputFile, pvValues, numGenerators, keepExistingGenerators, pvBusNumbers)
    % Function to place PV generators in the system.
    % If pvBusNumbers is provided, PVs are placed at those bus numbers.
    % Otherwise, PVs are randomly placed at load buses.
    %
    % Parameters:
    %   inputFile (string): Full path to the input PSSE .raw file
    %   pvValues (vector): Required vector of PV generation values (in MW)
    %   numGenerators (integer): Number of PV generators to place
    %   keepExistingGenerators (optional): Boolean to keep original generators
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
        numGenerators = 3; % Default to placing 3 generators
    elseif numGenerators > length(pvValues)
        error('The number of generators cannot exceed the number of PV values provided.');
    end

    % Default value for keepExistingGenerators
    if nargin < 4
        keepExistingGenerators = 1; % Default is to keep existing generators
    end

    % Ensure pvValues is a row vector
    pvValues = pvValues(:)'; 

    % Get the base name of the input file without extension
    [inputDir, baseName, ~] = fileparts(inputFile);

    % Create the "output" folder if it doesn't exist
    outputDir = fullfile(inputDir, 'output');
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Read the .raw file
    fileContent = fileread(inputFile);
    lines = splitlines(fileContent);

    % Find section markers
    genSectionStart = find(contains(lines, 'GENERATOR'), 1);
    endGenDataIndex = find(contains(lines, '0 / END OF GENERATOR DATA, BEGIN BRANCH DATA'), 1);
    if isempty(genSectionStart) || isempty(endGenDataIndex)
        error('Could not find the "GENERATOR" or "END OF GENERATOR DATA" markers in the file.');
    end

    % Preserve the "END OF GENERATOR DATA" marker
    endGenMarker = lines(endGenDataIndex);

    % Remove existing generators if keepExistingGenerators is 0
    if ~keepExistingGenerators
        lines = [lines(1:genSectionStart); endGenMarker; lines(endGenDataIndex+1:end)];
        fprintf('Removed all existing generators from the file.\n');
    else
        % Extract all existing generator lines
        generatorLines = lines(genSectionStart+1:endGenDataIndex-1);
    end

    % Find the load section to extract load buses
    loadSectionStart = find(contains(lines, 'LOAD'), 1);

    % Extract load buses
    loadBuses = [];
    for i = loadSectionStart+1:genSectionStart-1
        if contains(lines{i}, '/')
            continue; % Skip comments
        end
        fields = strsplit(lines{i}, ',');
        if numel(fields) > 2
            loadBuses(end+1) = str2double(fields{1}); % Load bus ID
        end
    end

    % Decide on bus placement
    if exist('pvBusNumbers', 'var') && ~isempty(pvBusNumbers)
        % Validate that all specified buses are load buses
        if ~all(ismember(pvBusNumbers, loadBuses))
            error('Some specified bus numbers are not valid load buses.');
        end
        selectedBuses = pvBusNumbers;
    else
        % Original random selection logic
        selectedBuses = randsample(loadBuses, numGenerators);
    end

    % Prepare new PV generator entries
    pvEntries = {};
    for k = 1:length(selectedBuses)
        bus = selectedBuses(k);
        pvGen = pvValues(k);

        % Calculate Qmax and Qmin based on 0.8 power factor
        tanPhi = tan(acos(0.8)); % Approximately 0.75
        Qmax = pvGen * tanPhi;
        Qmin = -Qmax;

        % Create PV generator entry for the current bus and PV value
        pvEntries{end+1} = sprintf('%d, ''PV'', %.2f, 0.0, %.2f, %.2f, 1.02, 0, 100.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1, 100.0, %.2f, 0.0, 0, 0.0, 0, 0.0, 0, 0.0, 0, 0.0', ...
            bus, pvGen, Qmax, Qmin, pvGen);
    end

    % Insert PV generator entries just before "END OF GENERATOR DATA"
    if keepExistingGenerators
        lines = [lines(1:endGenDataIndex-1); pvEntries'; endGenMarker; lines(endGenDataIndex+1:end)];
    else
        lines = [lines(1:genSectionStart); pvEntries'; endGenMarker; lines(endGenDataIndex+1:end)];
    end

    % Generate the output file name
    outputFile = fullfile(outputDir, sprintf('%s_with_PV.raw', baseName));
    fileID = fopen(outputFile, 'w');
    fprintf(fileID, '%s\n', lines{:});
    fclose(fileID);

    fprintf('Generated file: %s\n', outputFile);
end
