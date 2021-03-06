classdef cabinElevator
    %cabinElevator To illustrate how many cabin in an elevator
    %   Detailed explanation goes here
    
    properties
        cabinIsMoving = false
        cabinIsUp = true
        cabinState = 'idle' % down up door and fire
        cabinSpeed = 0;
        
        doorIsOpening = false
        doorOpenRequest = false
        doorCloseRequest = false
        doorState = 'canOpen' % canClose canKeepOpening
        doorSpeed = 0;
        
        fireAlarm = false;
        
        currentCabinPosition = 10 % Position in term of visualization
        currentCabinFloor =  1 % Floor in the building
        currentDoorPosition % Current door position, between full open/close
        
        nextCabinFloor % Next floor cabin is going
        nextCabinPosition;
        
        doorMaxPosition = 25.5;
        doorMinPosition = 2.5;
        
        keepDoorOpenInTime = 0;
        keepDoorOpenInTime_max = 1.5/0.03;
        totalDoorOpenTime = 0;
        
        allFloorPosition = [10 110 210 310 410 510];
        allFloor = [1 2 3 4 5 6];
        
        cabinMaxPosition = 510;
        cabinMinPosition = 10;
        
        queue = struct('floorRequest',[],'direction',[]);
    end
    
    methods
        function obj = cabinElevator(varargin)
            %cabinElevator Construct an instance of this class
            %   Detailed explanation goes here
            if nargin == 1 % No init floor, all start from 0
                obj.currentCabinFloor = varargin{1};
                obj.currentCabinPosition = obj.allFloorPosition(obj.currentCabinFloor);
            end
            if isempty(obj.queue.floorRequest)
                obj.nextCabinFloor = obj.currentCabinFloor ;
                obj.nextCabinPosition = obj.currentCabinPosition;
            end
        end
        
        
        function obj = visualize(obj,currentCabinPosition,currentDoorPosition)
            %visualize to add velocity of cabin -1/0/1 or door -1/0/1 that
            % needs speeds in order to perform corresponding movements of
            % the door and cabin
            
            
            % Update the current position of the cabin and door
            obj = obj.changeProperty('currentCabinPosition',currentCabinPosition);
            obj = obj.changeProperty('currentCabinFloor');
            obj = obj.changeProperty('currentDoorPosition',currentDoorPosition);
            
            % Update the current cabin floor
            obj = obj.changeProperty('currentCabinFloor');
            
            % Go to the elevator state machine: there are five
            % state: idle, donw, up, door and emergency (Fire)
            switch(obj.cabinState)
                case 'idle'
                    % Check if the cabin is not moving and doorOpenRequest true
                    obj.totalDoorOpenTime = 0;
                    % Update next cabin position based on the queue
                    obj = obj.changeProperty('nextCabinPosition');
                    if obj.fireAlarm
                        obj.cabinState = 'fire';
                        
                    elseif ~obj.cabinIsMoving && obj.doorOpenRequest
                        obj.cabinState = 'door';
                        obj.doorIsOpening = true;
                        obj.cabinIsMoving = false;
                    elseif ~obj.doorIsOpening % door should be closed when cabin is moving
                        if obj.nextCabinPosition > obj.currentCabinPosition
                            obj.cabinState = 'up';
                            obj.cabinIsMoving = true;
                            obj.cabinIsUp = true;
                        elseif obj.nextCabinPosition < obj.currentCabinPosition
                            obj.cabinState = 'down';
                            obj.cabinIsMoving = true;
                            obj.cabinIsUp = false;
                        else
                            obj.cabinState = 'idle';
                            obj.cabinIsMoving  = false;
                        end
                        
                    end
                case 'up'
                    if obj.nextCabinPosition > obj.currentCabinPosition
                        obj.cabinSpeed = 1;
                        obj.cabinState = 'up';
                    else
                        obj.cabinSpeed = 0; % Stop moving the cabin
                        obj.cabinIsMoving = false;
                        obj.doorOpenRequest = true;
                        obj.cabinState = 'idle'; % Put the cabin state to idle
                    end
                case 'down'
                    if obj.nextCabinPosition < obj.currentCabinPosition
                        obj.cabinSpeed = -1;
                        obj.cabinState = 'down';
                    else
                        obj.cabinSpeed = 0;
                        obj.cabinIsMoving = false;
                        obj.cabinState = 'idle'; % Put the cabin state to idle
                        obj.doorOpenRequest = true;
                    end
                    
                case 'door'
                    obj.totalDoorOpenTime = obj.totalDoorOpenTime + 1;
                    switch(obj.doorState)
                        case 'canOpen'
                            if obj.currentDoorPosition > obj.doorMinPosition % The door is completely opened
                                obj.doorSpeed = -1;
                            else
                                obj.doorSpeed = 0;
                                obj.doorState = 'canKeepOpen';
                                
                                % When the door is fully opened, the
                                % doorrequest can be received
                                obj.doorOpenRequest = false;
                            end
                            
                        case 'canClose'
                            % When door is closing, if doorOpenRequest is
                            % true, then jump directly to canOpen case
                            if obj.doorOpenRequest
                                obj.doorState = 'canOpen';
                                obj.doorSpeed = 0;
                            else
                                if obj.currentDoorPosition < obj.doorMaxPosition % The door is completely closed
                                    obj.doorSpeed = 1;
                                else % The door is fully close
                                    obj.doorSpeed = 0;
                                    obj.doorState = 'canOpen';
                                    
                                    obj.doorIsOpening = false;
                                    obj.cabinState = 'idle';
                                end
                            end
                            
                        case 'canKeepOpen'
                            % When the door is fully opened, if
                            % doorOpenRequest is true, then reset
                            if obj.doorOpenRequest
                                obj.keepDoorOpenInTime = 0;
                                % Reset doorOpenRequest
                                obj.doorOpenRequest = false;
                            else
                                if obj.doorCloseRequest
                                    obj.keepDoorOpenInTime  = obj.keepDoorOpenInTime_max;
                                    obj.doorCloseRequest = false;
                                else
                                    obj.keepDoorOpenInTime = obj.keepDoorOpenInTime+1;
                                end
                                if obj.keepDoorOpenInTime >= obj.keepDoorOpenInTime_max
                                    % Reset the keep opening door timer
                                    obj.keepDoorOpenInTime = 0;
                                    obj.doorState = 'canClose';
                                end
                            end
                    end
                    
                case 'fire'
                    % Add the force command to the cabin,
                    % if cabin is not moving, open door
                    % otherwise move to the next floor and open door.
                    % Check the current position
                    isInFloor = (obj.currentCabinPosition == obj.allFloorPosition);
                    if ~isempty(isInFloor) && ~obj.cabinIsMoving
                        % Just open door
                        if obj.currentDoorPosition > obj.doorMinPosition
                            obj.doorSpeed = -1;
                        else
                            obj.doorSpeed = 0;
                            obj.doorOpenRequest = false;
                        end
                        obj.doorIsOpening = true;
                    else % Move to the closest floor in the same direction
                        switch(obj.cabinIsUp)
                            case  true
                                if obj.currentCabinPosition ~= obj.allFloorPosition(obj.currentCabinFloor+1)
                                    obj.cabinSpeed = 1;
                                else
                                    obj.cabinSpeed = 0;
                                    obj.cabinIsMoving = false;
                                end
                            case false
                                if obj.currentCabinPosition ~= obj.allFloorPosition(obj.currentCabinFloor)
                                    obj.cabinSpeed = -1;
                                else
                                    obj.cabinSpeed = 0;
                                    obj.cabinIsMoving = false;
                                end
                        end
                    end
                    if ~obj.fireAlarm && (obj.currentDoorPosition < obj.doorMaxPosition)
                        obj.doorSpeed = 1; % Try to close to the door
                    elseif ~obj.fireAlarm && (obj.currentDoorPosition == obj.doorMaxPosition)
                        obj.doorSpeed = 0;
                        obj.cabinState = 'idle';
                        obj.doorIsOpening = false;
                    end
            end
        end
        
        function obj = changeProperty(obj,varargin)
            % changeProperty to change a property of the class instance
            % Structure: 'property' 'value'
            if nargin ~= 1
                switch(varargin{1})
                    case 'doorOpenRequest'
                        if islogical(varargin{2})
                            obj.doorOpenRequest = varargin{2};
                        end
                    case 'doorCloseRequest'
                        if islogical(varargin{2})
                            obj.doorCloseRequest = varargin{2};
                        end
                    case 'currentCabinPosition'
                        if isnumeric(varargin{2})
                            if varargin{2} < obj.cabinMinPosition
                                obj.currentCabinPosition = obj.cabinMinPosition;
                            elseif varargin{2} > obj.cabinMaxPosition
                                obj.currentCabinPosition = obj.cabinMaxPosition;
                            else
                                obj.currentCabinPosition = varargin{2};
                            end
                        end
                        
                    case 'currentCabinFloor'
                        ind_floor = find((obj.allFloorPosition>=obj.currentCabinPosition)==1);
                        obj.currentCabinFloor = ind_floor(1);
                        
                    case 'currentDoorPosition'
                        if isnumeric(varargin{2})
                            if varargin{2} < obj.doorMinPosition
                                obj.currentDoorPosition = obj.doorMinPosition;
                            elseif varargin{2} > obj.doorMaxPosition
                                obj.currentDoorPosition = obj.doorMaxPosition;
                            else
                                obj.currentDoorPosition = varargin{2};
                            end
                        end
                        
                    case 'nextCabinPosition'
                        % This is a step to recheck the prevent any mistake
                        % in the queue.
                        
                        % Sort the queue fist, delete the duplicate,
                        obj = obj.sortQueue;
                        if isempty(obj.queue.floorRequest)
                            obj.nextCabinFloor = obj.currentCabinFloor;
                            obj.nextCabinPosition = obj.currentCabinPosition;
                        else
                            obj.nextCabinFloor = obj.queue.floorRequest(1);
                            if obj.allFloorPosition(obj.nextCabinFloor) == obj.currentCabinPosition
                                if length(obj.queue.floorRequest) == 1
                                    obj.queue.floorRequest = [];
                                    obj.queue.direction = [];
                                    obj.nextCabinFloor = obj.currentCabinFloor;
                                    obj.nextCabinPosition = obj.currentCabinPosition;
                                else
                                    obj.queue.floorRequest = obj.queue.floorRequest(2:end);
                                    obj.queue.direction = obj.queue.direction(2:end);
                                    obj.nextCabinFloor = obj.queue.floorRequest(1);
                                    obj.nextCabinPosition = obj.allFloorPosition(obj.nextCabinFloor);
                                end
                            end
                        end  
                    case 'nextCabinFloor'
                        obj.nextCabinFloor = find( obj.allFloorPosition == obj.nextCabinPosition);
                    case 'doorMaxPosition'
                        if isnumeric(varargin{2})
                            obj.doorMaxPosition = varargin{2};
                        end
                    case 'doorMinPosition'
                        if isnumeric(varargin{2})
                            obj.doorMinPosition = varargin{2};
                        end
                    case 'keepDoorOpenInTime'
                        obj.keepDoorOpenInTime = varargin{2};
                    case 'keepDoorOpenInTime_max'
                        obj.keepDoorOpenInTime_max = varargin{2};
                    case 'allFloorPosition'
                        obj.allFloorPosition = varargin{2};
                    case 'allFloor'
                        obj.allFloor = varargin{2};
                    case 'fireAlarm'
                        if islogical(varargin{2})
                            obj.fireAlarm = varargin{2};
                        end
                    case 'cabinMaxPosition'
                        obj.cabinMaxPosition = varargin{2};
                    case 'cabinMinPosition'
                        obj.cabinMinPosition = varargin{2};
                    case 'queue'
                        floorRequest = varargin{2}(:,1);
                        directionRequest = varargin{2}(:,2);
                        
                        %addQueue add new floor request and direction to queue
                        obj.queue.floorRequest = [obj.queue.floorRequest; floorRequest];
                        obj.queue.direction = [obj.queue.direction; directionRequest];
                        
                        % Sort queue according to current cabin floor
                        obj = obj.sortQueue;
                        
                        % Add the new floor request to the nextCabinPosition
                        if ~isempty(obj.queue.floorRequest)
                            obj.nextCabinFloor = obj.queue.floorRequest(1);
                            obj.nextCabinPosition = obj.allFloorPosition(obj.nextCabinFloor);
                        else
                            obj.nextCabinFloor = obj.currentCabinFloor;
                            obj.nextCabinPosition = obj.currentCabinPosition;
                        end
                end
            end
        end
        
        
        function obj = sortQueue(obj)
            %sortQueue to sort the queue based on the new command floor
            % Two parameters: floor list and direction list
            % Two condition: currentDirection, currentFloor
            
            % First, check if floorRequest is not empty
            if ~isempty(obj.queue.floorRequest)
                ind_down = (obj.queue.direction>0);
                floor_downList = obj.queue.floorRequest(~ind_down);
                floor_upList = obj.queue.floorRequest(ind_down);
                
                % Now we check the duplication in the floow_down or floor_up and sorted
                % result
                floor_downList = unique(floor_downList);
                floor_upList = unique(floor_upList);
                
                % floor down list sorted as descend order
                floor_downList = sort(floor_downList,'descend');
                floor_upList = sort(floor_upList,'ascend');
                
                % Now we check the current direction
                switch(obj.cabinIsUp)
                    case true % Going up
                        % Find the index of floors which upper or equal than current floor
                        ind_upper_currentFloor_up = floor_upList>=obj.currentCabinFloor;
                        upper_floor_up = floor_upList(ind_upper_currentFloor_up);
                        lower_floor_up = floor_upList(~ind_upper_currentFloor_up);
                        
                        resultFloorList = [upper_floor_up; floor_downList;...
                            lower_floor_up];
                        resultDirectionList = [ones(size(upper_floor_up));-ones(size(floor_downList));
                            ones(size(lower_floor_up))];
                        
                    case false % Going down
                        % Find the index of floors which lower or equal than current floor
                        ind_upper_currentFloor_down = floor_downList<=obj.currentCabinFloor;
                        lower_floor_down = floor_downList(ind_upper_currentFloor_down);
                        upper_floor_down = floor_downList(~ind_upper_currentFloor_down);
                        
                        resultFloorList = [lower_floor_down; floor_upList;...
                            upper_floor_down];
                        resultDirectionList = [-ones(size(lower_floor_down));ones(size(floor_upList));
                            -ones(size(upper_floor_down))];
                end
            else
                resultFloorList = [];
                resultDirectionList = [];
            end
            obj.queue.floorRequest = resultFloorList;
            obj.queue.direction = resultDirectionList;
        end
        
    end
end

