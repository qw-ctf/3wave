
// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void() player_pain;
void() player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;
string(string old) RandomLevel;
void() SpawnRunes;

float	modelindex_eyes, modelindex_player;

void() MOTD =
{
	if (self.motd_count < 5) {
		self.motd_time = time + 1;
		self.motd_count = self.motd_count + 1;
		if (teamplay & TEAM_CAPTURE_FLAG)
			if (self.steam == TEAM_COLOR1)
				centerprint(self, "Welcome!\nQuakeWorld ThreeWave CTF 1.1\n\nцаптуре тхе флаг\n\nYou are on the ред team"); //red
			else
				centerprint(self, "Welcome!\nQuakeWorld ThreeWave CTF 1.1\n\nцаптуре тхе флаг\n\nYou are on the блуе team"); //blue
		else if (teamplay)
			centerprint(self, "Welcome!\nQuakeWorld Threewave 1.1\n\nTEAMPLAY IS ACTIVE");
		else
			centerprint(self, "Welcome!\nQuakeWorld ThreeWave Server Mods");
		return;
	}
	self.motd_time = 0;
};

// ZOID: with several effects doing the dimlight thing, they just can't
// turn it off.  Do not set self.effects with EF_DIMLIGHT directly.  This
// will automatically do it when CheckPowerups is called
// EF_DIMLIGHT is used;
// 1. Invincible (Pentagram)
// 2. Super Damage (Quad Power)
// 3. Having Flag in Capture
// self is player
void () CheckDimLight = {
	local float flag;

	flag = 0;
	// invincable
	if (self.invincible_finished > time)
		flag = 1;
	// quad
	if (self.super_damage_finished > time)
		flag = 1;
	// flag
//	if (self.player_flag & ITEM_ENEMY_FLAG)
//		flag = 1;

	if (flag)
		self.effects = self.effects | EF_DIMLIGHT;
	else
		self.effects = self.effects - (self.effects & EF_DIMLIGHT);
};

/*
=============================================================================

				LEVEL CHANGING / INTERMISSION

=============================================================================
*/

string nextmap;

float	intermission_running;
float	intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
};



void() SetChangeParms =
{
	if (self.health <= 0)
	{
		SetNewParms ();
		return;
	}

// remove items
	self.items = self.items - (self.items &
	(IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD) );

// cap super health
	if (self.health > 100)
		self.health = 100;
	if (self.health < 50)
		self.health = 50;
	if (teamplay & TEAM_CAPTURE_FLAG) // don't carry items between levels in CTF
		SetNewParms();
	else {
		parm1 = self.items;
		parm2 = self.health;
		parm3 = self.armorvalue;
		if (self.ammo_shells < 25)
			parm4 = 25;
		else
			parm4 = self.ammo_shells;
		parm5 = self.ammo_nails;
		parm6 = self.ammo_rockets;
		parm7 = self.ammo_cells;
		parm8 = self.weapon;
		parm9 = self.armortype * 100;
	}
// *TEAMPLAY*
	parm10 = self.steam; // Save the current team of the player
	parm16 = self.player_flag;
};

void() SetNewParms =
{
        parm1 = IT_SHOTGUN | IT_AXE | IT_GRAPPLE;
	parm2 = 100;
	if (teamplay & TEAM_CAPTURE_FLAG) {
		parm3 = 50;
		parm9 = 30;
		parm1 = parm1 + IT_ARMOR1;
	} else {
	parm3 = 0;
		parm9 = 0;
	}
	parm4 = 40;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = IT_SHOTGUN;
// *TEAMPLAY*
	parm10 = -1;	// Reset
	parm16 = 0;
};

void() DecodeLevelParms =
{
	self.player_flag = self.player_flag | parm16;
	self.player_flag = self.player_flag - (self.player_flag & ITEM_RUNE_MASK);
	self.player_flag = self.player_flag - (self.player_flag & ITEM_ENEMY_FLAG);

	self.ctfskinno = (self.player_flag & 65280) / 256;
	TeamSkinSet();

	if (serverflags)
	{
                if (world.model == "maps/start.bsp")
			SetNewParms ();		// take away all stuff on starting new episode
	}

	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells = parm4;
	self.ammo_nails = parm5;
	self.ammo_rockets = parm6;
	self.ammo_cells = parm7;
	self.weapon = parm8;
	self.armortype = parm9 * 0.01;

	// *XXX* EXPERT CTF

	// Reset times for additional scoring system on level change and server join
	// dprint("decode level parms\n");
	self.last_returned_flag = -10;
	self.last_fragged_carrier = -10;
	self.flag_since = -10;
	self.last_hurt_carrier = -10;

// *TEAMPLAY*
	if (TeamColorIsLegal(parm10))
		self.steam = parm10;
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
	local	entity spot;
	local	float cyc;

// look for info_intermission first
	spot = find (world, classname, "info_intermission");
	if (spot)
	{	// pick a random one
		cyc = random() * 4;
		while (cyc > 1)
		{
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

// then look for the start position
	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;

	objerror ("FindIntermission: no spot");
};


void() GotoNextMap =
{
//ZOID: We're overloading samelevel for use for map checking
//	if (cvar("samelevel"))	// if samelevel is set, stay on same level
//		changelevel (mapname);
//	else
		changelevel (nextmap);
};



/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!self.button0 && !self.button1 && !self.button2)
		return;

	GotoNextMap ();
};

