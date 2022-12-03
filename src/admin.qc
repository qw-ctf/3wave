//---------------------------------------------------------------------------
//Quake
//
//Copyright (c) 1995-96 by Dave Kirsch
//---------------------------------------------------------------------------
//admin - remove server admin functions
//---------------------------------------------------------------------------

.float accesslvl; // current access level
.float accessparm; // current access parm

// NOTE:  THE FOLLOWING VALUES ARE THE PASSWORD USED TO ENABLE
// REMOTE ACCESS.
//
// The have the following properties and requirements:
// a. Must not be an existing impulse
// b. Must be entered in the specified order
// c. Must be in the range 1 to 255 excluding previously used impulses
//
// They must be entered in the correct order which gives 256*256*256 or
// 16777216 possible passwords.  If a specified order wasn't given, it
// would only be 768 possibilities.
//
// BY DEFAULT, REMOTE ADMIN ACCESS IS DISABLED
// This is done by setting the admin passwords all to -1.
//
// If you wanted to enable it, pick three random numbers (that aren't
// existing impulses) and put 'em here, for example:
//
//		float	ADMIN_PWD_1	= 179;
//		float	ADMIN_PWD_2	= 131;
//		float	ADMIN_PWD_3	= 157;
//
// which would give you a password of 179, 131 and 157.  To send this from
// a Quake client, do a bind like this:
//
// bind p "impulse 179;wait;impulse 131;wait;impulse 157"
//
// When you hit p, you'll be granted remote admin functionality.
//
// Currently the only admin functions available right now are kick
// and team change.  They are bound to impulse 151 and impulse 152.
//
// The way it works is after you enter the admin password, do an
// impulse 151/152.  You'll get a list of players on the server with their
// numbers.  Send the next impulse with the number of the player
// to act the command on.

float	ADMIN_PWD_1	= -1;  // change me to first number of the passwd
float	ADMIN_PWD_2	= -1;  // change me to second number of the passwd
float	ADMIN_PWD_3	= -1;  // change me to third number of the passwd

float	ADMIN_KICK = 151;
float	ADMIN_TEAMCHANGE = 152;

void() CheckAdminCmd =
{
	local float n;
	local entity p;
	local string s;

	if (ADMIN_PWD_1 < 0 || ADMIN_PWD_2 < 0 || ADMIN_PWD_3 < 0)
		return; // disabled

	if (self.impulse == ADMIN_PWD_1 && self.accesslvl == 0)
		self.accesslvl = self.accesslvl + 1;

	else if (self.impulse == ADMIN_PWD_2 && self.accesslvl == 1)
		self.accesslvl = self.accesslvl + 1;

	else if (self.impulse == ADMIN_PWD_3 && self.accesslvl == 2) {
		self.accesslvl = self.accesslvl + 1;

		bprint(self.netname);
		bprint(" has become a sysop\n");

		sprint(self, "Admin:\nImpulse ");
		s = ftos(ADMIN_KICK);
		sprint(self, s);
		sprint(self, " to kick\nImpulse ");
		s = ftos(ADMIN_TEAMCHANGE);
		sprint(self, s);
		sprint(self, " to switch teamplayer\n");
		self.accessparm = 0;
		return;
	}

	if (self.accesslvl < 3) {
		self.accessparm = 0;
		return; // must be a sysop beyond this point
	}

	if (self.accessparm == 1) { // kick cmd

		n = self.impulse - 1;
		p = find(world, classname, "player");
		while (p != world && n > 0) {
			p = find(p, classname, "player");
			n = n - 1;
		}

		if (p != world) {
			sprint(p, "\n\nYou have been kicked.\nGo abuse someone else.\n");
			stuffcmd(p, "disconnect\n");
			bprint(p.netname);
			bprint(" was kicked by ");
			bprint(self.netname);
			bprint("\n");
		} else {
			sprint(self, "Can't kick #");
			s = ftos(self.impulse);
			sprint(self, s);
			sprint(self, "\n");
		}

		self.accessparm = 0;
		return;

	} else if (self.accessparm == 2) { // switch teams

		n = self.impulse - 1;
		p = find(world, classname, "player");
		while (p != world && n > 0) {
			p = find(p, classname, "player");
			n = n - 1;
		}

		if (p != world) {
			centerprint(p, "YOU HAVE SWITCHED TEAMS!");
			if (p.lastteam == TEAM_COLOR1 + 1) {
				p.team = p.lastteam = TEAM_COLOR2 + 1;
				s = ftos(TEAM_COLOR2);
			} else {
				p.team = p.lastteam = TEAM_COLOR1 + 1;
				s = ftos(TEAM_COLOR1);
			}
			stuffcmd(p, "color ");
			stuffcmd(p, s);
			stuffcmd(p, "\n");
			bprint(p.netname);
			bprint(" changed teams (by ");
			bprint(self.netname);
			bprint(")\n");
		} else {
			sprint(self, "Can't change #");
			s = ftos(self.impulse);
			sprint(self, s);
			sprint(self, "\n");
		}

		self.accessparm = 0;
		return;
	}

	self.accessparm = 0;

	if (self.impulse == ADMIN_KICK) {

		sprint(self, "Kick:\n");
		p = find(world, classname, "player");
		n = 1;
		while (p != world) {
			s = ftos(n);
			if (n < 10)
				sprint(self, " ");
			sprint(self, s);
			sprint(self, " ");
			sprint(self, p.netname);
			sprint(self, "\n");
			p = find(p, classname, "player");
			n = n + 1;
		}

		self.accessparm = 1;

	} else if (self.impulse == ADMIN_TEAMCHANGE) {

		sprint(self, "Switch:\n");
		p = find(world, classname, "player");
		n = 1;
		while (p != world) {
			s = ftos(n);
			if (n < 10)
				sprint(self, " ");
			sprint(self, s);
			sprint(self, " ");
			sprint(self, p.netname);
			sprint(self, "\n");
			p = find(p, classname, "player");
			n = n + 1;
		}

		self.accessparm = 2;
	}
};

