/////////////////////////////////////////////////////////////////////////

$cd id1/models/flag
$base base
$skin skin
$frame flagw1 flagw2 flagw3 flagw4 flagw5 flagw6 flagw7

//void()	flag_wave1	=[	$flagw1,	flag_wave2	] {};
//void()	flag_wave2	=[	$flagw2,	flag_wave3	] {};
//void()	flag_wave3	=[	$flagw3,	flag_wave4	] {};
//void()	flag_wave4	=[	$flagw4,	flag_wave5	] {};
//void()	flag_wave5	=[	$flagw5,	flag_wave6	] {};
//void()	flag_wave6	=[	$flagw6,	flag_wave7	] {};
//void()	flag_wave7	=[	$flagw7,	flag_wave1	] {};

void() place_flag = {
	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	if (!droptofloor()) {
		dprint ("Bonus item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		return;
	}
//	flag_wave1(); //make it wave
};

void() regen_flag = {
	self.model = self.mdl;
	self.solid = SOLID_TRIGGER;
	sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
//	flag_wave1();
};

// ZOID Capture the flag
void() item_flag_team1 =
{
	if (!deathmatch || !(cvar("teamplay") & TEAM_CAPTURE_FLAG)) {
		remove(self);
		return;
	}

	self.team = TEAM_COLOR1 + 1;
	self.cnt = 1; // it's at home base
	self.touch = TeamCaptureFlagTouch;
	self.items = IT_KEY2;
	if (cvar("teamplay") & TEAM_CAPTURE_CUSTOM) {
		precache_model ("progs/flag.mdl");
		setmodel (self, "progs/flag.mdl");
		self.skin = 0;
		precache_sound ("misc/flagtk.wav");			// flag taken
		precache_sound ("misc/flagcap.wav");			// flag capture
		precache_sound ("doors/runetry.wav");
		self.noise = "misc/flagtk.wav";
		self.noise1 = "doors/runetry.wav";
		setsize(self, '-16 -16 0', '16 16 74');
	} else {
		precache_model ("progs/w_g_key.mdl");
		setmodel (self, "progs/w_g_key.mdl");
		precache_sound ("misc/medkey.wav");
		precache_sound ("doors/meduse.wav");
		precache_sound ("doors/runetry.wav");
		self.noise = "misc/medkey.wav";
		self.noise1 = "doors/runetry.wav";
		setsize(self, '-16 -16 -24', '16 16 32');
	}

	// make it glow
	self.effects = self.effects | EF_DIMLIGHT;
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = place_flag;
};

void() item_flag_team2 =
{
	if (!deathmatch || !(cvar("teamplay") & TEAM_CAPTURE_FLAG)) {
		remove(self);
		return;
	}

	self.team = TEAM_COLOR2 + 1;
	self.cnt = 1; // it's at home base
	self.touch = TeamCaptureFlagTouch;
	self.items = IT_KEY1;
	if (cvar("teamplay") & TEAM_CAPTURE_CUSTOM) {
		precache_model ("progs/flag.mdl");
		setmodel (self, "progs/flag.mdl");
		self.skin = 1;
		precache_sound ("misc/flagtk.wav");			// flag taken
		precache_sound ("misc/flagcap.wav");			// flag capture
		precache_sound ("doors/runetry.wav");
		self.noise = "misc/flagtk.wav";
		self.noise1 = "doors/runetry.wav";
		setsize(self, '-16 -16 0', '16 16 74');
	} else {
		precache_model ("progs/w_s_key.mdl");
		setmodel (self, "progs/w_s_key.mdl");
		precache_sound ("misc/medkey.wav");
		precache_sound ("doors/meduse.wav");
		precache_sound ("doors/runetry.wav");
		self.noise = "misc/medkey.wav";
		self.noise1 = "doors/runetry.wav";
		setsize(self, '-16 -16 -24', '16 16 32');
	}
	// make it glow
	self.effects = self.effects | EF_DIMLIGHT;
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = place_flag;
};