/*
============
execute_changelevel

The global "nextmap" has been set previously.
Take the players to the intermission spot
============
*/
void() execute_changelevel =
{
	local entity	pos;

	intermission_running = 1;

// enforce a wait time before allowing changelevel
	intermission_exittime = time + 8;

	pos = FindIntermission ();

// play intermission music
	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, 3);

	WriteByte (MSG_ALL, SVC_INTERMISSION);
	WriteCoord (MSG_ALL, pos.origin_x);
	WriteCoord (MSG_ALL, pos.origin_y);
	WriteCoord (MSG_ALL, pos.origin_z);
	WriteAngle (MSG_ALL, pos.mangle_x);
	WriteAngle (MSG_ALL, pos.mangle_y);
	WriteAngle (MSG_ALL, pos.mangle_z);

	other = find (world, classname, "player");
	while (other != world)
	{
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		other = find (other, classname, "player");
	}

};


void() changelevel_touch =
{
	local entity	pos;

	if (other.classname != "player")
		return;

// if "noexit" is set, blow up the player trying to leave
	if (teamplay & TEAM_CAPTURE_FLAG)
		return;

	if ((cvar("samelevel") == 2) || ((cvar("samelevel") == 3) && (mapname != "start")))
	{
		T_Damage (other, self, self, 50000);
		return;
	}

	bprint (PRINT_HIGH, other.netname);
	bprint (PRINT_HIGH," exited the level\n");

	nextmap = self.map;

	SUB_UseTargets ();

	self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("chagnelevel trigger doesn't have map");

	InitTrigger ();
	self.touch = changelevel_touch;
};


/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
	// make a copy of the dead body for appearances sake
	CopyToBodyQue (self);
	// set default spawn parms
	SetNewParms ();
	// respawn
	PutClientInServer ();
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
	if (self.suicide_count > 3) {
		sprint(self, PRINT_HIGH, "You have suicided too much already.\n");
		return;
	}
	bprint (PRINT_MEDIUM, self.netname);
	bprint (PRINT_MEDIUM, " suicides\n");
	DropRune();
    TeamCaptureDropFlagOfPlayer(self);
	set_suicide_frame ();
	self.modelindex = modelindex_player;
	logfrag (self, self);
	self.frags = self.frags - 2;	// extra penalty
	self.suicide_count = self.suicide_count + 1;
	respawn ();
};

float(vector v) CheckSpawnPoint =
{
	return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
	local	entity spot, thing;
	local	float	pcount;

// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

// choose a info_player_deathmatch point
//CTF spawns
	if (!self.killed) {
		spot = TeamCaptureSpawn();
 		if (spot != world)
 			return spot;
	}
	lastspawn = find(lastspawn, classname, "info_player_deathmatch");
	if (lastspawn == world)
		lastspawn = find (lastspawn, classname, "info_player_deathmatch");
	if (lastspawn != world)
		return lastspawn;

	spot = find (world, classname, "info_player_start");
	if (!spot)
		error ("PutClientInServer: no info_player_start on level");

	return spot;
};

void() DecodeLevelParms;
void() PlayerDie;

/*
===========
ValidateUser


============
*/
float(entity e) ValidateUser =
{
/*
	local string	s;
	local string	userclan;
	local float	rank, rankmin, rankmax;

//
// if the server has set "clan1" and "clan2", then it
// is a clan match that will allow only those two clans in
//
	s = serverinfo("clan1");
	if (s)
	{
		userclan = masterinfo(e,"clan");
		if (s == userclan)
			return true;
		s = serverinfo("clan2");
		if (s == userclan)
			return true;
		return false;
	}

//
// if the server has set "rankmin" and/or "rankmax" then
// the users rank must be between those two values
//
	s = masterinfo (e, "rank");
	rank = stof (s);

	s = serverinfo("rankmin");
	if (s)
	{
		rankmin = stof (s);
		if (rank < rankmin)
			return false;
	}
	s = serverinfo("rankmax");
	if (s)
	{
		rankmax = stof (s);
		if (rankmax < rank)
			return false;
	}

	return true;
*/
};


/*
===========
PutClientInServer

called each time a player enters a new level
============
*/
void() PutClientInServer =
{
	local	entity spot;

	self.classname = "player";
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;
	self.staydeadtime = 0;
	self.regen_time = 0;
	self.rune_notice_time = 0;

	self.last_hurt_carrier = -10;

	DecodeLevelParms ();

	spot = SelectSpawnPoint ();
//ZOID: Minimize chance of telefragging someone, from Johannes Plass
//(plass@dipmza.physik.uni-mainz.de) ServerModules package
	spot = TelefragSelectSpawnPoint(spot);

	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;

	self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;

//	spot = SelectSpawnPoint ();


	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately

// oh, this is a hack!
	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/player.mdl");

	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';

	player_stand1 ();

	makevectors(self.angles);
	spawn_tfog (self.origin + v_forward*20);

	spawn_tdeath (self.origin, self);


        // grapple stuff
        self.on_hook = FALSE;
        self.hook_out = FALSE;
        self.fire_held_down = FALSE;
};


/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
	local entity rspawn;

	// spawn the runes
	rspawn = spawn();
	rspawn.nextthink = time + 0.1;
	rspawn.think = SpawnRunes;
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
*/
void() NextLevel =
{
	local entity o;

	if (teamplay & TEAM_CAPTURE_FLAG) {
		o = spawn();
		o.map = RandomLevel(mapname);
	} else {
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");
		if (!o || mapname == "start")
		{	// go back to same map if no trigger_changelevel
			o = spawn();
			o.map = mapname;
		}
	}

	nextmap = o.map;

	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}

	if (!intermission_running)
		intermission_running = -1;
};

