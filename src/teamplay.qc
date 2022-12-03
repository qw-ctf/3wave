/* teamplay.qc

   From
        The Comlete Enhanced Teamplay

   John Spickes -- jspickes@eng.umd.edu

	$Id: teamplay.qc 1.17 1996/08/17 16:52:45 jspickes Exp $

	$Log: teamplay.qc $
	Revision 1.17  1996/08/17 16:52:45  jspickes
	Fixed a problem with displaying the current team settings that could cause
	the wrong output when teamplay was negative.  Also added code to indicate
	when ID's silly teamplay code is being used.

	Revision 1.16  1996/08/17 00:41:52  jspickes
	Turned off strict coop by default.
	Fixed a bug that could have caused strange behavior if TEAM_COLOR* was
	set to -2.

	Revision 1.15  1996/08/17 00:34:17  jspickes
	Added instructions on drop-item use in current settings output.
	Fixed a problem that would allow you to drop lots of backpacks with
	nothing in them.

*/

/** Defs **/

/** MODIFIABLE CONSTANTS **/

float TEAM_DEFAULT_PENALTY =    1;      // Default frag penalty
float TEAM_STRICT_COOP =	0;	// Strict Coop

// Allowed team colors
// -1 indicates no color

float TEAM_COLOR1       =       4;
float TEAM_COLOR2       =       13;
float TEAM_COLOR3       =       -1;
float TEAM_COLOR4       =       -1;

/** End of MODIFIABLE CONSTANTS **/

// Globals

entity team1_lastspawn;
entity team2_lastspawn;

// Teamplay bitfield entries

float TEAM_HEALTH_PROTECT =     1;      // No health damage from friendly fire
float TEAM_ARMOR_PROTECT =      2;      // No armor damage from friendly fire
float TEAM_ATTACKER_DAMAGE =    4;      // Attacker takes damage from hitting teammates
float TEAM_FRAG_PENALTY =       8;      // One frag penalty for killing teammate
float TEAM_DEATH_PENALTY =      16;     // Die when you kill a teammate.
float TEAM_LOCK_COLORS =        32;     // Allow only team colors
float TEAM_STATIC_TEAMS =       64;     // Don't allow players to switch teams
float TEAM_DROP_ITEMS = 	128;	// Allow players to drop packs and
float TEAM_CAPTURE_FLAG =	256;	// Play capture the flag
float TEAM_CAPTURE_CUSTOM = 512;	// custom models

float TEAM_CAPTURE_CAPTURE_BONUS = 15; // what you get for capture
float TEAM_CAPTURE_TEAM_BONUS = 10; // what your team gets for capture
float TEAM_CAPTURE_RECOVERY_BONUS = 1; // what you get for recovery
float TEAM_CAPTURE_FLAG_BONUS = 0; // what you get for picking up enemy flag
float TEAM_CAPTURE_FRAG_CARRIER_BONUS = 2; // what you get for fragging
	//enemy flag carrier

// Prototypes
float() W_BestWeapon;
void() W_SetCurrentAmmo;
void() bound_other_ammo;
void(float o, float n) Deathmatch_Weapon;
void() BackpackTouch;
void()	flag_wave1;
void()	regen_flag;

// Return a name for the color of a team
string(float Team) GetTeamColor =
{
	if(Team == 0) return("Blue");
	else if(Team == 1) return("Steel blue");
	else if(Team == 2) return("Brown");
	else if(Team == 3) return("Baby blue");
	else if(Team == 4) return("Green");
	else if(Team == 5) return("Red");
	else if(Team == 6) return("Olive");
	else if(Team == 7) return("Orange");
	else if(Team == 8) return("Peech");
	else if(Team == 9) return("Purple");
	else if(Team == 10) return("Majenta");
	else if(Team == 11) return("Grey");
	else if(Team == 12) return("Aqua");
	else if(Team == 13) return("Yellow");
	else if(Team == 14) return("Blue");
	return "Unknown";
};


/*
================
TeamPrintSettings

Print out current teamplay options
================
*/

void() TeamPrintSettings =
{
	local string s;

	sprint(self,"The following Teamplay options are set:\n");

	if(teamplay < 0)
	{
		sprint(self, "Frag penalty manually set to ");
		s = ftos(teamplay);
		sprint(self, s);
		sprint(self, "\n");
		return;
	}

	if(!teamplay)
	{
		sprint(self, "None\n");
		return;
	}

	if(1 == teamplay)
	{
		sprint(self, "ID's original teamplay 1\n");
		return;
	}

	if(teamplay & TEAM_HEALTH_PROTECT)
		sprint(self, "Health-Protect ");

	if(teamplay & TEAM_ARMOR_PROTECT)
		sprint(self, "Armor-Protect ");

	if(teamplay & TEAM_ATTACKER_DAMAGE)
		sprint(self, "Mirror-Damage ");

	if(teamplay & TEAM_FRAG_PENALTY)
		sprint(self, "Frag-Penalty ");

	if(teamplay & TEAM_DEATH_PENALTY)
		sprint(self, "Death-Penalty ");

	if(teamplay & TEAM_LOCK_COLORS)
		sprint(self, "Lock-Colors ");

	if(teamplay & TEAM_STATIC_TEAMS)
		sprint(self, "Static-Teams ");

	if(teamplay & TEAM_DROP_ITEMS)
		sprint(self, "Drop-Items (Backpack Impulse 20, Weapon Impulse 21) ");

	if(teamplay & TEAM_CAPTURE_FLAG)
		sprint(self, "Capture-The-Flag ");

	sprint(self, "\n");
};

