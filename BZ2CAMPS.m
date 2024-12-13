% Converts matpower case files to CAMPS format
function BZ2CAMPS(filename)
%Find a way to make the reduction optional. Feasibility tests?
addpath(genpath('\Users\aaron\Desktop\Research\matpower8.0'));
addpath(genpath('\Users\aaron\Desktop\Thesis Simulations\CAMPSv1.05'));
BZ = loadcase(filename);

Transmission=BZ.branch;
Load=BZ.bus; %Real loads have values in columns 3 or 4

% Loads
% Extract rows where either P_load or Q_load is non-zero
load_buses = Load(Load(:,3) ~= 0 | Load(:,4) ~= 0, :);

% Extract loads
L_ID = load_buses(:,1);
L_P = load_buses(:, 3);
L_Q = load_buses(:, 4);
V=12.5; f=60;

%Convert to camps params format
for j=1:length(L_ID)
    eval(['PL_L' num2str(j) '=L_P(j,1);']);
    eval(['QL_L' num2str(j) '=L_Q(j,1);']);
end
%Save Individual parameter files
for j=1:length(L_ID)
    save(['BronzevilleParams/L' num2str(L_ID(j,1)) '.mat'],['PL_L' num2str(j)],['QL_L' num2str(j)]);
end

% Lines
TL_bus1 = Transmission(:,1);
TL_bus2 = Transmission(:,2);
TL_R = Transmission(:,3); 
TL_X = Transmission(:,4);

% Convert to camps params format
for j=1:length(Transmission)
    eval(['RTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1)) '=TL_R(j,1);']);
    eval(['LTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1)) '=TL_X(j,1);']);
end

%Save Individual parameter files
for j=1:length(Transmission)
    save(['BronzevilleParams/TL' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1)) '.mat'],...
        ['RTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1))],...
        ['LTL_TL_' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1))]);
end

%% Create CAMPS system in text file
% Open the file for writing
fileID = fopen('BZ.txt', 'w');
for j = 1:length(Transmission)
    x = ['TL' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1))];
    formatSpec = '%s = LongLine({''%s''},phi,dphidt,wb);\n';
    fprintf(fileID, formatSpec, x, x);
end
for i = 1:length(L_ID)
    y = ['L' num2str(L_ID(i,1))];
    formatSpec = '%s = PQLoad({''%s''},phi,dphidt,wb);\n';
    fprintf(fileID, formatSpec, y, y);
end
%% Generate modules section
FID=fopen('BZ.txt', 'a+');
for j = 1:length(Transmission)
    x = ['TL' num2str(TL_bus1(j,1)) '_' num2str(TL_bus2(j,1))];
    formatSpec = '%s,';
    fprintf(FID, formatSpec, x);
end
fprintf(FID, '\n');
for i = 1:length(L_ID)
    y = ['L' num2str(L_ID(i,1))];
    formatSpec = '%s,';
    fprintf(FID, formatSpec, y);
end

fprintf(FID, '\n');
%% Generate Bus section
txt2bus('BZ.txt');
fclose('all');
end