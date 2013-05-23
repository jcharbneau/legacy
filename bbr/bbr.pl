#!/usr/bin/perl
#
# 
#
#use warnings;
#use strict;
my $DEBUG		= 0;
my $SSHBIN		= "/usr/bin/ssh";
my $CONFIG		= "bbr.conf";

# Holds our config information
my($ip, $nickname, $scripts);

# Variables used later on in script
my($jvmselection, $selection, $ans);

# Cmd variables
my($cmd, $newcmd);

# Define counters
my $cnt			= 0;
my $scriptcnt		= 0;

# Result array, used to get a listing of all restart scripts
my @results;

# Open config file
open(CONF,$CONFIG) || die "Could not find my config:\n   $CONFIG\n   $!\n";

while(<CONF>) {
        s/\s*#.*$//;            # Zap comments
        s/(^\s+)|(\s+$)//;      # Zap leading/trailing whitespace
        next if /^$/;           # Zap blank lines

        # Split the variable out of the config
        ($ip, $nickname,$scripts) = split(/\s+/);

	if($DEBUG==1){print "config:$_:\n"};

	# Load the arrays
	$nickname{$nickname} = $nickname;
	$ip{$nickname} = $ip;
	$scripts{$nickname} = $scripts;
}

close(CONF);

# loop indefinitely, so that the user is forced
#  to make a selection from the seudo menu
while (1) {
	# Ask which server
	print "Please select which server:\n";
	for my $nickname ( sort keys %nickname) {
		print "  $cnt: $nickname\n";
		$server{$nickname} = $cnt;
		$cnt++;
	}

	# Get the answer
	$jvmselection = <>;

	chomp($jvmselection);
	# Validate the answer
	if($jvmselection =~ /\d/) {
	   # Check that the selection was valid against our counters
	   foreach $nickname (sort keys %server) {
		if($DEBUG==1) {
			print "\tnickname:$nickname:\n";
			print "\tjvmselection:$jvmselection:\n";
			print "\tserver:$server{$nickname}:\n";
		}
	 	if($jvmselection =~ $server{$nickname}) { 
			# Set the hostjvm variable
			$jvmhost = $nickname;
			# Add the valid flag (see error check below)
			$valid++; 
		} 
	   }

	   if($valid) {
		# DEBUGGING
		if($DEBUG == 1) {print "\tserver selected was valid\n";}
		last;  # Make this the last loop
	   } else {
		print "Selection was not a valid jvm.\n";
		$cnt = 0;
		next;
	   }	
	} else {
	   # The selection was not valid
	   print "Selection was not a valid number.\n";
	   $cnt = 0; # Reset the counter
	   next; # loop again
	}
}

# Log into the server via ssh (shared keys) and get the script listing
$cmd = "$SSHBIN $ip{$jvmhost} 'ls $scripts{$jvmhost}'";
@results = `$cmd`;

while(1) {
	# Spit out the listing for selection
	print "Available scripts are:\n";

	foreach $script (@results) {
		# Cut the newline crap off the end
		chomp($script);
	
		# Print out our "seudo" menu
		print "  $scriptcnt: $script\n";

		# Add the script to our hash
		$JVMSCRIPTS_INDEXED{$scriptcnt} = $script;
	
		# DEBUGGING
		if($DEBUG == 1) {
			print("\tcnt is:$scriptcnt:\n");
			print("\tscript is:" . $JVMSCRIPTS_INDEXED{$scriptcnt} . ":\n");
		}

		# Increment our counter
		$scriptcnt++;
	}

	# Prompt the user to select a script
	print "\nPlease select which script to execute.\n";
	my $selection = <>;

	# Cut the newline crap off the end of the variable
	chomp($selection);

	if($selection =~ /\d/) {
		foreach $script (sort keys %JVMSCRIPTS_INDEXED) {
			if($selection =~ $script){
				$execScript = $JVMSCRIPTS_INDEXED{$script};
				$validjvm++;
			}
		}
		
		if($validjvm) {
			last;
		} else {
			print "Selection was not a valid jvm.\n";
			$scriptcnt = 0;
			next;
		}
	} else {
		print "Selection was not a valid number.\n";
		$scriptcnt = 0;
		next;
	}
}

if($execScript) { 
	print "Host is:\t$jvmhost\n";
	print "Script is:\t$execScript\n";
	print "\nIs this correct? Y|N\n";
	$ans = <>;

	# Cut the newline crap off the end
	chomp($ans);

	# If they said y|Y then execute the script
	if(($ans eq "y") || ($ans eq "Y"))  {
		$newcmd = "$SSHBIN -f $ip{$jvmhost} $execScript";
		print "Executing command:\n\t$newcmd\n";
		system($newcmd);
	} elsif(($ans eq "n") || ($ans eq "N")) {
		print "You answered no.  I am exiting....\n";
		exit;
	} else {
		print "Unexpected reply, exiting\n";
		exit;
	}
}
