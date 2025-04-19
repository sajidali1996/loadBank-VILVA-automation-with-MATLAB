classdef LoadBankController_4app
    properties
        PortNumber % Port number for communication
        LoadBank   % Modbus object for communication
    end
    
    methods
        % Constructor
        function obj = LoadBankController_4app(portNumber)
            % LoadBankController Constructor
            % Syntax:
            %   obj = LoadBankController(portNumber)
            % 
            % Description:
            %   Initializes the LoadBankController object and establishes 
            %   communication using the specified port number.
            % 
            % Input:
            %   portNumber - String specifying the COM port (e.g., 'COM4').
            %
            % Output:
            %   obj - Instance of the LoadBankController class.
            % Initialize the modbus communication
            fprintf('Initializing communication on port: %s\n', portNumber);
            obj.PortNumber = portNumber;
            try
                obj.LoadBank = modbus('serialrtu', portNumber); % Create modbus object
                obj.LoadBank.Timeout = 3; % Set timeout
                fprintf('Communication established successfully.\n');
            catch ME
                fprintf('Error initializing communication: %s\n', ME.message);
                error('Failed to establish communication on port: %s', portNumber);
            end

        end

        function setRealPower(obj,Phase,RealPower)
            RealPower=round((120^2/101^2)*RealPower);
            %This function Sets the RealPower on selected Phase
            %Syntax
          
            %   setRealPower(2,5500)
            valueArray=zeros(1,8);
            if ~isnumeric(Phase) && (Phase==1 || Phase == 2 || Phase ==3)
               errordlg('Phase parameter must be 1, 2 or 3', 'Error');
            end
            

            switch Phase
                case 1
                    [slave_id,combination]=findCombination_AR(RealPower);
                    for i=1:length(combination)
                        valueArray(combination(i))=1;
                    end
                    write(obj.LoadBank,"coils",1,valueArray,slave_id)
                    disp("Turned ON the following Loads on Phase 1")
                    disp(valueArray)


                case 2
                    [slave_id,combination]=findCombination_BR(RealPower);
                    for i=1:length(combination)
                        valueArray(combination(i))=1;
                    end
                    write(obj.LoadBank,"coils",25,valueArray,slave_id)
                    disp("Turned ON the following Loads on Phase 2")
                    disp(valueArray)

                case 3
                    [slave_id,combination]=findCombination_CR(RealPower);
                    for i=1:length(combination)
                        valueArray(combination(i))=1;
                    end
                    write(obj.LoadBank,"coils",17,valueArray,slave_id)
                    disp("Turned ON the following Loads on Phase 3")
                    disp(valueArray)
            end

        end

        function resetLoad(obj)
            %resetting
            %write(obj.LoadBank,"coils",startingAddres,values,slaveID)
            write(obj.LoadBank,"coils",1,zeros(1,8),1)
            write(obj.LoadBank,"coils",25,zeros(1,8),1)
            write(obj.LoadBank,"coils",16,zeros(1,8),2)



       

        end
        %turn on Load
        function turnOnLoad(obj)
            % This function turns on the load by setting the coil 15 of
            % slave-3 to high
            %Syntax
            %   write(obj,"coils",address,value,slaveID)
            write(obj.LoadBank,"coils",15,1,3);
        end
        function turnOnPower(obj)
            % This function turns on the load by setting the coil 14 of
            % slave-3 to high
            %Syntax
            %   write(obj,"coils",address,value,slaveID)
            write(obj.LoadBank,"coils",14,1,3);
        end
        function selectVoltageLevel(obj,select)
            %This function will switch voltage level between 120V and 240V
            %Syntax
            %   obj.selectVoltageLevel(X)  
            %   X:
            %   1 = select 120V
            %   2 = select 240V
            %
            if(select==120)
                %select 120V
                write(obj.LoadBank,"coils",9,1,3);
            elseif(select==240)
                %select 240
                write(obj.LoadBank,"coils",10,1,3);
            else
                %throw error
                beep
                errordlg('Wrong voltage selection. Please select 120V or 240V.', 'Error');
            end

        end
        
       %finding combination of loads
       %Method: find combination of Resistive loads for phase A
       function [slave_ID,  combination] = findCombination_AR(inputValue)
        % findCombination_AR Finds the best load combination for AR
        % Syntax:
        %   [Slave-ID, combination] = findCombination_AL(RealPower)
        %
        % Description:
        %   This function finds the best combination of loads to match the 
        %   target value as closely as possible.
        % 
        % Inputs:
        %   RealPower    - load values to set.
        % Outputs:
        %   Slave-ID     - Modbus Slave-ID to select this combination.
        %   combination  - Array of load coil registers to get this load
        % Example
        %   To get 5500W on phase-A call the function as follows
        %   [slave_ID, combination] = findCombination_AR(5500)
        %   this will return:
        %   slave_ID = 1
        %   combination = 3     4     6     7
        slave_ID=1; % This value comes from programming manual of the equipment
        R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
        address = [0, 1, 2, 3, 4, 5, 6, 7];
        address = address+1;
        
        % Get all combinations of indices
        n = numel(R);
        allIndices = 1:n;
        bestDifference = inf;
        bestAddresses = [];
        
        % Loop through all possible subsets
        for subsetSize = 1:n
            combinations = nchoosek(allIndices, subsetSize);
            for i = 1:size(combinations, 1)
                indices = combinations(i, :);
                sumR = sum(R(indices));
                diff = abs(inputValue - sumR);
                if diff == 0
                    combination = address(indices);
                    return; % Exact match found
                elseif diff < bestDifference
                    bestDifference = diff;
                    bestAddresses = address(indices);
                end
            end
        end
        
        % Return closest match
        combination=bestAddresses;
        
       end
       %Method: find combination of Resistive loads for phase B
       function [slave_ID,  combination] = findCombination_BR(inputValue)
        % findCombination_AR Finds the best load combination for AR
        % Syntax:
        %   [Slave-ID, combination] = findCombination_AL(RealPower)
        %
        % Description:
        %   This function finds the best combination of loads to match the 
        %   target value as closely as possible.
        % 
        % Inputs:
        %   RealPower    - load values to set.
        % Outputs:
        %   Slave-ID     - Modbus Slave-ID to select this combination.
        %   combination  - Array of load coil registers to get this load
        % Example
        %   To get 5500W on phase-A call the function as follows
        %   [slave_ID, combination] = findCombination_AR(5500)
        %   this will return:
        %   slave_ID = 1
        %   combination = 3     4     6     7
        % Define the data
        slave_ID=1; % This value comes from programming manual of the equipment
        R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
        %address = [24, 25, 26, 27, 28, 29, 30, 31];
        address = [0, 1, 2, 3, 4, 5, 6, 7];
        address = address+1;
        
        % Get all combinations of indices
        n = numel(R);
        allIndices = 1:n;
        bestDifference = inf;
        bestAddresses = [];
        
        % Loop through all possible subsets
        for subsetSize = 1:n
            combinations = nchoosek(allIndices, subsetSize);
            for i = 1:size(combinations, 1)
                indices = combinations(i, :);
                sumR = sum(R(indices));
                diff = abs(inputValue - sumR);
                if diff == 0
                    combination = address(indices);
                    return; % Exact match found
                elseif diff < bestDifference
                    bestDifference = diff;
                    bestAddresses = address(indices);
                end
            end
        end
        
        % Return closest match
        combination=bestAddresses;
        
       end
       %Method : find combination of Resistive loads for phase C
       function [slave_ID,  combination] = findCombination_CR(inputValue)
        % findCombination_AR Finds the best load combination for AR
        % Syntax:
        %   [Slave-ID, combination] = findCombination_AL(RealPower)
        %
        % Description:
        %   This function finds the best combination of loads to match the 
        %   target value as closely as possible.
        % 
        % Inputs:
        %   RealPower    - load values to set.
        % Outputs:
        %   Slave-ID     - Modbus Slave-ID to select this combination.
        %   combination  - Array of load coil registers to get this load
        % Example
        %   To get 5500W on phase-A call the function as follows
        %   [slave_ID, combination] = findCombination_AR(5500)
        %   this will return:
        %   slave_ID = 1
        %   combination = 3     4     6     7
        % Define the data
        slave_ID=2; % This value comes from programming manual of the equipment
        R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
        %address = [16, 17, 18, 19, 20, 21, 22, 23];
        address = [0, 1, 2, 3, 4, 5, 6, 7];
        address = address+1;
        % Get all combinations of indices
        n = numel(R);
        allIndices = 1:n;
        bestDifference = inf;
        bestAddresses = [];
        
        % Loop through all possible subsets
        for subsetSize = 1:n
            combinations = nchoosek(allIndices, subsetSize);
            for i = 1:size(combinations, 1)
                indices = combinations(i, :);
                sumR = sum(R(indices));
                diff = abs(inputValue - sumR);
                if diff == 0
                    combination = address(indices);
                    return; % Exact match found
                elseif diff < bestDifference
                    bestDifference = diff;
                    bestAddresses = address(indices);
                end
            end
        end
        
        % Return closest match
        combination=bestAddresses;
        
       end
       %Inductive Loads
       %Method : find combination of Inductive loads for phase A
       function [slave_ID, combination] = findCombination_AL(inputValue)
        % findCombination_AR Finds the best load combination for AR
        % Syntax:
        %   [Slave-ID, combination] = findCombination_AL(RealPower)
        %
        % Description:
        %   This function finds the best combination of loads to match the 
        %   target value as closely as possible.
        % 
        % Inputs:
        %   RealPower    - load values to set.
        % Outputs:
        %   Slave-ID     - Modbus Slave-ID to select this combination.
        %   combination  - Array of load coil registers to get this load
        % Example
        %   To get 5500W on phase-A call the function as follows
        %   [slave_ID, combination] = findCombination_AR(5500)
        %   this will return:
        %   slave_ID = 1
        %   combination = 3     4     6     7
        % Define the data
        slave_ID=1; % This value comes from programming manual of the equipment
        R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
        address = [8, 9, 10, 11, 12, 13, 14, 15];
        
        % Get all combinations of indices
        n = numel(R);
        allIndices = 1:n;
        bestDifference = inf;
        bestAddresses = [];
        
        % Loop through all possible subsets
        for subsetSize = 1:n
            combinations = nchoosek(allIndices, subsetSize);
            for i = 1:size(combinations, 1)
                indices = combinations(i, :);
                sumR = sum(R(indices));
                diff = abs(inputValue - sumR);
                if diff == 0
                    combination = address(indices);
                    return; % Exact match found
                elseif diff < bestDifference
                    bestDifference = diff;
                    bestAddresses = address(indices);
                end
            end
        end
        
        % Return closest match
        combination = bestAddresses;
       end
       %Method : find combination of Inductive loads for phase B
       function [slave_ID, combination] = findCombination_BL(inputValue)
        % findCombination_AR Finds the best load combination for AR
        % Syntax:
        %   [Slave-ID, combination] = findCombination_AL(RealPower)
        %
        % Description:
        %   This function finds the best combination of loads to match the 
        %   target value as closely as possible.
        % 
        % Inputs:
        %   RealPower    - load values to set.
        % Outputs:
        %   Slave-ID     - Modbus Slave-ID to select this combination.
        %   combination  - Array of load coil registers to get this load
        % Example
        %   To get 5500W on phase-A call the function as follows
        %   [slave_ID, combination] = findCombination_AR(5500)
        %   this will return:
        %   slave_ID = 1
        %   combination = 3     4     6     7
        % Define the data
        slave_ID=2; % This value comes from programming manual of the equipment
        R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
        address = [0, 1, 2, 3, 4, 5, 6, 7];
        
        % Get all combinations of indices
        n = numel(R);
        allIndices = 1:n;
        bestDifference = inf;
        bestAddresses = [];
        
        % Loop through all possible subsets
        for subsetSize = 1:n
            combinations = nchoosek(allIndices, subsetSize);
            for i = 1:size(combinations, 1)
                indices = combinations(i, :);
                sumR = sum(R(indices));
                diff = abs(inputValue - sumR);
                if diff == 0
                    combination = address(indices);
                    return; % Exact match found
                elseif diff < bestDifference
                    bestDifference = diff;
                    bestAddresses = address(indices);
                end
            end
        end
        
        % Return closest match
        combination = bestAddresses;
       end

       %Method : find combination of Inductive loads for phase C
       function [slave_ID,  combination] = findCombination_CL(inputValue)
        % findCombination_AR Finds the best load combination for AR
        % Syntax:
        %   [Slave-ID, combination] = findCombination_AL(RealPower)
        %
        % Description:
        %   This function finds the best combination of loads to match the 
        %   target value as closely as possible.
        % 
        % Inputs:
        %   RealPower    - load values to set.
        % Outputs:
        %   Slave-ID     - Modbus Slave-ID to select this combination.
        %   combination  - Array of load coil registers to get this load
        % Example
        %   To get 5500W on phase-A call the function as follows
        %   [slave_ID, combination] = findCombination_AR(5500)
        %   this will return:
        %   slave_ID = 1
        %   combination = 3     4     6     7
        % Define the data
        slave_ID=2; % This value comes from programming manual of the equipment
        R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
        address = [24, 25, 26, 27, 28, 29, 30, 31];
        
        % Get all combinations of indices
        n = numel(R);
        allIndices = 1:n;
        bestDifference = inf;
        bestAddresses = [];
        
        % Loop through all possible subsets
        for subsetSize = 1:n
            combinations = nchoosek(allIndices, subsetSize);
            for i = 1:size(combinations, 1)
                indices = combinations(i, :);
                sumR = sum(R(indices));
                diff = abs(inputValue - sumR);
                if diff == 0
                    combination = address(indices);
                    return; % Exact match found
                elseif diff < bestDifference
                    bestDifference = diff;
                    bestAddresses = address(indices);
                end
            end
        end
        
        % Return closest match
        combination=bestAddresses;
        
       end

        %Capacitive Loads
        %Method : find combination of Capacitive loads for phase A
        function [slave_ID, combination] = findCombination_AC(inputValue)
            % findCombination_AR Finds the best load combination for AR
            % Syntax:
            %   [Slave-ID, combination] = findCombination_AL(RealPower)
            %
            % Description:
            %   This function finds the best combination of loads to match the 
            %   target value as closely as possible.
            % 
            % Inputs:
            %   RealPower    - load values to set.
            % Outputs:
            %   Slave-ID     - Modbus Slave-ID to select this combination.
            %   combination  - Array of load coil registers to get this load
            % Example
            %   To get 5500W on phase-A call the function as follows
            %   [slave_ID, combination] = findCombination_AR(5500)
            %   this will return:
            %   slave_ID = 1
            %   combination = 3     4     6     7
            % Define the data
            slave_ID=1; % This value comes from programming manual of the equipment
            R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
            address = [16, 17, 18, 19, 20, 21, 22, 23];
            
            % Get all combinations of indices
            n = numel(R);
            allIndices = 1:n;
            bestDifference = inf;
            bestAddresses = [];
            
            % Loop through all possible subsets
            for subsetSize = 1:n
                combinations = nchoosek(allIndices, subsetSize);
                for i = 1:size(combinations, 1)
                    indices = combinations(i, :);
                    sumR = sum(R(indices));
                    diff = abs(inputValue - sumR);
                    if diff == 0
                        combination = address(indices);
                        return; % Exact match found
                    elseif diff < bestDifference
                        bestDifference = diff;
                        bestAddresses = address(indices);
                    end
                end
            end
            
            % Return closest match
            combination = bestAddresses;
        end
        %Method : find combination of Capacitive loads for phase B
        function [slave_ID, combination] = findCombination_BC(inputValue)
            % findCombination_AR Finds the best load combination for AR
            % Syntax:
            %   [Slave-ID, combination] = findCombination_AL(RealPower)
            %
            % Description:
            %   This function finds the best combination of loads to match the 
            %   target value as closely as possible.
            % 
            % Inputs:
            %   RealPower    - load values to set.
            % Outputs:
            %   Slave-ID     - Modbus Slave-ID to select this combination.
            %   combination  - Array of load coil registers to get this load
            % Example
            %   To get 5500W on phase-A call the function as follows
            %   [slave_ID, combination] = findCombination_AR(5500)
            %   this will return:
            %   slave_ID = 1
            %   combination = 3     4     6     7
            % Define the data
            slave_ID=2; % This value comes from programming manual of the equipment
            R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
            address = [8, 9, 10, 11, 12, 13, 14, 15];
            
            % Get all combinations of indices
            n = numel(R);
            allIndices = 1:n;
            bestDifference = inf;
            bestAddresses = [];
            
            % Loop through all possible subsets
            for subsetSize = 1:n
                combinations = nchoosek(allIndices, subsetSize);
                for i = 1:size(combinations, 1)
                    indices = combinations(i, :);
                    sumR = sum(R(indices));
                    diff = abs(inputValue - sumR);
                    if diff == 0
                        combination = address(indices);
                        return; % Exact match found
                    elseif diff < bestDifference
                        bestDifference = diff;
                        bestAddresses = address(indices);
                    end
                end
            end
            
            % Return closest match
            combination = bestAddresses;
        end
        %Method : find combination of Capacitive loads for phase C
        function [slave_ID,  combination] = findCombination_CC(inputValue)
            % findCombination_AR Finds the best load combination for AR
            % Syntax:
            %   [Slave-ID, combination] = findCombination_AL(RealPower)
            %
            % Description:
            %   This function finds the best combination of loads to match the 
            %   target value as closely as possible.
            % 
            % Inputs:
            %   RealPower    - load values to set.
            % Outputs:
            %   Slave-ID     - Modbus Slave-ID to select this combination.
            %   combination  - Array of load coil registers to get this load
            % Example
            %   To get 5500W on phase-A call the function as follows
            %   [slave_ID, combination] = findCombination_AR(5500)
            %   this will return:
            %   slave_ID = 1
            %   combination = 3     4     6     7
            % Define the data
            slave_ID=3; % This value comes from programming manual of the equipment
            R = [100, 200, 200, 500, 1000, 1000, 2000, 2000];
            address = [0, 1, 2, 3, 4, 5, 6, 7];
            
            % Get all combinations of indices
            n = numel(R);
            allIndices = 1:n;
            bestDifference = inf;
            bestAddresses = [];
            
            % Loop through all possible subsets
            for subsetSize = 1:n
                combinations = nchoosek(allIndices, subsetSize);
                for i = 1:size(combinations, 1)
                    indices = combinations(i, :);
                    sumR = sum(R(indices));
                    diff = abs(inputValue - sumR);
                    if diff == 0
                        combination = address(indices);
                        return; % Exact match found
                    elseif diff < bestDifference
                        bestDifference = diff;
                        bestAddresses = address(indices);
                    end
                end
            end
            
            % Return closest match
            combination=bestAddresses;
            
        end


        %heartbeat
                % filepath: c:\Users\Sajid Ali\Downloads\2025-04-18\loadBank\loadBank-VILVA-automation-with-MATLAB\LoadBankController_4app.m
        function heartbeat(obj)
            % Heartbeat function to check Modbus connection status
            try
                % Attempt to read a coil or register to verify connection
                read(obj.LoadBank, "coils", 1, 1, 1); % Example: Read coil 1 from slave 1
                fprintf('Heartbeat: Modbus connection is active.\n');
            catch ME
                % Handle connection failure
                fprintf('Heartbeat: Modbus connection failed: %s\n', ME.message);
                % Optionally, attempt to reconnect
                obj.reconnect();
            end
        end

        %reconnect if lost connection
        % filepath: c:\Users\Sajid Ali\Downloads\2025-04-18\loadBank\loadBank-VILVA-automation-with-MATLAB\LoadBankController_4app.m
        function reconnect(obj)
            % Reconnect to the Modbus device
            fprintf('Attempting to reconnect to Modbus...\n');
            try
                obj.LoadBank = modbus('serialrtu', obj.PortNumber); % Recreate Modbus object
                obj.LoadBank.Timeout = 3; % Set timeout
                fprintf('Reconnection successful.\n');
            catch ME
                fprintf('Reconnection failed: %s\n', ME.message);
                % Optionally, notify the user or retry after a delay
            end
        end
        %setting heartbeat interval
        % filepath: c:\Users\Sajid Ali\Downloads\2025-04-18\loadBank\loadBank-VILVA-automation-with-MATLAB\LoadBankController_4app.m
        function startHeartbeat(obj, interval)
            % Start a timer to periodically check the Modbus connection
            t = timer('ExecutionMode', 'fixedRate', ...
                    'Period', interval, ...
                    'TimerFcn', @(~,~) obj.heartbeat());
            start(t);
            fprintf('Heartbeat started with an interval of %.2f seconds.\n', interval);
        end

        %stop heartbeat
        function stopHeartbeat(~)
            % Stop the heartbeat timer
            stop(timerfindall);
            delete(timerfindall);
            fprintf('Heartbeat stopped.\n');
        end

    end
            
    
    
        
        
    
    


    



 end