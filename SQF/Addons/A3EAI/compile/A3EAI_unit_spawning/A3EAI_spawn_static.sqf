/*
	spawnBandits
	
	Usage: [_minAI, _addAI, _patrolDist, _trigger, _numGroups (optional)] spawn spawnBandits;
	
	Description: Called through (mapname)_config.sqf when a static trigger is activated by a player.
	
	Last updated: 8:38 AM 10/23/2013
*/

private ["_minAI","_addAI","_patrolDist","_trigger","_unitLevel","_numGroups","_grpArray","_triggerPos","_startTime","_totalSpawned","_debugMarkers","_triggerStatements","_groupsActive"];


_minAI = _this select 0;									//Mandatory minimum number of AI units to spawn
_addAI = _this select 1;									//Maximum number of additional AI units to spawn
_patrolDist = _this select 2;								//Patrol radius from trigger center.
_trigger = _this select 3;									//The trigger calling this script.
//_positionArray = _this select 4;							//Array of manually-defined spawn points (markers). If empty, nearby buildings are used as spawn points.
_unitLevel = if ((count _this) > 5) then {_this select 5} else {1};		//(Optional) Select the item probability table to use
_numGroups = if ((count _this) > 6) then {_this select 6} else {1};		//(Optional) Number of groups of x number of units each to spawn

_startTime = diag_tickTime;

_grpArray = _trigger getVariable ["GroupArray",[]];	
_groupsActive = count _grpArray;
//_debugMarkers = ((!isNil "A3EAI_debugMarkersEnabled") && {A3EAI_debugMarkersEnabled});

_trigger setTriggerArea [750,750,0,false]; //Expand trigger area to prevent players from quickly leaving and start respawn process immediately
_triggerPos = ASLtoATL getPosASL _trigger;

//If trigger already has defined spawn points, then reuse them instead of recalculating new ones.
_locationArray = _trigger getVariable ["locationArray",[]];	
_totalSpawned = 0;

//Spawn groups
if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Extended Debug: Trigger %1 is spawning units...",triggerText _trigger]};
for "_j" from 1 to (_numGroups - _groupsActive) do {
	private ["_unitGroup","_spawnPos","_totalAI"];
	_totalAI = 0;
	_spawnPos = [];
	if ((_trigger getVariable ["spawnChance",0.90]) call A3EAI_chance) then {
		_totalAI = (_minAI + round(random _addAI));
		_spawnPos = if ((count _locationArray) > 0) then {_locationArray call A3EAI_findSpawnPos} else {[(ASLtoATL getPosASL _trigger),random (_patrolDist),random(360),0] call SHK_pos};
	};

	//If non-zero unit amount and valid spawn position, spawn group, otherwise add it to respawn queue.
	_unitGroup = grpNull;
	if ((_totalAI > 0) && {(count _spawnPos) > 1}) then {
		_unitGroup = [_totalAI,_unitGroup,_spawnPos,_trigger,_unitLevel] call A3EAI_spawnGroup;
		_totalSpawned = _totalSpawned + _totalAI;
		if (_patrolDist > 1) then {
			0 = [_unitGroup,_triggerPos,_patrolDist] spawn A3EAI_BIN_taskPatrol;
		} else {
			[_unitGroup, 0] setWaypointType "HOLD";
		};
		if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Extended Debug: Spawned group %1 (unitLevel: %2) with %3 units.",_unitGroup,_unitLevel,_totalAI];};
	} else {
		_unitGroup = ["protect"] call A3EAI_createGroup;
		_unitGroup setVariable ["GroupSize",0];
		_unitGroup setVariable ["trigger",_trigger];
		0 = [0,_trigger,_unitGroup] call A3EAI_addRespawnQueue;
		if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Extended Debug: No units spawned for group %1. Added group to respawn queue.",_unitGroup];};
	};
	
	_unitGroup setVariable ["unitType","static"];
	_grpArray pushBack _unitGroup;
};

if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Extended Debug: Trigger %1 group array updated to: %2.",triggerText _trigger,_trigger getVariable "GroupArray"]};
//_trigger setVariable ["isCleaning",false];
//_triggerStatements = (triggerStatements _trigger);
//_triggerStatements set [1,""];
//_trigger setTriggerStatements _triggerStatements;
//[_trigger,"A3EAI_staticTriggerArray"] call A3EAI_updateSpawnCount;

if (A3EAI_debugLevel > 0) then {diag_log format["A3EAI Debug: Spawned %1 new AI groups (%2 units total) in %3 seconds at %4.",_numGroups,_totalSpawned,(diag_tickTime - _startTime),(triggerText _trigger)];};

/*
if (_debugMarkers) then {
	_nul = _trigger call A3EAI_addMapMarker;
};
*/
//diag_log format ["DEBUG :: Activated trigger %1 has statements %2.",triggerText _trigger,triggerStatements _trigger];

true