///////////////////////////////////////
// Function file for Armed Assault 3 //
//     Created by: DreadedEntity     //
///////////////////////////////////////

sleep 0.1;

[] spawn {
	while {true} do {
		hintSilent str (player weaponState "HandGrenade_Stone");
	}
};

//required so the "throw" can reload, otherwise the first press won't work
player addMagazine "HandGrenade_stone";

//keydown UI EH - Adds another hotkey to the main "game" display to get the keypress
//note 35 == "H" key
(findDisplay 46) displayAddEventHandler ["KeyDown", {
	if (()player weaponState "HandGrenade_Stone") # 6 == 0) then {
		if ((_this select 1) == 35) then {
			DE_var_throwPressed = true;
			_magName = "";
			_magName = {
				_find = (getArray (configFile >> "cfgWeapons" >> currentWeapon player >> "magazines")) find _x;
				if (_find > -1) exitWith {_x};
			} count ((backpackItems player) + (vestItems player) + (uniformItems player));

			if (typeName _magName == "STRING" && {_magName != ""}) then {
				DE_var_throwMag = _magName;
				player addMagazine "HandGrenade_stone";
				player setWeaponReloadingTime [player, "HandGrenade_Stone", 0]; //this doesn't work, it would be the key to solving all of my headaches with this code
				player forceWeaponFire ["HandGrenade_Stone","HandGrenade_Stone"];
			} else {
				hint "You do not have an extra magazine for this weapon";
			}
		};
	};
}];

//keyup UI EH - Creates a switch. Prevents the keydown code from spamming if the player holds the key down
(findDisplay 46) displayAddEventHandler ["KeyUp", {
	if ((_this select 1) == 35) then {
		DE_var_throwPressed = false;
	};
}];

//fired EH - Does all the cool stuff
player addEventHandler ["Fired", {
	_unit = _this select 0; _projectile = _this select 6;
	if ((_this select 1) == "Throw") then {
		if (missionNamespace getVariable ["DE_var_throwMag", ""] != "") then {
			_pos = getPosATL _projectile; _vel = velocity _projectile; _obj = createVehicle ["WeaponHolderSimulated", _pos, [], 0, "CAN_COLLIDE"];
			_maxMagBullets = 0; _maxMagType = ""; _maxMagLocation = ""; _allMags = []; _useableMagazines = getArray (configFile >> "cfgWeapons" >> currentWeapon player >> "magazines");
			_allMags = [];
			{
				if ((_useableMagazines find (_x select 0) > -1) && {["Uniform","Vest","Backpack"] find (_x select 4) > -1) then {
					_maxMagType = _x select 0;
					_maxMagBullets = _x select 1;
					_maxMagLocation = _x select 4;
					_allMags pushBack [_maxMagType, _maxMagBullets, _maxMagLocation];
				};
			} forEach (magazinesAmmoFull player);

			player removeItem _maxMagType;
			_obj addMagazineAmmoCargo [_maxMagType, 1, _maxMagBullets];
			_obj setVariable ["DE_var_thrownMag", [_maxMagType, _maxMagBullets]];

			_obj setVelocity _vel; deleteVehicle _projectile;

			_num = missionNamespace getVariable ["DE_var_throwEvents", 0]; _event = "DE_throwEvent_" + (str DE_var_throwEvents);
			[_event, "onEachFrame", {
				_near = (nearestObjects [_this select 1, ["MAN"], 3]) - [player];
				if (count _near > 0) then {
					[_this select 0, "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
					deleteVehicle (_this select 1);
					_magInfo = (_this select 1) getVariable "DE_var_magInfo";
					(_near select 0) addMagazine [_magInfo select 0, _magInfo select 1];
				};
				if (speed (_this select 1) == 0) then {
					[_this select 0, "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
				};
			}, [_event, _obj, DE_var_throwMag]] call BIS_fnc_addStackedEventHandler;
			DE_var_throwEvents = (missionNamespace getVariable ["DE_var_throwEvents", 0]) + 1; DE_var_throwMag = "";
		};
	};
}];

["B Alpha 1-1:1 (DreadedEntity)","Throw","HandGrenade_Stone","HandGrenade_Stone","GrenadeHand_stone","HandGrenade_Stone","1779995: handgrenade.p3d"];

player addAction ["Switch to cursorTarget", {
	selectPlayer cursorTarget;
}, [], 6, false, true, "", "_target != player"];

man addAction ["Switch to cursorTarget", {
	selectPlayer cursorTarget;
}, [], 6, false, true, "", "_target != player"];