// Return a new random level, that doesn't match old

// Rewriten for CTF
// uses the server temp1 cvar for level tracking
// temp1 is mapped out as:
//  bit 16 to 12 for id level num 0xf800, 63488
//  bit 11 to 7 for Custom level num 0x0f80, 3968
//  bit 6 to 0 for percent of custom CTF levels 0x007f, 127
// server ops should just set temp1 to the percent and the start id/ctf
// levels will be zero (first level)
// 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536
// ---------------- --------------------- ---------------------------
// x x x x  x  x  x
//                  x   x   x   x    x
//                                        x    x    x     x     x
//
string(string old) RandomLevel =
{
local float r;
local float idlvl, ctflvl;
local float percent;
local string smap;
local string s;

	r = random();
	if (teamplay & TEAM_CAPTURE_FLAG) {
		// extract stuff from temp1
		percent = cvar("samelevel") & 127;
		idlvl = (cvar("samelevel") & 3968) / 128;
		ctflvl = (cvar("samelevel") & 126976) / 4096;

		if ((random() < percent / 100.0)) {
			ctflvl = ctflvl + 1;
			if (ctflvl == 1) smap = "ctf2";
			else if (ctflvl == 2) smap = "ctf3";
			else if (ctflvl == 3) smap = "ctf4";
			else if (ctflvl == 4) smap = "ctf5";
			else if (ctflvl == 5) smap = "ctf6";
			else if (ctflvl == 6) smap = "ctf7";
			else if (ctflvl == 7) smap = "ctf8";
			else {
				smap = "ctf1";
				ctflvl = 0;
			}
		} else {
			// capture levels
			idlvl = idlvl + 1;
			if (idlvl == 1) smap = "e1m2";
			else if (idlvl == 2) smap = "e1m3";
			else if (idlvl == 3) smap = "e1m4";
			else if (idlvl == 4) smap = "e1m5";
			else if (idlvl == 5) smap = "e1m6";
			else if (idlvl == 6) smap = "e1m8";
			else if (idlvl == 7) smap = "e2m1";
			else if (idlvl == 8) smap = "e2m2";
			else if (idlvl == 9) smap = "e2m3";
			else if (idlvl == 10) smap = "e2m5";
			else if (idlvl == 11) smap = "e4m3";
			else if (idlvl == 12) smap = "e4m4";
			else if (idlvl == 13) smap = "e4m5";
			else if (idlvl == 14) smap = "e4m6";
			else if (idlvl == 15) smap = "dm3";
			else if (idlvl == 16) smap = "dm6";
			else {
				smap = "e1m1";
				idlvl = 0;
			}
		}
		// recombine the cvar
		s = ftos(ctflvl * 4096 + idlvl * 128 + percent);
		cvar_set("samelevel", s);
		return smap;
	}
	if (r > 0.8) {
		r = random() * 7;
		if ((r >= 6) && (old != "e1m1")) return ("e1m1"); // e1m1: Slipgate Complex -- by John Romero
		if ((r >= 5) && (old != "e1m2")) return ("e1m2"); // e1m2: Castle of the Damned -- by Tim Willits
		if ((r >= 4) && (old != "e1m3")) return ("e1m3"); // e1m3: The Necropolis -- by Tim Willits
		if ((r >= 3) && (old != "e1m4")) return ("e1m4"); // e1m4: The Grisly Grotto -- by Tim Willits
		if ((r >= 2) && (old != "e1m5")) return ("e1m5"); // e1m5: Gloom Keep -- by Tim Willits
		if ((r >= 1) && (old != "e1m6")) return ("e1m6"); // e1m6: The Door To Chthon -- by American McGee
// e1m7: The House of Chthon -- removed because of lag problems
		return ("e1m8"); // e1m8: Ziggurat Vertigo --by American McGee
	} else if (r > 0.6) {
		r = random() * 6;
		if ((r >= 5) && (old != "e2m1")) return ("e2m1"); // e2m1: The Installation -- by John Romero
		if ((r >= 4) && (old != "e2m2")) return ("e2m2"); // e2m2: Ogre Citadel -- by John Romero
		if ((r >= 3) && (old != "e2m3")) return ("e2m3"); // e2m3: Crypt of Decay -- by John Romero
		if ((r >= 2) && (old != "e2m4")) return ("e2m4"); // e2m4: The Ebon Fortress  -- by John Romero
		if ((r >= 1) && (old != "e2m5")) return ("e2m5"); // e2m5: The Wizard's Manse -- by John Romero
// e2m6: The Dismal Oubliette -- removed because it sucks for dm
		return ("e2m7"); // e2m7: Underearth --by Tim Willits
	} else if (r > 0.4) {
		r = random() * 6;
		if ((r >= 5) && (old != "e3m1")) return ("e3m1"); // e3m1: Termination Central -- by John Romero
		if ((r >= 4) && (old != "e3m2")) return ("e3m2"); // e3m2: The Vaults of Zin -- by American McGee
		if ((r >= 3) && (old != "e3m3")) return ("e3m3"); // e3m3: The Tomb of Terror -- by American McGee
// e3m4 (Satan's Dark Delight) removed because it sucks for dm
		if ((r >= 2) && (old != "e3m5")) return ("e3m5"); // e3m5: Wind Tunnels --by Tim Willits
		if ((r >= 1) && (old != "e3m6")) return ("e3m6"); // e3m6: Chambers of Torment -- by American McGee & Tim Willits
		return ("e3m7"); // e3m7: The Haunted Halls -- by American McGee
	} else if (r > 0.2) {
		r = random() * 8;
		if ((r >= 7) && (old != "e4m1")) return ("e4m1"); // e4m1: The Sewage System -- by Tim Willits
		if ((r >= 6) && (old != "e4m2")) return ("e4m2"); // e4m2: The Tower of Despair --by Sandy Petersen
		if ((r >= 5) && (old != "e4m3")) return ("e4m3"); // e4m3: The Elder God Shrine --by Sandy Petersen
		if ((r >= 4) && (old != "e4m4")) return ("e4m4"); // e4m4: The Palace of Hate --by Sandy Petersen
		if ((r >= 3) && (old != "e4m5")) return ("e4m5"); // e4m5: Hell's Atrium --by Sandy Petersen
		if ((r >= 2) && (old != "e4m6")) return ("e4m6"); // e4m6: The Pain Maze --by Sandy Petersen
		if ((r >= 1) && (old != "e4m7")) return ("e4m7"); // e4m7: Azure Agony --by Sandy Petersen
		return ("e4m8"); // e4m8: The Nameless City -- by Sandy Petersen
	} else {
		r = random() * 6;
		if ((r >= 5) && (old != "dm1")) return ("dm1"); // dm1: Place of Two Deaths --by Tim Willits
		if ((r >= 4) && (old != "dm2")) return ("dm2"); // dm2: Claustrophobopolis --by American McGee
		if ((r >= 3) && (old != "dm3")) return ("dm3"); // dm3: The Abandoned Base --by John Romero
		if ((r >= 2) && (old != "dm4")) return ("dm4"); // dm4: The Bad Place --by American McGee
		if ((r >= 1) && (old != "dm5")) return ("dm5"); // dm5: The Cistern --by Tim Willits
		return ("dm6"); // dm6: The Dark Zone --by Tim Willits
	}
	return("start");
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
 	local	entity	p;
 	local	float	total1, total2;
	local	string	s;

	if (intermission_running)
		return;

//	if (timelimit && time >= timelimit)
//		NextLevel ();
//
//	if (fraglimit && self.frags >= fraglimit)
//		NextLevel ();

	if ((timelimit && time >= timelimit) ||
		(fraglimit && (self.frags >= fraglimit))) {
		if (teamplay & TEAM_CAPTURE_FLAG) {
			// count up total
			total1 = total2 = 0;
			p = find(world, classname, "player");
			while (p != world) {
				if (p.steam == TEAM_COLOR1)
					total1 = total1 + p.frags;
				else if (p.steam == TEAM_COLOR2)
					total2 = total2 + p.frags;
				p = find(p, classname, "player");
			}

			if (total1 > total2) {
				bprint(PRINT_HIGH, "ред team won the level with ");
				s = ftos(total1);
				bprint(PRINT_HIGH, s);
				bprint(PRINT_HIGH, " points!\n");
				bprint(PRINT_HIGH, "блуе team lost with ");
				s = ftos(total2);
				bprint(PRINT_HIGH, s);
				bprint(PRINT_HIGH, " points.\n");
			} else if (total1 < total2) {
				bprint(PRINT_HIGH, "блуе team won the level with ");
				s = ftos(total1);
				bprint(PRINT_HIGH, s);
				bprint(PRINT_HIGH, " points!\n");
				bprint(PRINT_HIGH, "ред team lost with ");
				s = ftos(total2);
				bprint(PRINT_HIGH, s);
				bprint(PRINT_HIGH, " points.\n");
			} else {
				bprint(PRINT_HIGH, "блуе and ред team tied level with ");
				s = ftos(total1);
				bprint(PRINT_HIGH, s);
				bprint(PRINT_HIGH, " points!\n");
			}
		}

		NextLevel ();
  		return;
  	}

	// update team scores?
	TeamCaptureCheckUpdate();
};

