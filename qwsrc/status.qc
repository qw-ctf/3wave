
.float laststattime;		// time of last status update
.float motd_count;
.float statstate;			// is the status bar on?

float PLAYERSTATTIME = 1.75;

void() MOTD =
{
	if (self.motd_count < 4) {
		self.motd_count = self.motd_count + 1;
		if (self.classname == "spectator") {
			centerprint(self, "Welcome!\nRunning ThreeWave CTF 4.21\n\n??????? ??? ????!\n");
			return;
		}

		if (gamestart) {
			centerprint(self, "Welcome!\nRunning ThreeWave CTF 4.21\n\n??????? ??? ????!\n\nChoose an exit...\n"); //red
			return;
		}
		if (self.steam == TEAM_COLOR1)
			centerprint(self, "Welcome!\nRunning ThreeWave CTF 4.21\n\n??????? ??? ????!\n\nYou are ??? team\n"); //red
		else
			centerprint(self, "Welcome!\nRunning Threewave CTF 4.21\n\n??????? ??? ????!\n\nYou are ???? team"); //blue
		return;
	}
	sprint(self, PRINT_HIGH, "Impulse 70 to turn off status bar\n");
	sprint(self, PRINT_HIGH, "Impulse 71 through 81 to set status bar resolution\n");
	sprint(self, PRINT_HIGH, "71:200 72:240 73:300 74:350 75:384 76:400 77:480 78:600 79:768 81:1024\n");
	self.motd_count = 0;
};

void() MOTD_ChooseTeam =
{
	if (self.motd_count < 6) {
		self.motd_count = self.motd_count + 1;
		centerprint(self, "Welcome!\nRunning ThreeWave CTF 4.2\n\n??????? ??? ????!\n\nPress 1 for ??? team\nPress 2 for ???? team\nOr Press Jump for automatic team\n");
		return;
	}
	self.motd_count = 0;
};

void() TeamCaptureCheckUpdate =
{
	local entity p;

	if (gamestart)
		return; // handled by vote exit
	if (lastteamscrtime > time)
		return;

	lastteamscrtime = time + TEAMSCRTIME;

	// count up teamscr
	teamscr1 = teamscr2 = 0;
	p = find(world, classname, "player");
	while (p != world) {
		if (p.steam == TEAM_COLOR1)
			teamscr1 = teamscr1 + p.frags;
		else if (p.steam == TEAM_COLOR2)
			teamscr2 = teamscr2 + p.frags;
		p = find(p, classname, "player");
	}
};

void() TeamCaptureResetUpdate =
{
	lastteamscrtime = 0;
	TeamCaptureCheckUpdate();
};

void() TeamEndScore =
{
	local string s;

	if (gamestart)
		return;

	lastteamscrtime = 0;
	TeamCaptureCheckUpdate();

	if (teamscr1 > teamscr2) {
		bprint(PRINT_HIGH, "??? team won the level with ");
		s = ftos(teamscr1);
		bprint(PRINT_HIGH, s);
		bprint(PRINT_HIGH, " points!\n");
		bprint(PRINT_HIGH, "???? team lost with ");
		s = ftos(teamscr2);
		bprint(PRINT_HIGH, s);
		bprint(PRINT_HIGH, " points.\n");
	} else if (teamscr1 < teamscr2) {
		bprint(PRINT_HIGH, "???? team won the level with ");
		s = ftos(teamscr2);
		bprint(PRINT_HIGH, s);
		bprint(PRINT_HIGH, " points!\n");
		bprint(PRINT_HIGH, "??? team lost with ");
		s = ftos(teamscr1);
		bprint(PRINT_HIGH, s);
		bprint(PRINT_HIGH, " points.\n");
	} else {
		bprint(PRINT_HIGH, "???? and ??? team tied level with ");
		s = ftos(teamscr1);
		bprint(PRINT_HIGH, s);
		bprint(PRINT_HIGH, " points!\n");
	}
};

string(entity who) TeamSetStatRes =
{
	if (who.statstate > 7) // 768
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 7) // 600
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 6) // 480
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 5) // 400
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 4) // 384
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 3) // 350
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 2) // 300
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 1) // 240
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	// 200
	return "\n\n\n\n\n\n\n\n\n\n\n\n";
};

string(entity who) TeamSetStatRes2 =
{
	if (who.statstate > 7) // 768
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 7) // 600
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 6) // 480
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 5) // 400
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 4) // 384
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 3) // 350
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 2) // 300
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 1) // 240
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	// 200
	return "\n\n\n\n\n\n\n\n\n\n\n";
};

