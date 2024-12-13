function generateGenParameters(mpc)
    % generateGenParameters - Creates parameter files for power system generators
    % based on MATPOWER case data
    %
    % Syntax:  generateGenParameters(mpc)
    %
    % Inputs:
    %    mpc - MATPOWER case structure containing generator data
    %
    % Outputs:
    %    Creates .mat files for each generator with parameters
    %
    % Example:
    %    mpc = loadcase('case9');
    %    generateGenParameters(mpc)

    % Input validation
    if ~isstruct(mpc) || ~isfield(mpc, 'gen')
        error('Invalid MATPOWER case data structure');
    end

    % Define constants
    genNumbers = 1:3;
    ParameterNames = {'J', 'D', 'Td0', 'xd', 'xdprime', 'RS', 'Pm', 'efd'};
    
    % Parameter templates based on generator size
    parameterTemplates = struct('small', {4.0, 1.5, 6.0, 0.7, 0.12, 0.002, [], 1.04}, ...
        'medium', {6.0, 2.0, 6.5, 0.8, 0.14, 0.002, [], 1.025},...
        'large', {8.0, 2.5, 7.4, 0.85, 0.15, 0.002, [], 1.025});

    for genNum = genNumbers
        try
            % Extract generator data
            baseVA = mpc.gen(genNum, 6);  % mBase value
            Pg = mpc.gen(genNum, 2);      % Real power output
            Vg = mpc.gen(genNum, 5);      % Voltage setpoint
            Pmax = mpc.gen(genNum, 8);    % Maximum real power
            
            % Determine generator size category and get template
            if Pmax <= 75
                template = parameterTemplates.small;
                template(7) = Pg/100;  % Normalize Pm
            elseif Pmax <= 100
                template = parameterTemplates.medium;
                template(7) = Pg/100;
            else
                template = parameterTemplates.large;
                template(7) = Pg/100;
            end
            
            % Create parameter structure
            newData = struct();
            for i = 1:length(ParameterNames)
                varName = [ParameterNames{i} '_G' num2str(genNum)];
                newData.(varName) = template(i);
            end
            
            % Save parameters with error handling
            filename = ['G' num2str(genNum) '_m.mat'];
            try
                save(filename, '-struct', 'newData');
                fprintf('Successfully generated parameters for generator %d\n', genNum);
            catch saveError
                warning('Failed to save parameters for generator %d: %s', genNum, saveError.message);
            end
            
        catch genError
            warning('Error processing generator %d: %s', genNum, genError.message);
            continue;
        end
    end
end