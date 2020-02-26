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
        doorState = 'canOpen' % canClose canKeepOpening
        doorSpeed = 0;
        
        currentCabinPosition = 0 % Position in term of visualization
        currentCabinFloor =  1 % Floor in the building
        currentCabinIsUp = true % going up
        
        nextCabinFloor = 1 % Next floor cabin is going 
        nextCabinPosition = 0;
        
        queue = struct('floorRequest',[],'direction',[]);
        
    end
    
    methods
        function obj = cabinElevator(varargin)
            %cabinElevator Construct an instance of this class
            %   Detailed explanation goes here
            if nargin == 1 % No init floor, all start from 0
                obj.currentCabinFloor = varargin{1};
                obj.currentCabinPosition = varargin{1}*100;
            end
        end
        
        function obj = visualize(obj)
            % Function to add velocity of cabin -1/0/1 or door -1/0/1, the
            % visualization needs the speeds in order to perform
            % corresponding movements of door and cabin
            
            % Update the current status of the cabin and door
            

            % Go to the elevator state machine: there are five
            % state: idle, donw, up, door and emergency (Fire)
            switch(app.cabinState)
                case 'idle'
                case 'up'
                    if obj.nextCabinPosition > obj.currentCabinPosition
                        obj.cabinSpeed = 1;
                        obj.cabinState = 'up';
                    elseif obj.nextCabinPosition == obj.currentCabinPosition
                        obj.cabinSpeed = 0; % Stop moving the cabin
                        obj.cabinState = 'idle'; % Put the cabin state to idle
                    end
                case 'down'
                    if obj.nextCabinPosition < obj.currentCabinPosition
                        obj.cabinSpeed = -1;
                        obj.cabinState = 'down';
                    elseif obj.nextCabinPosition == obj.currentCabinPosition
                        obj.cabinSpeed = 0;
                        obj.cabinState = 'idle';
                    end
                case 'door'
                    
                    % Set the door opening condition
                    app.doorOpening = true;

                    switch(app.doorState)
                        case 'canOpen'
           vcb c
                            if strcmp(app.CloseDoor.Enable,'off')
                                % Turn on close door button
                                app.CloseDoor.BackgroundColor = [0.96 0.96 0.96];
                                app.CloseDoor.Enable = 'on';
                            end
                            
                            if app.door.Vertices(3,1) >= 5 % The door is completely opened
                                set(app.door, 'Vertices',app.door.Vertices-app.velXdoor*app.dt);
                            else
                                app.doorState = 'canKeepingOpen';
                            end
                            app.elevatorIsMoving = false;
                        case 'canClose'
                            % We activate open door button
                            app.OpenDoor.BackgroundColor = [0.96 0.96 0.96];
                            app.OpenDoor.Enable = 'on';
                            app.CloseDoor.BackgroundColor = 'g';
                            app.CloseDoor.Enable = 'off';
                            
                            if app.door.Vertices(3,1) < 50 % The door is completely closed
                                set(app.door, 'Vertices',app.door.Vertices+app.velXdoor*app.dt);
                            else
                                app.doorState = 'canOpen';
                                app.elevatorState = 'idle';
                                
                                % Turn on close door button
                                app.CloseDoor.BackgroundColor = [0.96 0.96 0.96];
                                app.CloseDoor.Enable = 'on';
                                
                                app.doorOpening = false;
                                app.doorOpeningLamp.Color = 'r';
                            end
                        case 'canKeepingOpen'
                            app.data.keepDoor = app.data.keepDoor+1;
                            app.DoorKeepOpenEditField.Value = app.data.keepDoor*app.dispTimer.Period;
                            if app.data.keepDoor == app.data.keepMaxDoor
                                app.data.keepDoor = 0;
                                app.doorState = 'canClose';
                                
                            end
                    end
                    % Show the current door state
                    app.DoorEditField.Value = app.doorState;
                case 'fire'
            end
            
        end
        
        function obj = addQueue(obj,floorRequest,directionRequest)
            % Add new floor request and direction to queue
            obj.queue.floorRequest = [obj.queue.floorRequest; floorRequest];
            obj.queue.direction = [obj.queue.direction; directionRequest];
            
            % Sort queue according to current cabin floor
            obj = obj.sortQueue;
        end
        
        function obj = sortQueue(obj)
            % The function to sort the queue based on the new command floor
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
                switch(obj.currentCabinIsUp)
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