//============================================================================

void() PlayerDeathThink =
{
	local entity	old_self;
	local float		forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else
			self.velocity = forward * normalize(self.velocity);
	}

// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

// wait for any button down
	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn();
};


void() PlayerJump =
{
	local vector start, end;

	if (self.flags & FL_WATERJUMP)
		return;

	if (self.waterlevel >= 2)
	{
// play swiming sound
		if (self.swim_flag < time)
		{
			self.swim_flag = time + 1;
			if (random() < 0.5)
                                sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.button2 = 0;

// player jumping sound
	sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
};


/*
===========
WaterMove

============
*/
.float	dmgtime;

void() WaterMove =
{
//dprint (ftos(self.waterlevel));
	if (self.movetype == MOVETYPE_NOCLIP)
		return;
	if (self.health < 0)
		return;

	if (self.waterlevel != 3)
	{
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		self.air_finished = time + 12;
		self.dmg = 2;
	}
	else if (self.air_finished < time)
	{	// drown!
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 2;
			if (self.dmg > 15)
				self.dmg = 10;
			T_Damage (self, world, world, self.dmg);
			self.pain_finished = time + 1;
		}
	}

	if (!self.waterlevel)
	{
		if (self.flags & FL_INWATER)
		{
			// play leave water sound
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{	// do damage
		if (self.dmgtime < time)
		{
			if (self.radsuit_finished > time)
				self.dmgtime = time + 1;
			else
				self.dmgtime = time + 0.2;

			T_Damage (self, world, world, 10*self.waterlevel);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{	// do damage
		if (self.dmgtime < time && self.radsuit_finished < time)
		{
			self.dmgtime = time + 1;
			T_Damage (self, world, world, 4*self.waterlevel);
		}
	}

	if ( !(self.flags & FL_INWATER) )
	{

// player enter water sound

		if (self.watertype == CONTENT_LAVA)
			sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_SLIME)
			sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

		self.flags = self.flags + FL_INWATER;
		self.dmgtime = 0;
	}
};

void() CheckWaterJump =
{
	local vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.flags = self.flags | FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}

};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
	local	float	mspeed, aspeed;
	local	float	r;

	if (intermission_running > 0)
	{
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

	makevectors (self.v_angle);		// is this still used

	if (self.motd_time && self.motd_time < time)
		MOTD();

	CheckRules ();
	WaterMove ();

// *TEAMPLAY*
// TeamCheckLock performs all necessary teamlock checking, and performs all
// actions needed.
	TeamCheckLock();

/*
	if (self.waterlevel == 2)
		CheckWaterJump ();
*/

	if (self.deadflag >= DEAD_DEAD)
	{
		PlayerDeathThink ();
		return;
	}

	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing

	if (self.button2)
	{
		PlayerJump ();
	}
	else
		self.flags = self.flags | FL_JUMPRELEASED;

// teleporters can force a non-moving pause time
	if (time < self.pausetime)
		self.velocity = '0 0 0';

// RUNE: If player has rune of elder magic (4), regeneration
	if (self.player_flag & ITEM_RUNE4_FLAG) {
		if (self.health < 100 && self.regen_time < time) {
			self.health = self.health + 2;
			self.regen_time = time + 0.5;
			RegenerationSound();
		}
	}
// RUNE

	if(time > self.attack_finished && self.currentammo == 0 &&
                self.weapon != IT_AXE && self.weapon != IT_GRAPPLE)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
	}

        // Do grapple stuff if I'm on a hook
        if (self.on_hook)
                Service_Grapple ();

};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
	if (self.health <= 0)
		return;

// invisibility
	if (self.invisible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invisible_sound < time)
		{
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random() * 3) + 1);
		}

		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				sprint (self, PRINT_HIGH, "Ring of Shadows magic is fading\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}

			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVISIBILITY;
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}

	// use the eyes
		self.frame = 0;
		self.modelindex = modelindex_eyes;
	}
	else
		self.modelindex = modelindex_player;	// don't use eyes