void() TeamCapturePlayerUpdate =
{
	local entity e;
	local string n, t, s1, s2, s3, res;

	if (self.laststattime > time)
		return;

	TeamCaptureCheckUpdate();

	self.laststattime = time + PLAYERSTATTIME;

	if (self.motd_count) {
		MOTD();
		return;
	}

	if (self.statstate < 0)
		return;

	res = TeamSetStatRes(self);

	if (gamestart) {
		if (vote_leader == world)
			centerprint2(self, res, "                    Choose an exit...");
		else {
			res = TeamSetStatRes2();
			n = ftos(voteexit_time - time);
			centerprint5(self, res, vote_leader.message,
				" leads\n", n, " seconds until exit");
		}
		return;
	}

	//.1234567890123456789012345678901234567
	// Res.R.B.             Capture The Flag
	// Res.R.B.                     BLUE 999

	if (self.player_flag & ITEM_RUNE1_FLAG)
		s1 = "Resist  ?";
	else if (self.player_flag & ITEM_RUNE2_FLAG)
		s1 = "Strength?";
	else if (self.player_flag & ITEM_RUNE3_FLAG)
		s1 = "Haste   ?";
	else if (self.player_flag & ITEM_RUNE4_FLAG)
		s1 = "Regen   ?";
	else
		s1 = "        ?";

	e = find(world, classname, "item_flag_team1");
	if (e.cnt == FLAG_AT_BASE)
		s2 = " ?";
	else if (e.cnt == FLAG_CARRIED)
		s2 = "R?";
	else
		s2 = "҅";

	e = find(world, classname, "item_flag_team2");
	if (e.cnt == FLAG_AT_BASE)
		s3 = " ?";
	else if (e.cnt == FLAG_CARRIED)
		s3 = "B?";
	else
		s3 = "";

	if (teamscr1 == 0 && teamscr2 == 0) {
		centerprint5(self, res, s1, s2, s3, "         Capture The Flag");		// CTFBOT
		return;
	}

	if (time < (last_flag_capture + 6))
	{
		if (last_capture_team == TEAM_COLOR1)
		{
			if (teamscr1 > teamscr2) {
				t = "Red Capture!   RED ";
				n = ftos(teamscr1 - teamscr2);
			} else if (teamscr1 < teamscr2) {
				t = "Red Capture!  BLUE ";
				n = ftos(teamscr2 - teamscr1);
			} else {
				t = "Red Capture!  TIED ";
				n = "";
			}
		}
		else
		{
			if (teamscr1 > teamscr2) {
				t = "Blue Capture!  RED ";
				n = ftos(teamscr1 - teamscr2);
			} else if (teamscr1 < teamscr2) {
				t = "Blue Capture! BLUE ";
				n = ftos(teamscr2 - teamscr1);
			} else {
				t = "Blue Capture! TIED ";
				n = "";
			}
		}
	}
	else
	{
		if (teamscr1 > teamscr2) {
			t = "               RED ";
			n = ftos(teamscr1 - teamscr2);
		} else if (teamscr1 < teamscr2) {
			t = "              BLUE ";
			n = ftos(teamscr2 - teamscr1);
		} else {
			t = "              TIED ";
			n = "";
		}
	}
	centerprint7(self, res, s1, s2, s3, "    ", t, n);		//
};

void(entity who, string s) TeamPlayerUpdate =
{
	local string n, res;

	TeamCaptureCheckUpdate();
	who.laststattime = time + PLAYERSTATTIME;

	if (who.statstate < 0) {
		centerprint(who, s);
		return;
	}

	res = TeamSetStatRes2(who);

	if (teamscr1 == 0 && teamscr2 == 0) {
		centerprint3(who, res, s, "\n                       Capture The Flag");
	} else if (teamscr1 > teamscr2) {
		n = ftos(teamscr1 - teamscr2);
		centerprint4(who, res, s, "\n                               RED ", n);
	} else if (teamscr1 < teamscr2) {
		n = ftos(teamscr2 - teamscr1);
		centerprint4(who, res, s, "\n                               BLUE ", n);
	} else
		centerprint3(who, res, s, "\n                               TIED");
};

void(entity who, string s1, string s2) TeamPlayerUpdate2 =
{
	local string n, res;

	TeamCaptureCheckUpdate();
	who.laststattime = time + PLAYERSTATTIME;

	if (who.statstate < 0) {
		centerprint2(who, s1, s2);
		return;
	}

	res = TeamSetStatRes2(who);

	if (teamscr1 == 0 && teamscr2 == 0) {
		centerprint4(who, res, s1, s2, "\n                       Capture The Flag");
		return;
	} else if (teamscr1 > teamscr2) {
		n = ftos(teamscr1 - teamscr2);
		centerprint5(who, res, s1, s2, "\n                               RED ", n);
	} else if (teamscr1 < teamscr2) {
		n = ftos(teamscr2 - teamscr1);
		centerprint5(who, res, s1, s2, "\n                               BLUE ", n);
	} else {
		centerprint4(who, res, s1, s2, "\n                               TIED");
		return;
	}
};

