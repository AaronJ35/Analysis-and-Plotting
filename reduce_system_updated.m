function mpc_reduced = reduce_system_updated(mpc, resistance_threshold, Pf_flag)
% REDUCE_MATPOWER_CASE_MP Reduces a MATPOWER case by iteratively removing low resistance lines
% and ensures a reference node (REF) and at least one generator node (PV) are present.
%   mpc_reduced = reduce_matpower_case_mp(mpc, resistance_threshold, Pf_flag)
%
%   Inputs:
%       mpc: MATPOWER case struct
%       resistance_threshold: Lines with resistance below this value will be removed
%       Pf_flag: Flag for power flow calculation (0: no power flow, 1: AC power flow, 2: DC power flow)
%
%   Output:
%       mpc_reduced: Reduced MATPOWER case struct

    % Define column indices for MATPOWER matrices
    BR_R = 3;   % Resistance (p.u.)
    F_BUS = 1;  % From bus number
    T_BUS = 2;  % To bus number
    REF_BUS = 3; % Slack/reference bus index
    GEN_BUS = 1; % Generator bus index in the generator matrix
    GEN_STATUS = 8; % Generator status (1 for online, 0 for offline)
    
    % Copy original case to reduced case variable
    mpc_reduced = mpc;
    
    % Initialize reduction loop
    branches_to_remove = true;  % Placeholder for the condition check

    while branches_to_remove
        % Find indices of branches to remove (resistance < threshold)
        remove_branches = find(mpc_reduced.branch(:, BR_R) < resistance_threshold);
        
        % If no branches meet the criteria, exit the loop
        if isempty(remove_branches)
            branches_to_remove = false;
            break;
        end
        
        % Create a list of buses connected by the branches to be removed
        buses_to_check = unique([mpc_reduced.branch(remove_branches, F_BUS); mpc_reduced.branch(remove_branches, T_BUS)]);
        
        % Initialize external buses (buses we want to keep)
        external_buses = setdiff(mpc_reduced.bus(:,1), buses_to_check);
        
        % Add generator buses to external buses
        external_buses = unique([external_buses; mpc_reduced.gen(:,GEN_BUS)]);
        
        % Sort external buses to match MATPOWER's expectation
        external_buses = sort(external_buses);
        
        % Use mpreduction to reduce the network
        [mpc_reduced, ~] = MPReduction(mpc_reduced, external_buses, Pf_flag);
        
        % Update case dimensions after reduction
        mpc_reduced.dim.nb = size(mpc_reduced.bus, 1);
        mpc_reduced.dim.nl = size(mpc_reduced.branch, 1);
        mpc_reduced.dim.ng = size(mpc_reduced.gen, 1);
        
        % Ensure there is at least one reference (slack) bus
        ref_buses = find(mpc_reduced.bus(:,2) == 3);  % Column 2 in MATPOWER bus matrix indicates REF buses
        if isempty(ref_buses)
            % Assign the first bus as the reference bus if none exists
            mpc_reduced.bus(1, 2) = 3;  % Set bus type as REF
        end
        
        % Ensure there is at least one PV bus (generator)
        pv_buses = find(mpc_reduced.bus(:,2) == 2);  % Column 2 in bus matrix indicates PV buses
        if isempty(pv_buses)
            % Assign the first available generator bus as PV if none exists
            gen_buses = find(mpc_reduced.gen(:,GEN_STATUS) == 1);  % Find online generators
            if ~isempty(gen_buses)
                mpc_reduced.bus(mpc_reduced.gen(gen_buses(1), GEN_BUS), 2) = 2;  % Set as PV bus
            end
        end
    end

end
