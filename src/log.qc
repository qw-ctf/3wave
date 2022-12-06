
void(entity targ, entity attacker, string what) LogPlayerDMDeath =
{
	// note embedded tabs in the next string
	localcmd("echo ");
	localcmd("LOG:	DEATH	");
	localcmd(targ.netname);
	localcmd("/");
	localcmd(ftos(targ.frags));
	localcmd("	");
	localcmd(attacker.netname);
	localcmd("/");
	localcmd(ftos(attacker.frags));
	localcmd("	");
	localcmd(what);
	localcmd("\n");
};

void (entity targ, string what) LogPlayerDeath =
{
	localcmd("echo ");
	localcmd("LOG:	DEATH	");
	localcmd(targ.netname);
	localcmd("/");
	localcmd(ftos(targ.frags));
	localcmd("	");
	localcmd(what);
	localcmd("\n");
};

void (entity who, string what) LogMsg =
{
	localcmd("echo ");
	localcmd("LOG:	");
	localcmd(what);
	localcmd("	");
	localcmd(who.netname);
	localcmd("\n");
};