/*
================
TeamArmorDam

Return TRUE if the target's armor can take damage from this attacker.
================
*/

float(entity targ, entity inflictor, entity attacker, float damage) TeamArmorDam =
{
        if( teamplay < 0 )
                return TRUE;
        if( (teamplay & TEAM_ARMOR_PROTECT) &&
			(attacker.lastteam == targ.lastteam) &&
			(attacker != targ) && (targ.lastteam > 0) )
        {
                // Armor is protected
                return FALSE;
        }
        return TRUE;
};

/*
================
TeamHealthDam

Return TRUE if the target can take health damage from this attacker.
================
*/

float(entity targ, entity inflictor, entity attacker, float damage) TeamHealthDam =
{
        if( teamplay < 0 )
        {
                return TRUE;
        }
        if( (attacker.lastteam == targ.lastteam) &&
			(attacker != targ) && (targ.lastteam > 0) )
        {
                // Attacker and target are on the same team.
                if( teamplay & TEAM_ATTACKER_DAMAGE )
                {
                        // Damage applied to teammate.
                        T_Damage(attacker, inflictor, attacker, damage);
                }
                if( teamplay & TEAM_HEALTH_PROTECT )
                {
                        // Health is protected
                        return FALSE;
                }
        }
        return TRUE;
};

/*
================
TeamPFrags

Return the number of frags we should penalize attacker for killing targ.
================
*/

float(entity targ, entity attacker) TeamPFrags =
{
        if( teamplay < 0 )
                return (-1 * teamplay);
        if( (targ.lastteam > 0) && (targ != attacker) && (targ.lastteam ==
			attacker.lastteam) )
        {
                // targ and attacker are on the same team
                if( teamplay < 0 )
                {
                        // teamplay indicates frag penalty
                        return ( -1 * teamplay );
                }
                if( teamplay & TEAM_FRAG_PENALTY )
                {
                        // default penalty
                        return TEAM_DEFAULT_PENALTY;
                }
        }
        // No frag penalty
        return 0;
};

/*
================
TeamFragPenalty

If attacker should be penalized for killing targ, penalize attacker
and return TRUE.
================
*/

float(entity targ, entity attacker) TeamFragPenalty =
{
        local float f;

        f = TeamPFrags(targ, attacker);

        if( f )
        {
                // We should penalize some frags.
                attacker.frags = attacker.frags - f;
                return TRUE;
        }
        // No penalty
        return FALSE;
};

/*
=================
TeamDeathPenalty

If attacker should be killed for killing targ, kill attacker and
add a frag to offset the one attacker will lose for killing himself.
*/

void(entity targ, entity attacker) TeamDeathPenalty =
{
        //Don't kill anyone if teamplay is negative.
        if ( teamplay < 0 )
                return;

        if ( (teamplay & TEAM_DEATH_PENALTY) && (targ.lastteam > 0) &&
			(attacker != targ) && (attacker.lastteam == targ.lastteam) )
        {
                //We should kill the attacker.
                T_Damage(attacker,attacker,attacker,1000);
                //Add a frag to offset the self-kill penalty.
                attacker.frags = attacker.frags + 1;
        }
};

/*
==================
TeamColorIsLegal

Return TRUE if the indicated color is legal
==================
*/
float(float color) TeamColorIsLegal =
{
        // All colors are legal if teamplay is negative.
        if( teamplay < 0 )
                return TRUE;
        // All colors are legal if TEAM_LOCK_COLORS is off.
        if( !(teamplay & TEAM_LOCK_COLORS) )
                return TRUE;
        if( (color == TEAM_COLOR1) && (TEAM_COLOR1 >= 0) )
                return TRUE;
        if( (color == TEAM_COLOR2) && (TEAM_COLOR2 >= 0) )
                return TRUE;
        if( (color == TEAM_COLOR3) && (TEAM_COLOR3 >= 0) )
                return TRUE;
        if( (color == TEAM_COLOR4) && (TEAM_COLOR4 >= 0) )
                return TRUE;
};