// invincibility
	if (self.invincible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				sprint (self, PRINT_HIGH, "Protection is almost burned out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}

			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invincible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVULNERABILITY;
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}
// ZOID, next line isn't needed, EF_DIMLIGHT is handled by
// client.qc:CheckDimLight
//		if (self.invincible_finished > time)
//			self.effects = self.effects | EF_DIMLIGHT;
//		else
//			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	}

// super damage
	if (self.super_damage_finished)
	{

// sound and screen flash when items starts to run out

		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
				sprint (self, PRINT_HIGH, "Quad Damage is wearing off\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}

			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{	// just stopped
			self.items = self.items - IT_QUAD;
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
// ZOID, next line isn't needed, EF_DIMLIGHT is handled by
// client.qc:CheckDimLight
//		if (self.super_damage_finished > time)
//			self.effects = self.effects | EF_DIMLIGHT;
//		else
//			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	}

// suit
	if (self.radsuit_finished)
	{
		self.air_finished = time + 12;		// don't drown

// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				sprint (self, PRINT_HIGH, "Air supply in Biosuit expiring\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}

			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{	// just stopped
			self.items = self.items - IT_SUIT;
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}

	// Check to see about DIMLIGHT effects
	CheckDimLight();
};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{
	local	float	mspeed, aspeed;
	local	float	r;

//dprint ("post think\n");
	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale
	if (self.deadflag)
		return;

// check to see if player landed and play landing sound
	if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) )
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
			T_Damage (self, world, world, 5);
			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
			self.deathtype = "falling";
		}
		else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
	}

	self.jump_flag = self.velocity_z;

	CheckPowerups ();

	W_WeaponFrame ();

};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
	bprint (PRINT_HIGH, self.netname);
	bprint (PRINT_HIGH, " entered the game\n");

	self.motd_time = time + 3;
	self.motd_count = 0;
	self.player_flag = self.player_flag - (self.player_flag & PF_GHOST);

	self.suicide_count = 0;
	self.killed = 0;
	self.player_flag = 0;

// *TEAMPLAY*
 	// If this is our first connection, parm10 is < 0
 	// Set lastteam negative.
 	if (parm10 < 0 || self.steam < 0) {
 		self.steam = -1;
		TeamAssign();
        if(teamplay & TEAM_LOCK_COLORS) // force a stuff cmd in think
			self.player_flag = self.player_flag | TEAM_STUFF_COLOR;
	}


// a client connecting during an intermission can cause problems
	if (intermission_running)
		GotoNextMap ();
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	// let everyone else know
	bprint (PRINT_HIGH, self.netname);
	bprint (PRINT_HIGH, " left the game with ");
	bprint (PRINT_HIGH, ftos(self.frags));
	bprint (PRINT_HIGH, " frags\n");
	sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
	DropRune();
    TeamCaptureDropFlagOfPlayer(self);
	set_suicide_frame ();

	self.player_flag = self.player_flag | PF_GHOST;
	self.steam = -1;
};

// *TEAMPLAY*
// Prototypes

