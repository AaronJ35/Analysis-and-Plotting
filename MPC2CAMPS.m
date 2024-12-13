function MPC2CAMPS(filename)
% Converts matpower case files to CAMPS format with new output structure
addpath(genpath('\Users\aaron\Desktop\Research\matpower8.0'));
addpath(genpath('\Users\aaron\Desktop\Thesis Simulations\CAMPSv1.05'));

% Extract base name from filename (remove extension if present)
[~, baseName, ~] = fileparts(filename);

% Load the case
mpc = loadcase(filename);

Transmission = mpc.branch;
Load = mpc.bus;
Gen = mpc.gen;

% Create parameters directory if it doesn't exist
paramsDir = [baseName 'Params'];
if ~exist(paramsDir, 'dir')
    mkdir(paramsDir);
end

% Process Loads
load_buses = Load(Load(:,3) ~= 0 | Load(:,4) ~= 0, :);
L_ID = load_buses(:,1);
L_P = load_buses(:, 3);
L_Q = load_buses(:, 4);

% Process Lines
TL_bus1 = Transmission(:,1);
TL_bus2 = Transmission(:,2);
TL_R = Transmission(:,3);
TL_X = Transmission(:,4);

% Process Generators
G_ID = Gen(:,1);

% Save parameters for loads
%for j=1:length(L_ID)
 %   eval(['PL_L' num2str(L_ID(j,1)) '=L_P(j,1);']);
  %  eval(['QL_L' num2str(L_ID(j,1)) '=L_Q(j,1);']);
   % save([paramsDir '/L' num2str(L_ID(j,1)) '.mat'],['PL_L' num2str(L_ID(j,1))],['QL_L' num2str(L_ID(j,1))]);
%end
% Given values
V = 12.5;  % kV
f = 60;    % Hz
wb = 2*pi*f;  % Base frequency in rad/s

% Convert PQ to RL for each load
for j = 1:length(L_ID)
    % Get P and Q values for this load
    P = L_P(j);  % Real power
    Q = L_Q(j);  % Reactive power
    
    % Calculate R and L
    % For numerical stability, avoid division by zero
    if P ~= 0
        eval(['RL_L' num2str(L_ID(j,1)) '=(V^2)/P;']);
    else
        eval(['RL_L' num2str(L_ID(j,1)) '=1e6;']);  % Very large resistance if P=0
    end
    
    if Q ~= 0
        % Calculate L from Q: L = V^2/(Q*wb)
        eval(['LL_L' num2str(L_ID(j,1)) '=(V^2)/(Q*wb);']);
    else
        eval(['LL_L' num2str(L_ID(j,1)) '=0;']);  % No inductance if Q=0
    end
    
    % Save parameters
    save([paramsDir '/L' num2str(L_ID(j,1)) '.mat'],...
        ['RL_L' num2str(L_ID(j,1))],...
        ['LL_L' num2str(L_ID(j,1))]);
end
% Save parameters for transmission lines
for j=1:length(TL_bus1)
    eval(['RTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1)) '=TL_R(j,1);']);
    eval(['LTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1)) '=TL_X(j,1);']);
    eval(['CTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1)) '=1e-3;']);
    save([paramsDir '/TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1)) '.mat'],...
        ['RTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1))],...
        ['LTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1))], ...
        ['CTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1))]);
end

% Create output file
outputFile = [baseName '.m'];
fileID = fopen(outputFile, 'w');

% Write header
fprintf(fileID, '%%Specify the name of file to be used for analysis\n');
fprintf(fileID, 'FileName = ''%s'';\n\n', [baseName '.m']);
fprintf(fileID, '%%Specify the path to parameters folder which need to be used\n');
fprintf(fileID, 'ParametersPath = ''%s'';\n\n', [baseName 'Params/']);
fprintf(fileID, '%%Define base speed\n');
fprintf(fileID, 'wb = 377;\n\n');

% Write Generators section
fprintf(fileID, '%% Generators\n');
for i = 1:length(G_ID)
    fprintf(fileID, 'G%d = SMOneAxis({''_G%d''},phi,dphidt,wb);\n', G_ID(i), G_ID(i));
end
fprintf(fileID, '\n');

% Write Transmission Lines section
fprintf(fileID, '%% Transmission Lines\n');
for j = 1:length(TL_bus1)
    fprintf(fileID, 'TL_%d_%d = LongLine({''_TL_%d_%d''},phi,dphidt,wb);\n', ...
        TL_bus1(j), TL_bus2(j), TL_bus1(j), TL_bus2(j));
end
fprintf(fileID, '\n');

% Write Loads section
fprintf(fileID, '%% Loads\n');
for i = 1:length(L_ID)
    fprintf(fileID, 'L%d = RLLoad({''_L%d''},phi,dphidt,wb);\n', L_ID(i), L_ID(i));
end
fprintf(fileID, '\n');

% Write Modules section
fprintf(fileID, '%%% Create system\n%% Modules\n');
fprintf(fileID, 'Modules = {');

% Add generators to modules
for i = 1:length(G_ID)
    fprintf(fileID, 'G%d,', G_ID(i));
end
fprintf(fileID, '...\n');

% Add loads to modules
for i = 1:length(L_ID)
    fprintf(fileID, 'L%d,', L_ID(i));
end
fprintf(fileID, '...\n');

% Add transmission lines to modules
for j = 1:length(TL_bus1)
    if j == length(TL_bus1)
        fprintf(fileID, 'TL_%d_%d};\n\n', TL_bus1(j), TL_bus2(j));
    else
        fprintf(fileID, 'TL_%d_%d,', TL_bus1(j), TL_bus2(j));
    end
end

% Write Buses section
fprintf(fileID, '%%Buses\n');

% Create a map to store components connected to each bus
busConnections = containers.Map('KeyType', 'double', 'ValueType', 'any');

% Initialize bus connections
uniqueBuses = unique([TL_bus1; TL_bus2; L_ID; G_ID]);
for bus = uniqueBuses'
    busConnections(bus) = {};
end

% Add generators to buses
for i = 1:length(G_ID)
    bus = G_ID(i);
    busConnections(bus) = [busConnections(bus), sprintf('{G%d}', bus)];
end

% Add loads to buses
for i = 1:length(L_ID)
    bus = L_ID(i);
    busConnections(bus) = [busConnections(bus), sprintf('{L%d}', bus)];
end

% Add transmission lines to buses
for i = 1:length(TL_bus1)
    bus1 = TL_bus1(i);
    bus2 = TL_bus2(i);
    busConnections(bus1) = [busConnections(bus1), sprintf('{TL_%d_%d,''L''}', bus1, bus2)];
    busConnections(bus2) = [busConnections(bus2), sprintf('{TL_%d_%d,''R''}', bus1, bus2)];
end

% Write bus definitions
for bus = uniqueBuses'
    connections = busConnections(bus);
    fprintf(fileID, 'Bus%d = {%s};\n', bus, strjoin(connections, ','));
end

% Write final Buses array
fprintf(fileID, '\nBuses = {');
for i = 1:length(uniqueBuses)
    if i == length(uniqueBuses)
        fprintf(fileID, 'Bus%d};\n', uniqueBuses(i));
    else
        fprintf(fileID, 'Bus%d,', uniqueBuses(i));
    end
end

% Write G matrix generation
fprintf(fileID, '\nG = ProduceGMatrix(Modules,Buses);\n');

fclose(fileID);
end