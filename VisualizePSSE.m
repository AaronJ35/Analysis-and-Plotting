function VisualizePSSE(rawFile)
    % Visualize network topology from a PSSE .raw file (version 33).

    % Validate input file
    if ~isfile(rawFile)
        error('The specified file does not exist: %s', rawFile);
    end

    % Read the .raw file content
    fileContent = fileread(rawFile);
    lines = splitlines(fileContent);

    % Initialize containers for buses and branches
    busData = [];
    branchData = [];

    % Parse the file line by line
    busSection = false;
    branchSection = false;

    for i = 1:length(lines)
        line = strtrim(lines{i});

        % Skip comments and empty lines
        if isempty(line) || startsWith(line, '/')
            continue;
        end

        % Detect section starts
        if contains(line, 'BEGIN BUS DATA')
            busSection = true;
            continue;
        elseif contains(line, 'END OF BUS DATA, BEGIN LOAD DATA')
            busSection = false;
        elseif contains(line, 'BEGIN BRANCH DATA')
            branchSection = true;
            continue;
        elseif contains(line, 'END OF BRANCH DATA, BEGIN TRANSFORMER DATA')
            branchSection = false;
        end

        % Extract bus data
        if busSection
            fields = split(line, ',');
            if length(fields) >= 2
                busID = str2double(strtrim(fields{1}));
                busData(end+1) = busID; %#ok<AGROW> % Store bus IDs
            end
        end

        % Extract branch data
        if branchSection
            fields = split(line, ',');
            if length(fields) >= 2
                fromBus = str2double(strtrim(fields{1}));
                toBus = str2double(strtrim(fields{2}));
                branchData(end+1, :) = [fromBus, toBus]; %#ok<AGROW>
            end
        end
    end

    % Check if branchData is populated
    if isempty(branchData)
        error('Branch data could not be extracted from the file.');
    end

    % Create the graph only after `branchData` is populated
    G = graph(branchData(:, 1), branchData(:, 2));

    % Plot the graph
    figure;
    plot(G, 'NodeLabel', busData, 'Layout', 'force');
    title('Network Topology');
    grid on;

    fprintf('Network topology visualized for file: %s\n', rawFile);
end
