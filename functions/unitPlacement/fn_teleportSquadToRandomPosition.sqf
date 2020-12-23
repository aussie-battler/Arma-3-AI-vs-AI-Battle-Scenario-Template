params ["_group", "_centerPos", "_minimumDistance", "_maximumDistance", "_maxGradient", "_waterMode", "_shoreMode"];

_actuallyVehicleClasses = ["Car", "Armored", "Air", "Support"];

_vehicles = [];
_dismounts = [];

{
    _vehicleConfig = configFile >> "cfgVehicles" >> (typeOf vehicle _x);

    _vehicleClass = getText (_vehicleConfig >> "vehicleClass");

    if (_vehicleClass in _actuallyVehicleClasses) then {
        _vehicles append [_x];
    } else {
        _dismounts append [_x];
    };
} forEach (units _group);



// No vehicles in group - simpler way to spawn infantry
if (count (_vehicles) == 0) exitWith {
    _randomPosition = [_centerPos, _minimumDistance, _maximumDistance, 1, 0, 0.6, 0] call BIS_fnc_findSafePos;
    {
        _unitPosition = _randomPosition findEmptyPosition [2, 20, typeOf _x];
        _azimuth = random [0, 180, 359];

        vehicle _x setPos _unitPosition; // Set on vehicle because it might be a turret
        vehicle _x setDir _azimuth;
    } foreach units _group;
};



// Try to find a road section
_startingRoadSection = [_centerPos, _minimumDistance, _maximumDistance] call Rimsiakas_fnc_findRoad;



// No road section was found
if (isNil "_startingRoadSection" == true) exitWith {
    _requiredArea = 10 + (count (_vehicles) * 5);

    _defaultPos = [[0,0],[0,0]];

    _randomPosition = [_centerPos, _minimumDistance, _maximumDistance, _requiredArea, 0, 0.3, 0, nil, _defaultPos] call BIS_fnc_findSafePos;

    if ((_randomPosition select 0) == 0) then {
        _randomPosition = [_centerPos, _minimumDistance, _maximumDistance, 1, 0, 0.3, 0] call BIS_fnc_findSafePos;
        _terrainObjects = nearestTerrainObjects [_randomPosition, [], _requiredArea, false];

        {
            _x hideObjectGlobal true;
        } forEach _terrainObjects;
    };


    {
        _unitPosition = [_randomPosition, 0, _requiredArea, 5, 0, 0.6, 0] call BIS_fnc_findSafePos;
        _azimuth = random [0, 180, 359];

        vehicle _x setPos _unitPosition;
        vehicle _x setDir _azimuth;
    } forEach _vehicles;

    {
        _unitPosition = _randomPosition findEmptyPosition [5, _requiredArea, typeOf _x];
        _azimuth = random [0, 180, 359];

        vehicle _x setPos _unitPosition;
        vehicle _x setDir _azimuth;
    } forEach _dismounts;
};



// Road section was found
if (isNil "_startingRoadSection" == false) exitWith {
    _nearbyRoadSections = nearestTerrainObjects [getPos _startingRoadSection, ["ROAD", "MAIN ROAD", "TRACK"], 100, true];



    // Handle vehicles in group
    {
        _vehicle = vehicle _x;
        _availableRoadSection = nil;

        {
            _nearbyEntities = (getPos _x) nearEntities 5;
            if ((count _nearbyEntities) == 0) exitWith
                {_availableRoadSection = _x;
                _nearbyRoadSections deleteAt _forEachIndex;
            }
        } forEach _nearbyRoadSections;

        if (isNil "_availableRoadSection" == false) then {
            _vehicle setPos (getPos _availableRoadSection);
        } else {
            // No safe road section was found, so clear an area nearby
            _positionForVehicle = [_startingRoadSection, 5, 30, 0, 0, 0.6, 0] call BIS_fnc_findSafePos;
            _terrainObjects = nearestTerrainObjects [_positionForVehicle, [], 6, false];
            {
                _x hideObjectGlobal true;
            } forEach _terrainObjects;

            _vehicle setPos _positionForVehicle;
        };
    } forEach _vehicles;



    // Handle dismounts in group
    {
        _unitPosition = (getPos _startingRoadSection) findEmptyPosition [5, 20, typeOf _x];
        _azimuth = random [0, 180, 359];

        vehicle _x setPos _unitPosition;
        vehicle _x setDir _azimuth;
    } forEach _dismounts;
};