/*
==================
TeamCheckTeam

Check if the team self is on is legal, and put self in a legal team if not.
==================
*/
void() TeamCheckTeam =
{
	local float TEAM1;
	local float TEAM2;
	local float TEAM3;
	local float TEAM4;

	local float newcolor;
	local float t;

	local entity p;

	local string n;

	if( self.lastteam >= 0 )
	{
			if(TeamColorIsLegal(self.team - 1)) {
				self.lastteam = self.team;
				return;
			}
	}

	// Assign the player to a team.

	// Sum the players on all the teams.

	TEAM1 = 0;
	TEAM2 = 0;
	TEAM3 = 0;
	TEAM4 = 0;

	p = find (world, classname, "player");

	while(p)
	{
		if (p != self) {
			if( (TEAM_COLOR1 >= 0) && (p.team == (TEAM_COLOR1 +1)) )
					TEAM1 = TEAM1 + 1;
			if( (TEAM_COLOR2 >= 0) && (p.team == (TEAM_COLOR2 +1)) )
					TEAM2 = TEAM2 + 1;
			if( (TEAM_COLOR3 >= 0) && (p.team == (TEAM_COLOR3 +1)) )
					TEAM3 = TEAM3 + 1;
			if( (TEAM_COLOR4 >= 0) && (p.team == (TEAM_COLOR4 +1)) )
					TEAM4 = TEAM4 + 1;
		}
		p = find(p, classname, "player");
	}

	// Find the team with the least players.
	newcolor = TEAM_COLOR1;
	t = TEAM1;

	if ( (TEAM_COLOR2 >= 0) && (TEAM2 < t) ) {
			newcolor = TEAM_COLOR2;
			t = TEAM2;
	}

	if ( (TEAM_COLOR3 >= 0) && (TEAM3 < t) ) {
			newcolor = TEAM_COLOR3;
			t = TEAM3;
	}

	if ( (TEAM_COLOR4 >= 0) && (TEAM4 < t) ) {
			newcolor = TEAM_COLOR4;
			t = TEAM4;
	}

	// Put the player on a the new team.

	n = ftos(newcolor);
	stuffcmd(self, "color ");
	stuffcmd(self, n);
	stuffcmd(self, "\n");

	sprint(self, "You have been assigned color ");
	sprint(self, n);
	sprint(self, "\nLegal colors are:");
	if(TEAM_COLOR1 >= 0)
	{
			n = ftos(TEAM_COLOR1);
			sprint(self, " ");
			sprint(self, n);
	}
	if(TEAM_COLOR2 >= 0)
	{
			n = ftos(TEAM_COLOR2);
			sprint(self, " ");
			sprint(self, n);
	}
	if(TEAM_COLOR3 >= 0)
	{
			n = ftos(TEAM_COLOR3);
			sprint(self, " ");
			sprint(self, n);
	}
	if(TEAM_COLOR4 >= 0)
	{
			n = ftos(TEAM_COLOR4);
			sprint(self, " ");
			sprint(self, n);
	}

	sprint(self, "\n");

	self.lastteam = newcolor + 1;      // Remember what team we're on
	self.team = newcolor + 1;
};

/*
===============
TeamCheckLock

Check for team changing and perform whatever actions are neccessary.
===============
*/
void() TeamCheckLock =
{
        local   float   n;
        local   string  s;

        // Don't do anything if teamplay is negative
        if ( teamplay < 0 )
                return;

		if (self.player_flag & TEAM_STUFF_COLOR) {
			self.player_flag = self.player_flag - TEAM_STUFF_COLOR;
			stuffcmd(self, "color ");
			n = self.lastteam - 1;
			s = ftos(n);
			stuffcmd(self, s);
			stuffcmd(self, "\n");
			return;
		}

        if ( !TeamColorIsLegal(self.team - 1) && (self.team == self.lastteam)) {
			self.lastteam = -1;
		}

        // Check to see if the player has changed colors
        if (self.team != self.lastteam)
        {
                // Player has changed colors

                // If teams are static and we've been on some team already,
                // put us back on the team we were on.

                if ( (teamplay & TEAM_STATIC_TEAMS) && (self.lastteam >= 0) )
                {
                        if ( TeamColorIsLegal(self.lastteam - 1) )
                        {
								// changing teams sucks, kill him

								// if he has tried to change teams several
								// times, kick him off the server.
								if (self.suicide_count > 3) {
									sprint(self, "You were told you can't change teams.\nGo play color games somewhere else.\n");
									stuffcmd(self, "disconnect\n");
									bprint(self.netname);
									bprint(" has bad color sense\n");
								}
								// case base respawn
								if (self.killed != 1)
									self.killed = 2;
								T_Damage(self,self,self,1000);  // Kill the player
								// trying to change teams counts as a suicide
								self.suicide_count = self.suicide_count + 1;

                                sprint(self, "You cannot change teams.\n");
                                stuffcmd(self, "color ");
                                n = self.lastteam - 1;
                                s = ftos(n);
                                stuffcmd(self, s);
                                stuffcmd(self, "\n");
								self.team = self.lastteam;
                                return;
                        }
                        else {
                                // If we're on an illegal team, force a change.
                                self.lastteam = -50;
						}
                }

                // If teamlock is turned off, don't do anything more.
                if ( !(teamplay & TEAM_LOCK_COLORS) )
                {
						self.lastteam = self.team;
                        return;
                }

                if(self.lastteam > 0) {
					// case base respawn
					if (self.killed != 1)
						self.killed = 2;
					T_Damage(self,self,self,1000);  // Kill the player
				}
                self.frags = 0;                 // Zero out frags
                TeamCheckTeam();
        }
};