float(entity targ, entity attacker) TeamFragPenalty;
void(entity targ, entity attacker) TeamDeathPenalty;

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker) ClientObituary =
{

	// *XXX* EXPERT CTF variable for
	// flag/flag carrier defense bonus determination
	local	entity head;
	local float flag_radius;
	local float flag_carrier_radius;

        local   float rnum, temp;
	local	string deathstring, deathstring2, s;
	rnum = random();

	if (targ.classname == "player")
	{

		// *XXX* EXPERT CTF:
		// When the flag carrier dies, reset the last_hurt_carrier field in
		// all players on the opposite team from the flag carrier.  The carrier
		// has been killed, so there is no longer a reason to award points for
		// killing off his assailants
		if (targ.player_flag & ITEM_ENEMY_FLAG) {

			head = find(world, classname, "player");

			while (head != world) {
				if (head.steam != targ.steam)
					head.last_hurt_carrier = -10;
				head = find(head, classname, "player");
			}
		}
		// END EXPERT CTF

		if (attacker.classname == "teledeath")
		{
			bprint (PRINT_MEDIUM,targ.netname);
			bprint (PRINT_MEDIUM," was telefragged by ");
			bprint (PRINT_MEDIUM,attacker.owner.netname);
			bprint (PRINT_MEDIUM,"\n");

			attacker.owner.frags = attacker.owner.frags + 1;
			return;
		}

		if (attacker.classname == "teledeath2")
		{
			bprint (PRINT_MEDIUM,"Satan's power deflects ");
			bprint (PRINT_MEDIUM,targ.netname);
			bprint (PRINT_MEDIUM,"'s telefrag\n");

			targ.frags = targ.frags - 1;
			logfrag (targ, targ);
			return;
		}

		if (attacker.classname == "player")
		{
			if (targ == attacker)
			{
				// killed self
				logfrag (attacker, attacker);
				attacker.frags = attacker.frags - 1;
				bprint (PRINT_MEDIUM,targ.netname);

				if (targ.weapon == 64 && targ.waterlevel > 1)
				{
					bprint (PRINT_MEDIUM," discharges into the water.\n");
					return;
				}
				if (targ.weapon == IT_GRENADE_LAUNCHER) {
					bprint (PRINT_MEDIUM," tries to put the pin back in\n");
				} else if (rnum) {
					bprint (PRINT_MEDIUM," becomes bored with life\n");
				} else if (targ.steam != targ.steam) {
					//ZOID: try if player was gibbed for changing teams
					if (teamplay & TEAM_STATIC_TEAMS)
						bprint (PRINT_MEDIUM, " tried to change teams\n");
					else
						bprint (PRINT_MEDIUM, " changed teams\n");
				} else {
					bprint (PRINT_MEDIUM," checks if his weapon is loaded\n");
				}
				return;
			}
			else
			{
 				// *TEAMPLAY*
 				// TeamFragPenalty returns true if the attacker gets a frag penalty for
 				// killing this target.  It also deducts frags as needed.
 				if (!TeamFragPenalty(targ, attacker)) {

 					// the attacker is award the normal one frag.. now we
 					// determine if he gets any bonuses
					logfrag (attacker, targ);
   					attacker.frags = attacker.frags + 1;

 					if ((targ.player_flag & ITEM_ENEMY_FLAG) &&
 						(targ.steam != attacker.steam)) {
 						//ZOID: one team fragged the other team's flag carrier

 						// *XXX* EXPERT CTF
 						// Mark the attacker with the time at which he killed the flag
 						// carrier, for awarding assist points

 						attacker.last_fragged_carrier = time;

 						// *XXX* EXPERT CTF: give player only the normal amount of frags
 						// if the carrier has only had the flag for a few seconds, to
 						// prevent ppl intentionally allowing enemies to grab the flag,
 						// then immediately fragging them

 						if (targ.flag_since + TEAM_CAPTURE_CARRIER_FLAG_SINCE_TIMEOUT > time) {
 							sprint(attacker, PRINT_MEDIUM, "Enemy flag carrier killed, no bonus\n");
 						} else {
 							attacker.frags = attacker.frags + TEAM_CAPTURE_FRAG_CARRIER_BONUS;
 							sprint(attacker, PRINT_MEDIUM, "Enemy flag carrier killed: ");
 							s = ftos(TEAM_CAPTURE_FRAG_CARRIER_BONUS);
 							sprint(attacker, PRINT_MEDIUM, s);
 							sprint(attacker, PRINT_MEDIUM, " bonus frags\n");
 						}
 						// END FLAG CARRIER FRAG CODE
 					}

 					// *XXX* EXPERT CTF
 					// This code checks for all game-critical kills OTHER THAN fragging the enemy
 					// flag carrier, like killing players who are trying to kill your flag carrier
 					// or trying to grab your flag, and hands out bonus frags.

 					// The two variables below track whether special bonus frags have already
 					// been awarded for the attacker or target being near the flag or flag carrier.

 					flag_radius = 0;
 					flag_carrier_radius = 0;

 					// get a string for the attacker's team now, for later announcements
 					s = GetCTFTeam(attacker.steam);

 					if ((targ.last_hurt_carrier + TEAM_CAPTURE_CARRIER_DANGER_PROTECT_TIMEOUT > time) &&
 					    !(attacker.player_flag & ITEM_ENEMY_FLAG) ) {
 						// a player on the same team as the flag carrier killed
 						// someone who recently shot the flag carrier
 						attacker.frags = attacker.frags +
 							TEAM_CAPTURE_CARRIER_DANGER_PROTECT_BONUS;
 						flag_carrier_radius = 1;
 						// NOTE: getting CARRIER_DANGER_PROTECT_BONUS precludes getting
 						// other kinds of bonuses for defending the flag carrier, since
 						// it's worth more points
 						bprint(PRINT_MEDIUM, attacker.netname);
 						bprint(PRINT_MEDIUM, " defends ");
 						bprint(PRINT_MEDIUM, s);
 						bprint(PRINT_MEDIUM, "'s flag carrier against an agressive enemy\n");
 					}

 					// *XXX* EXPERT CTF
 					// Bonusus for defending the flag carrier or the flag itself.
 					// Extra frags are awarded if either the attacker or the target are
 					// 1. within 40 feet of a flag carrier on the same team as the attacker
 					// 2. within 40 feet of the attacker's flag
 					// These bonuses are cumulative with respect to defending both the
 					// flag and the flag carrier at the same time, but not cumulative with
 					// respect to both the target and attacker being near the object being defended

 					// find flags or flag carriers within a radius of the attacker
 					head = findradius(attacker.origin, TEAM_CAPTURE_ATTACKER_PROTECT_RADIUS);

 					while (head) {
 						if (head.classname == "player") {
 							if ( (head.steam == attacker.steam) &&
 							     (head.player_flag & ITEM_ENEMY_FLAG) &&
 							     (head != attacker) && // self defense
 							     (!flag_carrier_radius) ) {
								// attacker was near his own flag carrier
 								attacker.frags = attacker.frags +
 									TEAM_CAPTURE_CARRIER_PROTECT_BONUS;
 								flag_carrier_radius = 1;
 								bprint(PRINT_MEDIUM, attacker.netname);
 								bprint(PRINT_MEDIUM, " defends ");
 								bprint(PRINT_MEDIUM, s);
 								bprint(PRINT_MEDIUM, "'s flag carrier\n");
 							}
 						}
 						if ( (head.classname == "item_flag_team1") ||
 						     (head.classname == "item_flag_team2")) {
 							if (((attacker.steam == TEAM_COLOR1) &&
								(head.classname == "item_flag_team1")) ||
 								((attacker.steam == TEAM_COLOR2) &&
 								(head.classname == "item_flag_team2"))) {
								// attacker was near his own flag
 								attacker.frags = attacker.frags +
 									TEAM_CAPTURE_FLAG_DEFENSE_BONUS;
 								flag_radius = 1;
 								bprint(PRINT_MEDIUM, attacker.netname);
 								bprint(PRINT_MEDIUM, " defends the ");
 								bprint(PRINT_MEDIUM, s);
 								bprint(PRINT_MEDIUM, " flag\n");
 							}
 						}
 						head = head.chain;
 					}

 					// find flags or flag carriers within a radius from the target
 					head = findradius(targ.origin, TEAM_CAPTURE_TARGET_PROTECT_RADIUS);
 					while (head) {
 						if (head.classname == "player") {
 							if ( (head.steam == attacker.steam) &&
 							     (head.player_flag & ITEM_ENEMY_FLAG) &&
 							     (head != attacker) &&
 							     (!flag_carrier_radius)) { // prevents redundant points awarded
 								// target was near attacker's flag carrier
 								attacker.frags = attacker.frags +
 									TEAM_CAPTURE_CARRIER_PROTECT_BONUS;
 								flag_carrier_radius = 1;
 								bprint(PRINT_MEDIUM, attacker.netname);
 								bprint(PRINT_MEDIUM, " defends ");
 								bprint(PRINT_MEDIUM, s);
 								bprint(PRINT_MEDIUM, "'s flag carrier\n");
 							}
 						}
						if (((attacker.steam == TEAM_COLOR1) &&
							(head.classname == "item_flag_team1")) ||
							((attacker.steam == TEAM_COLOR2) &&
							(head.classname == "item_flag_team2"))
							&& (!flag_radius)) { // prevents redundant points awarded
							// target was near attacker's flag
							attacker.frags = attacker.frags +
								TEAM_CAPTURE_FLAG_DEFENSE_BONUS;
							flag_radius = 1;
							bprint(PRINT_MEDIUM, attacker.netname);
							bprint(PRINT_MEDIUM, " defends the ");
							bprint(PRINT_MEDIUM, s);
							bprint(PRINT_MEDIUM, " flag\n");
						}
 						head = head.chain;
 					}
 				}

 				// *XXX* EXPERT CTF
 				// End frag determination code.  Now determine death text for
 				// a member of one team killing a member of the other

 				// *TEAMPLAY*
 				// TeamDeathPenalty kills the attacker if necessary and adjusts frags to
 				// offset the one frag penalty for dying.
				TeamDeathPenalty(targ, attacker);

				rnum = attacker.weapon;
				if (rnum == IT_AXE)
				{
					deathstring = " was ax-murdered by ";
					deathstring2 = "\n";
				}
                                if (rnum == IT_GRAPPLE)
				{
                                        temp = random();
                                        if (temp < 0.5)
                                        {
                                                deathstring = " was hooked by ";
                                                deathstring2 = "\n";
                                        }
                                        else if (temp > 0.5)
                                        {
                                                deathstring = " was disemboweled by ";
                                                deathstring2 = "\n";
                                        }
        			}
				if (rnum == IT_SHOTGUN)
				{
					deathstring = " chewed on ";
					deathstring2 = "'s boomstick\n";
				}
				if (rnum == IT_SUPER_SHOTGUN)
				{
					deathstring = " ate 2 loads of ";
					deathstring2 = "'s buckshot\n";
				}
				if (rnum == IT_NAILGUN)
				{
					deathstring = " was nailed by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_SUPER_NAILGUN)
				{
					deathstring = " was punctured by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_GRENADE_LAUNCHER)
				{
					deathstring = " eats ";
					deathstring2 = "'s pineapple\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s grenade\n";
					}
				}
				if (rnum == IT_ROCKET_LAUNCHER)
				{
					if (attacker.items & IT_QUAD) {
						deathstring = " was destroyed by ";
						deathstring2 = "'s Quad rocket\n";
					} else {
						deathstring = " rides ";
						deathstring2 = "'s rocket\n";
						if (targ.health < -40)
						{
							deathstring = " was gibbed by ";
							deathstring2 = "'s rocket\n" ;
						}
					}
				}
				if (rnum == IT_LIGHTNING)
				{
					deathstring = " accepts ";
					if (attacker.waterlevel > 1)
						deathstring2 = "'s discharge\n";
					else
						deathstring2 = "'s shaft\n";
				}
				bprint (PRINT_MEDIUM,targ.netname);
				bprint (PRINT_MEDIUM,deathstring);
				bprint (PRINT_MEDIUM,attacker.netname);
				bprint (PRINT_MEDIUM,deathstring2);
			}
			return;
		}
		else
		{
			logfrag (targ, targ);
			targ.frags = targ.frags - 1;		// killed self
			rnum = targ.watertype;

			bprint (PRINT_MEDIUM,targ.netname);
			if (rnum == -3)
			{
				if (random() < 0.5)
					bprint (PRINT_MEDIUM," sleeps with the fishes\n");
				else
					bprint (PRINT_MEDIUM," sucks it down\n");
				return;
			}
			else if (rnum == -4)
			{
				if (random() < 0.5)
					bprint (PRINT_MEDIUM," gulped a load of slime\n");
				else
					bprint (PRINT_MEDIUM," can't exist on slime alone\n");
				return;
			}
			else if (rnum == -5)
			{
				if (targ.health < -15)
				{
					bprint (PRINT_MEDIUM," burst into flames\n");
					return;
				}
				if (random() < 0.5)
					bprint (PRINT_MEDIUM," turned into hot slag\n");
				else
					bprint (PRINT_MEDIUM," visits the Volcano God\n");
				return;
			}

			if (attacker.flags & FL_MONSTER)
			{
				if (attacker.classname == "monster_army")
					bprint (PRINT_MEDIUM," was shot by a Grunt\n");
				if (attacker.classname == "monster_demon1")
					bprint (PRINT_MEDIUM," was eviscerated by a Fiend\n");
				if (attacker.classname == "monster_dog")
					bprint (PRINT_MEDIUM," was mauled by a Rottweiler\n");
				if (attacker.classname == "monster_dragon")
					bprint (PRINT_MEDIUM," was fried by a Dragon\n");
				if (attacker.classname == "monster_enforcer")
					bprint (PRINT_MEDIUM," was blasted by an Enforcer\n");
				if (attacker.classname == "monster_fish")
					bprint (PRINT_MEDIUM," was fed to the Rotfish\n");
				if (attacker.classname == "monster_hell_knight")
					bprint (PRINT_MEDIUM," was slain by a Death Knight\n");
				if (attacker.classname == "monster_knight")
					bprint (PRINT_MEDIUM," was slashed by a Knight\n");
				if (attacker.classname == "monster_ogre")
					bprint (PRINT_MEDIUM," was destroyed by an Ogre\n");
				if (attacker.classname == "monster_oldone")
					bprint (PRINT_MEDIUM," became one with Shub-Niggurath\n");
				if (attacker.classname == "monster_shalrath")
					bprint (PRINT_MEDIUM," was exploded by a Vore\n");
				if (attacker.classname == "monster_shambler")
					bprint (PRINT_MEDIUM," was smashed by a Shambler\n");
				if (attacker.classname == "monster_tarbaby")
					bprint (PRINT_MEDIUM," was slimed by a Spawn\n");
				if (attacker.classname == "monster_vomit")
					bprint (PRINT_MEDIUM," was vomited on by a Vomitus\n");
				if (attacker.classname == "monster_wizard")
					bprint (PRINT_MEDIUM," was scragged by a Scrag\n");
				if (attacker.classname == "monster_zombie")
					bprint (PRINT_MEDIUM," joins the Zombies\n");

				return;
			}
			if (attacker.classname == "explo_box")
			{
				bprint (PRINT_MEDIUM," blew up\n");
				return;
			}
			if (attacker.solid == SOLID_BSP && attacker != world)
			{
				bprint (PRINT_MEDIUM," was squished\n");
				return;
			}
			if (targ.deathtype == "falling")
			{
				targ.deathtype = "";
				bprint (PRINT_MEDIUM," fell to his death\n");
				return;
			}
			if (attacker.classname == "trap_shooter" || attacker.classname == "trap_spikeshooter")
			{
				bprint (PRINT_MEDIUM," was spiked\n");
				return;
			}
			if (attacker.classname == "fireball")
			{
				bprint (PRINT_MEDIUM," ate a lavaball\n");
				return;
			}
			if (attacker.classname == "trigger_changelevel")
			{
	 			bprint (PRINT_MEDIUM," tried to leave\n");
				return;
			}

			bprint (PRINT_MEDIUM," died\n");
		}
	}
};
