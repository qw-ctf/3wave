// Spectator functions
// Added Aug11'97 by Zoid <zoid@idsoftware.com>
//
// These functions are called from the server if they exist.
// Note that Spectators only have one think since they movement code doesn't
// track them much.  Impulse commands work as usual, but don't call
// the regular ImpulseCommand handler in weapons.qc since Spectators don't
// have any weapons and things can explode.
//
//   --- Zoid.

/*
===========
SpectatorConnect

called when a spectator connects to a server
============
*/
void() SpectatorConnect =
{
	bprint (PRINT_MEDIUM, "Spectator ");
	bprint (PRINT_MEDIUM, self.netname);
	bprint (PRINT_MEDIUM, " entered the game\n");

	self.goalentity = world; // used for impulse 1 below
	self.motd_count = 1;
	self.classname = "spectator";
};

/*
===========
SpectatorDisconnect

called when a spectator disconnects from a server
============
*/
void() SpectatorDisconnect =
{
	bprint (PRINT_MEDIUM, "Spectator ");
	bprint (PRINT_MEDIUM, self.netname);
	bprint (PRINT_MEDIUM, " left the game\n");
	self.statstate = 0;
};

/*
================
SpectatorImpulseCommand

Called by SpectatorThink if the spectator entered an impulse
================
*/
void() SpectatorImpulseCommand =
{
	if (self.impulse == 1) {
		// teleport the spectator to the next spawn point
		// note that if the spectator is tracking, this doesn't do
		// much
		self.goalentity = find(self.goalentity, classname, "info_player_deathmatch");
		if (self.goalentity == world)
			self.goalentity = find(self.goalentity, classname, "info_player_deathmatch");
		if (self.goalentity != world) {
			setorigin(self, self.goalentity.origin);
			self.angles = self.goalentity.angles;
			self.fixangle = TRUE;           // turn this way immediately
		}
	} else if (self.impulse == 23)
		TeamFlagStatusReport();

	else if (self.impulse == 25)
		TeamPrintSettings ();

	else if (self.impulse == 70) {
		if (self.statstate < 0) {
			self.statstate = 0;
			sprint(self, PRINT_HIGH, "Status bar on (impulse 71 to 81 to set size)\n");
		} else {
			self.statstate = -1;
			sprint(self, PRINT_HIGH, "Status bar off.\n");
		}

	} else if (self.impulse >= 71 && self.impulse <= 81) {
		self.statstate = self.impulse - 71;
		sprint(self, PRINT_HIGH, "Status bar set\n");
	}

	self.impulse = 0;
};

/*
================
SpectatorThink

Called every frame after physics are run
================
*/
void() SpectatorThink =
{
	// self.origin, etc contains spectator position, so you could
	// do some neat stuff here

	TeamCapturePlayerUpdate();

	if (self.impulse)
		SpectatorImpulseCommand();
};