/*
=======================
TossBackPack

Original idea by Vhold
Rewritten by John Spickes

Toss out a backpack containing some ammo from your current weapon,
and any weapons you don't have.
=======================
*/
void() TossBackpack =
{
	local entity 	item;

	// If we don't have any ammo, return
	if(self.currentammo <= 0)
		return;

	item = spawn();

	// See if you have the Shotgun or Super Shotgun on
        if ( (self.weapon == IT_SHOTGUN) || (self.weapon == IT_SUPER_SHOTGUN) )
	{
		if( self.ammo_shells >= 20 ) {
			item.ammo_shells = 20;
			self.ammo_shells = self.ammo_shells - 20;
		}
		else
		{
			item.ammo_shells = self.ammo_shells;
			self.ammo_shells = 0;
		}
	}

	// See if you have neither the Shotgun or Super Shotgun
        if ( !(self.items & IT_SHOTGUN) && !(self.items & IT_SUPER_SHOTGUN) )
	{
		if( self.ammo_shells >= 20 ) {
			item.ammo_shells = 20;
			self.ammo_shells = self.ammo_shells - 20;
		}
		else
		{
			item.ammo_shells = self.ammo_shells;
			self.ammo_shells = 0;
		}
	}

	// See if we are using a nailgun
        if ( (self.weapon == IT_NAILGUN) || (self.weapon == IT_SUPER_NAILGUN) )
	{
		if( self.ammo_nails >= 20 )
		{
			item.ammo_nails = 20;
			self.ammo_nails = self.ammo_nails - 20;
		}
		else
		{
			item.ammo_nails = self.ammo_nails;
			self.ammo_nails = 0;
		}
	}
	// Check to see if we have neither nailgun
        if ( !(self.items & IT_NAILGUN) && !(self.items & IT_SUPER_NAILGUN) )
	{
		if( self.ammo_nails >= 20 )
		{
			item.ammo_nails = 20;
			self.ammo_nails = self.ammo_nails - 20;
		}
		else
		{
			item.ammo_nails = self.ammo_nails;
			self.ammo_nails = 0;
		}
	}

	// See if we are using a grenade or rocket launcher
        if ( (self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_ROCKET_LAUNCHER) )
	{
		if( self.ammo_rockets >= 10 )
		{
			item.ammo_rockets = 10;
			self.ammo_rockets = self.ammo_rockets - 10;
		}
		else
		{
			item.ammo_rockets = self.ammo_rockets;
			self.ammo_rockets = 0;
		}
	}
	// See if we have neither the Grenade or rocket launcher
        if ( !(self.items & IT_GRENADE_LAUNCHER) && !(self.items & IT_ROCKET_LAUNCHER) )
	{
		if( self.ammo_rockets >= 10 )
		{
			item.ammo_rockets = 10;
			self.ammo_rockets = self.ammo_rockets - 10;
		}
		else
		{
			item.ammo_rockets = self.ammo_rockets;
			self.ammo_rockets = 0;
		}
	}

	// See if we're using the lightning gun
	if ( self.weapon == IT_LIGHTNING )
	{
		if( self.ammo_cells >= 20 )
		{
			item.ammo_cells = 20;
			self.ammo_cells = self.ammo_cells - 20;
		}
		else
		{
			item.ammo_cells = self.ammo_cells;
			self.ammo_cells = 0;
		}
	}
	// see if we don't have the lightning gun
        if ( !(self.items & IT_LIGHTNING) )
	{
		if( self.ammo_cells >= 20 )
		{
			item.ammo_cells = 20;
			self.ammo_cells = self.ammo_cells - 20;
		}
		else
		{
			item.ammo_cells = self.ammo_cells;
			self.ammo_cells = 0;
		}
	}

	item.owner = self;
	makevectors(self.v_angle);

	setorigin(item, self.origin + '0 0 16');
	item.velocity = aim(self, 1000);
	item.velocity = item.velocity * 500;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_BOUNCE;

	setmodel (item, "progs/backpack.mdl");
	setsize(item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;
	item.nextthink = time + 120;	// remove after 2 minutes
	item.think = SUB_Remove;

	W_SetCurrentAmmo();

};

void() Team_weapon_touch =
{
	local	float	hadammo, best, new, old;
	local entity stemp;

	if (!(other.flags & FL_CLIENT))
		return;
	// Don't let the owner pick up his own weapon for a second.
	if ( (other == self.owner) && ( (self.nextthink - time) > 119 ) )
		return;

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

	if (self.classname == "weapon_nailgun")
	{
		hadammo = other.ammo_nails;
		new = IT_NAILGUN;
	}
	else if (self.classname == "weapon_supernailgun")
	{
		hadammo = other.ammo_rockets;
		new = IT_SUPER_NAILGUN;
	}
	else if (self.classname == "weapon_supershotgun")
	{
		hadammo = other.ammo_rockets;
		new = IT_SUPER_SHOTGUN;
	}
	else if (self.classname == "weapon_rocketlauncher")
	{
		hadammo = other.ammo_rockets;
		new = IT_ROCKET_LAUNCHER;
	}
	else if (self.classname == "weapon_grenadelauncher")
	{
		hadammo = other.ammo_rockets;
		new = IT_GRENADE_LAUNCHER;
	}
	else if (self.classname == "weapon_lightning")
	{
		hadammo = other.ammo_rockets;
		new = IT_LIGHTNING;
	}
	else
		objerror ("Team_weapon_touch: unknown classname");

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other, "\n");
// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	bound_other_ammo ();

// change to the weapon
	old = other.items;
	other.items = other.items | new;

	remove(self);
	self = other;

	if (!deathmatch)
		self.weapon = new;
	else
		Deathmatch_Weapon (old, new);

	W_SetCurrentAmmo();

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

void() TossWeapon =
{
	local entity item;

	if((self.weapon == IT_AXE) || (self.weapon == IT_SHOTGUN) ||
		(self.weapon == IT_HOOK))
		return;

	item = spawn();
	item.owner = self;
	makevectors(self.v_angle);

	setorigin(item, self.origin + '0 0 16');
	item.velocity = aim(self, 1000);
	item.velocity = item.velocity * 500;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_BOUNCE;

	if(self.weapon == IT_SUPER_SHOTGUN)
	{
		setmodel (item, "progs/g_shot.mdl");
		item.weapon = IT_SUPER_SHOTGUN;
		item.netname = "Double-barrelled Shotgun";
		item.classname = "weapon_supershotgun";
		self.items = self.items - IT_SUPER_SHOTGUN;
	}

	if( self.weapon == IT_NAILGUN )
	{
		setmodel (item, "progs/g_nail.mdl");
		item.weapon = IT_NAILGUN;
		item.netname = "nailgun";
		item.classname = "weapon_nailgun";
		self.items = self.items - IT_NAILGUN;
	}

	if( self.weapon == IT_SUPER_NAILGUN)
	{
		setmodel (item, "progs/g_nail2.mdl");
		item.weapon = IT_SUPER_NAILGUN;
		item.netname = "Super Nailgun";
		item.classname = "weapon_supernailgun";
		self.items = self.items - IT_SUPER_NAILGUN;
	}

	if( self.weapon == IT_GRENADE_LAUNCHER)
	{
		setmodel (item, "progs/g_rock.mdl");
		item.weapon = 3;
		item.netname = "Grenade Launcher";
		item.classname = "weapon_grenadelauncher";
		self.items = self.items - IT_GRENADE_LAUNCHER;
	}

	if( self.weapon == IT_ROCKET_LAUNCHER )
	{
		setmodel (item, "progs/g_rock2.mdl");
		item.weapon = 3;
		item.netname = "Rocket Launcher";
		item.classname = "weapon_rocketlauncher";
		self.items = self.items - IT_ROCKET_LAUNCHER;
	}

	if( self.weapon == IT_LIGHTNING )
	{
		setmodel (item, "progs/g_light.mdl");
		item.weapon = 3;
		item.netname = "Thunderbolt";
		item.classname = "weapon_lightning";
		self.items = self.items - IT_LIGHTNING;
	}
	setsize(item, '-16 -16 0', '16 16 56');
	item.touch = Team_weapon_touch;
	item.think = SUB_Remove;
	item.nextthink = time + 120;

	self.weapon = W_BestWeapon();
	W_SetCurrentAmmo();
};

void() SilentKill;

void() TeamCaptureRegenFlags =
{
	local entity f;

	self = find(world, classname, "item_flag_team1");
	if (self != world)
		regen_flag();
	self = find(world, classname, "item_flag_team2");
	if (self != world)
		regen_flag();
};

void() TeamCaptureFlagSanityCheck =
{
	local entity p;

	// Ok, a flag must be in one of three states
	// 1. At home base (though we shouldn't be called in that case)
	// 2. On enemy player
	// 3. A copy is sitting around somewhere, waiting to be picked up

	// at home base?
	if (self.model != string_null) {
		self.think = TeamCaptureFlagSanityCheck;
		self.nextthink = time + 30;
		return; // its at home, no prob
	}

	// on enemy player?
	p = find(world, classname, "player");
	while (p != world) {
		if ((p.team != self.team) && (p.player_flag & ITEM_ENEMY_FLAG)) {
			self.think = TeamCaptureFlagSanityCheck;
			self.nextthink = time + 30;
			return; // enemy player has it
		}
		p = find(p, classname, "player");
	}

	// copy sitting around somewhere
	p = find(world, classname, "info_dropped_flag");
	while (p != world) {
		if (p.team == self.team) {
			self.think = TeamCaptureFlagSanityCheck;
			self.nextthink = time + 30;
			return; // its out hanging around
		}
		p = find(p, classname, "info_dropped_flag");
	}
	// didn't find it, oh my
	// regen this one
	regen_flag();
};

void() TeamCaptureFlagTouch =
{
	local entity p, oself;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	if (other.team != other.lastteam)
		return; // something is fishy, somebody is playing with colors

	if (self.team == other.team) {
		// same team, if the flag is *not* at the base, return
		// it to base.  we overload the 'cnt' field for this
		if (self.cnt) {
			// the flag is at home base.  if the player has the enemy
			// flag, he's just won!

			if (other.player_flag & ITEM_ENEMY_FLAG) {
				bprint(other.netname);
				if (other.team == TEAM_COLOR1 + 1)
					bprint(" ãáðôõòåä the ÂÌÕÅ flag!\n"); // blue
				else
					bprint(" ãáðôõòåä the ÒÅÄ flag!\n"); // red
				LogMsg(other, "FLAG-CAPTURE");
				other.items = other.items - (other.items & (IT_KEY1 | IT_KEY2));

				if (teamplay & TEAM_CAPTURE_CUSTOM)
					sound (other, CHAN_VOICE, "misc/flagcap.wav", 1, ATTN_NONE);
				else
					sound (other, CHAN_VOICE, "doors/meduse.wav", 1, ATTN_NONE);

				// other gets another 10 frag bonus
				other.frags = other.frags + TEAM_CAPTURE_CAPTURE_BONUS;

				// Ok, let's do the player loop, hand out the bonuses
				p = find(world, classname, "player");
				while (p != world) {
					self = p;
					self.killed = 0;
					if (self.team == other.team && self != other)
						self.frags = self.frags + TEAM_CAPTURE_TEAM_BONUS;
					if (self.team != other.team)
						centerprint(self, "Your flag was captured!\n");
					else if (self.team == other.team)
						centerprint(self, "Your team captured the flag!\n");
					self.player_flag = self.player_flag - (self.player_flag & ITEM_ENEMY_FLAG);
// ZOID, next line isn't needed, EF_DIMLIGHT is handled by
// client.qc:CheckDimLight
//					self.effects = self.effects - (self.effects & EF_DIMLIGHT);

					p = find(p, classname, "player");
				}
				// respawn flags
				TeamCaptureRegenFlags();
				return;
			}
			return; // its at home base already
		}
		// hey, its not home.  return it by teleporting it back
		bprint(other.netname);
		if (other.team == TEAM_COLOR1 + 1)
			bprint(" òåôõòîåä the ÒÅÄ flag!\n"); // red
		else
			bprint(" òåôõòîåä the ÂÌÕÅ flag!\n"); // blue
		LogMsg(other, "FLAG-RECOVERY");
		other.frags = other.frags + TEAM_CAPTURE_RECOVERY_BONUS;
		sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
		remove(self); // oops it gone
		p = find(world, classname, "player");
		while (p != world) {
			if (p.team != other.team)
				centerprint(p, "Enemy flag has been returned to base!\n");
			else if (p.team == other.team)
				centerprint(p, "Your flag has been returned to base!\n");
			p = find(p, classname, "player");
		}
		if (other.team == TEAM_COLOR1 + 1) {
			self = find(world, classname, "item_flag_team1");
			if (self != world)  {
				self.think = SUB_Null; // its at home, no need to think
				regen_flag();
			}
		} else { // TEAM_COLOR2
			self = find(world, classname, "item_flag_team2");
			if (self != world) {
				self.think = SUB_Null; // its at home, no need to think
				regen_flag();
			}
		}
		return;
	}

	// hey, its not our flag, pick it up
	bprint(other.netname);
	if (other.team == TEAM_COLOR1 + 1)
		bprint(" çïô the ÂÌÕÅ flag!\n"); // blue
	else
		bprint(" çïô the ÒÅÄ flag!\n"); // red
	LogMsg(other, "FLAG-PICKUP");
	if (TEAM_CAPTURE_FLAG_BONUS)
		other.frags = other.frags + TEAM_CAPTURE_FLAG_BONUS;
//	centerprint(other, "YOU GOT THE ENEMY FLAG!\n\nRETURN TO BASE!\n");
	centerprint(other, "ÙÏÕ ÇÏÔ ÔÈÅ ÅÎÅÍÙ ÆÌÁÇ\n\nÒÅÔÕÒÎ ÔÏ ÂÁÓÅ\n");
	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	other.player_flag = other.player_flag + ITEM_ENEMY_FLAG;
	other.items = other.items | self.items;
	// turn on the glow
// ZOID, next line isn't needed, EF_DIMLIGHT is handled by
// client.qc:CheckDimLight
//	other.effects = other.effects | EF_DIMLIGHT;

	// make the flag here disappear
	if (self.cnt) {
		// home base flags stay
		self.solid = SOLID_NOT;
		self.model = string_null;
		// set up sanity check
		self.think = TeamCaptureFlagSanityCheck;
		self.nextthink = time + 30; // 30 seconds pre check
	} else
		remove(self); // dropped flags recyclce

	p = find(world, classname, "player");
	while (p != world) {
		if (p != other) {
			if (p.team != other.team)
				centerprint(p, "Your flag has been taken!\n");
			else if (p.team == other.team)
				centerprint(p, "Your team has the enemy flag!\n");
		}
		p = find(p, classname, "player");
	}
};

void() TeamCaptureReturnFlag =
{
	local entity f, p;

	f = world;
	if (self.team == TEAM_COLOR1 + 1) {
		f = self;
		self = find(world, classname, "item_flag_team1");
		if (self != world) {
			self.think = SUB_Null; // its at home, no need to think
			regen_flag();
		}
	} else { // TEAM_COLOR2
		f = self;
		self = find(world, classname, "item_flag_team2");
		if (self != world) {
			self.think = SUB_Null; // its at home, no need to think
			regen_flag();
		}
	}
	if (f == world)
		return;
	p = find(world, classname, "player");
	while (p != world) {
		if (p.team != f.team)
			centerprint(p, "Enemy flag has been returned to base!\n");
		else if (p.team == f.team)
			centerprint(p, "Your flag has been returned to base!\n");
		p = find(p, classname, "player");
	}
	remove(f);
};

void() TeamCaptureDropFlag =
{
	local entity item, f, oself;

	if (!(self.player_flag & ITEM_ENEMY_FLAG))
		return;

	self.player_flag = self.player_flag - ITEM_ENEMY_FLAG;

	bprint(self.netname);
	if (self.lastteam == TEAM_COLOR1 + 1)
		bprint(" ìïóô the ÂÌÕÅ flag!\n"); // blue
	else
		bprint(" ìïóô the ÒÅÄ flag!\n"); // red
	LogMsg(self, "FLAG-DROP");

	item = spawn();
	item.items = self.items & (IT_KEY1 | IT_KEY2);
	item.origin = self.origin - '0 0 24';
	item.cnt = 0; // it's NOT at home base
	//NOTE! We check lastteam here instead of team--this is because
	//in the mode where we change colors, we get killed
	if (self.lastteam == TEAM_COLOR1 + 1) {
		item.classname = "info_dropped_flag";
		item.team = TEAM_COLOR2 + 1;
		f = find(world, classname, "item_flag_team2");
		if (f != world) {
			setmodel(item, f.mdl);
			item.skin = f.skin;
			item.noise = f.noise;
		} else {
			setmodel(item, "progs/lavaball.mdl");
			item.noise = "";
		}
	} else { // TEAM_COLOR2
		item.classname = "info_dropped_flag";
		item.team = TEAM_COLOR1 + 1;
		f = find(world, classname, "item_flag_team1");
		if (f != world) {
			setmodel(item, f.mdl);
			item.skin = f.skin;
			item.noise = f.noise;
		} else {
			setmodel(item, "progs/lavaball.mdl");
			item.noise = "";
		}
	}
	item.velocity_z = 300;
	item.velocity_x = 0;
	item.velocity_y = 0;
	item.touch = TeamCaptureFlagTouch;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	if (teamplay & TEAM_CAPTURE_CUSTOM)
		setsize(item, '-8 -8 -8', '16 16 32');
	else
		setsize(item, '-16 -16 -24', '16 16 32');
	item.effects = item.effects | EF_DIMLIGHT; // make it glow
	oself = self;
	self = item;
	if (teamplay & TEAM_CAPTURE_CUSTOM)
		flag_wave1(); // make it wave
	self = oself;
	// return the flag to base if no one picks it up for a while
	item.think = TeamCaptureReturnFlag;
	item.nextthink = time + 30;
};

// self is player
entity() TeamCaptureSpawn =
{

	if (!(teamplay & TEAM_CAPTURE_FLAG))
		return world;

	if (self.team == TEAM_COLOR1 + 1) {
		team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
		if (team1_lastspawn == world)
			team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
		return team1_lastspawn;
	} else { // if (self.team == TEAM_COLOR2 + 1)
		team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
		if (team2_lastspawn == world)
			team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
		return team2_lastspawn;
	}
	return world;
};

// ZOID -- total up team scores and set everyone's frag count to the team
// total
void() TeamScores =
{
	local float team1, team2, team3, team4;
	local entity p;

	if (teamscored || !teamplay)
		return; // already scored or not in team mode

	teamscored = 1;

	team1 = 0;
	team2 = 0;
	team3 = 0;
	team4 = 0;

dprint("TeamScores()\n");
	p = find(world, classname, "player");
	while (p != world) {
dprint("  Player=");
dprint(p.netname);
dprint(" Team=");
dprint(ftos(p.team));
dprint(" Frags=");
dprint(ftos(p.frags));
dprint("\n");
		if (p.team == TEAM_COLOR1 + 1)
			team1 = team1 + p.frags;
		else if (p.team == TEAM_COLOR2 + 1)
			team2 = team2 + p.frags;
		else if (p.team == TEAM_COLOR3 + 1)
			team3 = team3 + p.frags;
		else if (p.team == TEAM_COLOR4 + 1)
			team4 = team4 + p.frags;
		p = find(p, classname, "player");
	}
dprint(" Totals: team1=");
dprint(ftos(team1));
dprint(" team2=");
dprint(ftos(team2));
dprint("\n");
	p = find(world, classname, "player");
	while (p != world) {
		if (p.team == TEAM_COLOR1 + 1)
			p.frags = team1;
		else if (p.team == TEAM_COLOR2 + 1)
			p.frags = team2;
		else if (p.team == TEAM_COLOR3 + 1)
			p.frags = team3;
		else if (p.team == TEAM_COLOR4 + 1)
			p.frags = team4;
		p = find(p, classname, "player");
	}
};

/*
	From byron@caseware.com Wed Oct 16 18:57:44 1996
	Date: Wed, 16 Oct 1996 21:22:37 -0400
	From: Byron Long <byron@caseware.com>
	To: zoid@mindlink.net
	Subject: Team Status Command (source code included) :-)

	A co-worker of mine wondered if it was possible to add a function to
	your capture the flag code that would give a status report on an
	impulse. I think he may have mailed you, but I wrote a quick version
	myself, which your welcome to use if you like the feature (it offsets
	some of the problems with the chat capabilities in Quake so it seems
	like a worthwhile feature). Feel free to change it
	as necessary.
*/

// *Capture The Flag - Status report by Wonko
void() TeamFlagStatusReport =
{
	local entity flag1, flag2, thief1, thief2, p;

	if (!(teamplay & TEAM_CAPTURE_FLAG)) {
		sprint(self, "Capture the Flag is not enabled.\n");
		return;
	}

	// Find the flags at home base
	flag1 = find (world,classname, "item_flag_team1");
	flag2 = find (world,classname, "item_flag_team2");

	// Find whether they are superceded by dropped flags
	if (flag1 != world && flag2 != world &&
		(flag1.model == string_null || flag2.model == string_null)) {
		p = find(world, classname, "info_dropped_flag");
		while (p != world) {
			if (p.team == TEAM_COLOR1 + 1) {
				if (flag1.model == string_null)
					flag1 = p;
			}
			else {
				if (flag2.model == string_null)
					flag2 = p;
			}
			p = find(p, classname, "info_dropped_flag");
		}
	}

	// If on team 2 switch meanings of flags
	if (self.team != TEAM_COLOR1 + 1) {
		p = flag1;
		flag1 = flag2;
		flag2 = p;
	}

	// Find if a player is carrying the flag(s)
	thief1 = world;
	thief2 = world;

	p = find(world, classname, "player");
	while (p != world) {
		if ((p.player_flag & ITEM_ENEMY_FLAG)) {
			if (p.team == self.team)
				thief2 = p;
			else
				thief1 = p;
		}
		p = find(p, classname, "player");
	}

	// Player's team flag status
	if (thief1 == world) {
		sprint(self, "Your flag is ");
		if (flag2 == world)
			sprint (self, " missing! ");
		else {
			if (flag1.cnt)
				sprint(self, "in your base. ");
			else
				sprint(self, "lying about. ");
		}
	} else {
		sprint (self, thief1.netname);
		sprint (self, " has your flag. ");
	}

	// Enemy team flag status
	if (thief2 == world) {
		sprint(self, "The enemy flag is ");
		if (flag2 == world)
			sprint (self, "missing!\n");
		else {
			if (flag2.cnt)
				sprint(self, "in their base.\n");
			else
				sprint(self, "lying about.\n");
		}
	} else {
		if (self == thief2)
			sprint(self, "You have the enemy flag.\n");
		else {
			sprint (self, thief2.netname);
			sprint (self, " has the enemy flag.\n");
		}
	}
};

