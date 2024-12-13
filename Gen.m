% Define generator numbers from the MATPOWER data
genNumbers = [1, 2, 3];
ParameterNames = {'J', 'D', 'Td0', 'xd', 'xdprime', 'RS', 'Pm', 'efd'};
%mpc = loadcase(filename);
mpc = loadcase('case9');

% Create mapping based on generator ratings and power outputs
for genNum = 1:3
    baseVA = mpc.gen(genNum, 6);  % mBase value from MATPOWER
    Pg = mpc.gen(genNum, 2);      % Real power output
    Vg = mpc.gen(genNum, 5);      % Voltage setpoint
    Pmax = mpc.gen(genNum, 8);    % Maximum real power
    
    % Customize parameters based on generator size and operating point
    switch genNum
        case 1  % Smallest generator (72.3 MW)
            defaultValues = {
                4.0,    % J - Smaller inertia for smaller unit
                1.5,    % D 
                6.0,    % Td0
                0.7,    % xd - Lower reactance for smaller unit
                0.12,   % xdprime
                0.002,  % RS
                0.723,  % Pm - Normalized to 1.0 base (72.3/100)
                1.04    % efd - Match MATPOWER voltage setpoint
            };
        case 2  % Largest generator (163 MW)
            defaultValues = {
                8.0,    % J - Larger inertia for larger unit
                2.5,    % D
                7.4,    % Td0
                0.85,   % xd - Higher reactance for larger unit
                0.15,   % xdprime
                0.002,  % RS
                1.63,   % Pm - Normalized (163/100)
                1.025   % efd - Match MATPOWER voltage setpoint
            };
        case 3  % Medium generator (85 MW)
            defaultValues = {
                6.0,    % J - Medium inertia
                2.0,    % D
                6.5,    % Td0
                0.8,    % xd
                0.14,   % xdprime
                0.002,  % RS
                0.85,   % Pm - Normalized (85/100)
                1.025   % efd - Match MATPOWER voltage setpoint
            };
    end
    
    % Create new struct with parameter fields
    newData = struct();
    for i = 1:length(ParameterNames)
        varName = [ParameterNames{i} '_G' num2str(genNum)];
        newData.(varName) = defaultValues{i};
    end
    
    % Save the new data
    save(['G' num2str(genNum) '.mat'], '-struct', 'newData');
end