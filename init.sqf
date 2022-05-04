///////////////////////////////////////
// Function file for Armed Assault 3 //
//     Created by: DreadedEntity     //
///////////////////////////////////////

sleep 0.1;

player switchCamera "External";

//[] spawn {
//	while {true} do {
//		hintSilent str (player weaponState "HandGrenade_Stone");
//	}
//};

//required so the "throw" can reload, otherwise the first press won't work
player addMagazine "HandGrenade_stone";

//keydown UI EH - Adds another hotkey to the main "game" display to get the keypress
//note 35 == "H" key
(findDisplay 46) displayAddEventHandler ["KeyDown", {
	if ((_this select 1) == 35) then {
		if ((player weaponState "HandGrenade_Stone") # 6 == 0) then {
			if !(player getVariable ["DE_THROW_LOCK", false]) then {
				player setVariable ["DE_THROW_LOCK", true];
				private ["_acceptedMags","_playerMags","_magIndex"];
				_acceptedMags = getArray (configFile >> "cfgWeapons" >> currentWeapon player >> "magazines");
				_playerMags = magazinesAmmo player;
				_magIndex = _playerMags findIf { _acceptedMags find (_x # 0) > -1 };
				if (_magIndex > -1) then {
					player setVariable ["DE_THROWN_MAG",_playerMags # _magIndex];
					//systemChat str (_playerMags # _magIndex);
					player forceWeaponFire ["HandGrenade_Stone","HandGrenade_Stone"];
					//player removeMagazines "HandGrenade_Stone";
					player addMagazine "HandGrenade_stone";
				} else {
					systemChat "You do not have an extra magazine for this weapon";
				};
			};
		};
	};
}];

//keyup UI EH - Creates a switch. Prevents the keydown code from spamming if the player holds the key down
(findDisplay 46) displayAddEventHandler ["KeyUp", {
	if ((_this select 1) == 35) then {
		player setVariable ["DE_THROW_LOCK", false];
	};
}];

//fired EH - Does all the cool stuff
//["B Alpha 1-1:1 (DreadedEntity)", "Throw", "HandGrenade_Stone", "HandGrenade_Stone", "GrenadeHand_stone", "HandGrenade_Stone", "1779995: handgrenade.p3d"];
player addEventHandler ["Fired", {
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
	//_unit = _this select 0; _projectile = _this select 6;
	//systemChat str _this;
	//copyToClipboard str _this;
	if (_weapon == "Throw") then {
		if (_muzzle == "HandGrenade_Stone") then {
			private _thrownMag = player getVariable "DE_THROWN_MAG";
			if (!isNil "_thrownMag") then {
				//Only if all these are true can be assume mag was thrown
				private ["_pos","_vel","_mag"];
				_pos = getPosASL _projectile;
				_vel = velocity _projectile;
				deleteVehicle _projectile;
				_mag = createVehicle ["WeaponHolderSimulated", ASLToAGL _pos, [], 0, "CAN_COLLIDE"];
				_mag addMagazineAmmoCargo [_thrownMag # 0, 1, _thrownMag # 1];
				player removeMagazine (_thrownMag # 0);
				_mag setVelocity _vel;

				_id = addMissionEventHandler ["EachFrame", {
					private ["_mag","_thrownMag","_near","_manIndex"];
					_mag = _thisArgs # 0;
					_thrownMag = _thisArgs # 1;
					_near = (_mag nearEntities ["Man", 3]) select { _x != player };
					_manIndex = _near findIf { isNull objectParent _x }; //only throw to soldiers on foot :)
					//hintSilent str [_near, _manIndex];
					if (_manIndex > -1) then {
						private _unit = _near # _manIndex;
						private _mass = getNumber (configFile >> "CfgMagazines" >> _thrownMag # 0 >> "mass");
						//hintSilent str [_unit, _mass];
						if ((loadAbs _unit) + _mass <= maxLoad _unit) then { //could cause issue? uniform/vest/backpack not checked if there's actually enough space
							deleteVehicle _mag;
							_unit addMagazine [_thrownMag # 0, _thrownMag # 1];
							removeMissionEventHandler [_thisEvent, _thisEventHandler];
							systemChat "Event Handler removed";
						};
					};
					//systemChat str (speed _mag);
					if (speed _mag == 0) then {
						_mag setPosATL (ASLToATL (getPosASL _mag));
						removeMissionEventHandler [_thisEvent, _thisEventHandler];
						systemChat "Event Handler removed";
					};
				}, [_mag, _thrownMag]];
				systemChat format ["Event Handler %1 added", _id];
			};
		};

		//	_num = missionNamespace getVariable ["DE_var_throwEvents", 0]; _event = "DE_throwEvent_" + (str DE_var_throwEvents);
		//	[_event, "onEachFrame", {
		//		_near = (nearestObjects [_this select 1, ["MAN"], 3]) - [player];
		//		if (count _near > 0) then {
		//			[_this select 0, "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
		//			deleteVehicle (_this select 1);
		//			_magInfo = (_this select 1) getVariable "DE_var_magInfo";
		//			(_near select 0) addMagazine [_magInfo select 0, _magInfo select 1];
		//		};
		//		if (speed (_this select 1) == 0) then {
		//			[_this select 0, "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
		//		};
		//	}, [_event, _obj, DE_var_throwMag]] call BIS_fnc_addStackedEventHandler;
		//	DE_var_throwEvents = (missionNamespace getVariable ["DE_var_throwEvents", 0]) + 1; DE_var_throwMag = "";
		//};
	};
}];

player addAction ["Switch to cursorTarget", {
	selectPlayer cursorTarget;
}, [], 6, false, true, "", "_target != player"];

man addAction ["Switch to cursorTarget", {
	selectPlayer cursorTarget;
}, [], 6, false, true, "", "_target != player"];