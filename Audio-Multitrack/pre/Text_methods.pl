use Carp;
sub new { my $class = shift; return bless { @_ }, $class; }

sub show_versions {
 	print "All versions: ", join " ", @{$::this_track->versions}, $/;
}

sub show_effects {
 	map { 
 		my $op_id = $_;
 		 my $i = $effect_i{ $cops{ $op_id }->{type} };
 		 print $op_id, ": " , $effects[ $i ]->{name},  " ";
 		 my @pnames =@{$effects[ $i ]->{params}};
			map{ print join " ", 
			 	$pnames[$_]->{name}, 
				$copp{$op_id}->[$_],'' 
		 	} (0..scalar @pnames - 1);
		 print $/;
 
 	 } @{ $this_track->ops };
}
sub show_modifiers {
	print "Modifiers: ",$this_track->modifiers, $/;
}


sub loop {

	# first setup Term::Readline::GNU

	# we are using Event's handlers and event loop

	package ::;
	my $prompt = "Enter command: ";
	$term = new Term::ReadLine("Ecasound/Nama");
	my $attribs = $term->Attribs;
	$term->callback_handler_install($prompt, \&::Text::process_line);

	# store output buffer in a scalar (for print)
	my $outstream=$attribs->{'outstream'};

	# install STDIN handler
	$event_id{stdin} = Event->io(
		desc   => 'STDIN handler',           # description;
		fd     => \*STDIN,                   # handle;
		poll   => 'r',	                   # watch for incoming chars
		cb     => sub{ &{$attribs->{'callback_read_char'}}() }, # callback;
		repeat => 1,                         # keep alive after event;
	 );

	$event_id{Event_heartbeat} = Event->timer(
		parked => 1, 						# start it later
	    desc   => 'heartbeat',               # description;
	    prio   => 5,                         # low priority;
		interval => 3,
	    cb     => \&::heartbeat,               # callback;
	);
	Event::loop();

}
sub wraparound {
	@_ = ::discard_object @_;
	my ($diff, $start) = @_;
	#print "diff: $diff, start: $start\n";
	$event_id{Event_wraparound}->cancel()
		if defined $event_id{Event_wraparound};
	$event_id{Event_wraparound} = Event->timer(
	desc   => 'wraparound',               # description;
	after  => $diff,
	cb     => sub{ ::eval_iam("setpos " . $start) }, # callback;
   );

}


sub start_heartbeat {$event_id{Event_heartbeat}->start() }

sub stop_heartbeat {$event_id{Event_heartbeat}->stop() }

sub cancel_wraparound {
	$event_id{Event_wraparound}->cancel() if defined $event_id{Event_wraparound}
}

sub process_line {
  $debug2 and print "&process_line\n";
  my ($user_input) = @_;
  $debug and print "user input: $user_input\n";

  if (defined $user_input and $user_input !~ /^\s*$/)
    {
    $term->addhistory($user_input) 
	 	unless $user_input eq $previous_text_command;
 	$previous_text_command = $user_input;
	command_process( $user_input );
    }
}


sub command_process {

	package ::;
	my ($user_input) = shift;
	return if $user_input =~ /^\s*$/;
	$debug and print "user input: $user_input\n";
	my ($cmd, $predicate) = ($user_input =~ /([\S]+)(.*)/);
	if ($cmd eq 'eval') {
			$debug and print "Evaluating perl code\n";
			print eval $predicate;
			print "\n";
			$@ and print "Perl command failed: $@\n";
	}
	elsif ( $cmd eq '!' ) {
			$debug and print "Evaluating shell commands!\n";
			system $predicate;
			print "\n";
	} else {


	my @user_input = split /\s*;\s*/, $user_input;
	map {
		my $user_input = $_;
		my ($cmd, $predicate) = ($user_input =~ /([\S]+)(.*)/);
		$debug and print "cmd: $cmd \npredicate: $predicate\n";
		if ($cmd eq 'eval') {
			$debug and print "Evaluating perl code\n";
			print eval $predicate;
			print "\n";
			$@ and print "Perl command failed: $@\n";
		} elsif ($cmd eq '!') {
			$debug and print "Evaluating shell commands!\n";
			system $predicate;
			print "\n";
		} elsif ($tn{$cmd}) { 
			$debug and print qq(Selecting track "$cmd"\n);
			$this_track = $tn{$cmd};
			$predicate !~ /^\s*$/ and $parser->command($predicate);
		} elsif ($cmd =~ /^\d+$/ and $ti[$cmd]) { 
			$debug and print qq(Selecting track ), $ti[$cmd]->name, $/;
			$this_track = $ti[$cmd];
			$predicate !~ /^\s*$/ and $parser->command($predicate);
		} elsif ($iam_cmd{$cmd}){
			$debug and print "Found Iam command\n";
			print eval_iam($user_input), $/ ;
		} else {
			$debug and print "Passing to parser\n", 
			$_, $/;
			#print 1, ref $parser, $/;
			#print 2, ref $::parser, $/;
			# both print
			$parser->command($_) 
		}    
	} @user_input;
	}
	$ui->refresh; # in case we have a graphic environment
	# package :: scope ends here
}
sub show_tracks {
    no warnings;
    my @tracks = @_;
    map {     push @format_fields,  
            $_->n,
            $_->name,
            $_->rw,
            $_->rec_status,
            $_->rec_status eq 'REC' ? $_->ch_r : '',
            $_->current_version || '',
            #(join " ", @{$_->versions}),

        } grep{ ! $_-> hide} @tracks;
        
    write; # using format below
    $- = 0; # $FORMAT_LINES_LEFT # force header on next output
    1;
    use warnings;
    no warnings q(uninitialized);
}

format STDOUT_TOP =
Track  Name        Setting  Status  Input  Version 
==================================================
.
format STDOUT =
@>>    @<<<<<<<<<    @<<<    @<<<    @>>     @>>>   ~~
splice @format_fields, 0, 6
.

sub helpline {
	my $cmd = shift;
	my $text = "Command: $cmd\n";
	$text .=  "Shortcuts: $commands{$cmd}->{short}\n"
			if $commands{$cmd}->{short};	
	$text .=  $commands{$cmd}->{what}. $/;
	$text .=  "parameters: ". $commands{$cmd}->{parameters} . $/
			if $commands{$cmd}->{parameters};	
	$text .=  "example: ". eval( qq("$commands{$cmd}->{example}") ) . $/  
			if $commands{$cmd}->{example};
	print( $/, ucfirst $text, $/);
	
}
sub helptopic {
	my $index = shift;
	$index =~ /^\d+$/ and $index = $help_topic[$index];
	print "\n-- ", ucfirst $index, " --\n\n";
	print $help_topic{$index};
	print $/;
}

sub help { 
	my $name = shift;
	chomp $name;
	#print "seeking help for argument: $name\n";
	$iam_cmd{$name} and print <<IAM;

$name is an Ecasound command.  See 'man ecasound-iam'.
IAM
	$help_topic{$name} and helptopic($name), return;
	$name == 10 and (map{ helptopic $_ } @help_topic), return;
	$name =~ /^\d+$/ and helptopic($name), return;

	$commands{$name} and helpline($name), return;
	my %helped = (); 
	map{  my $cmd = $_ ;
		
		helpline($cmd), $helped{$cmd}++ if $cmd =~ /$name/;

		  # print ("commands short: ", $commands{$cmd}->{short}, $/),
	      helpline($cmd) 
		  	if grep { /$name/ } split " ", $commands{$cmd}->{short} 
				and ! $helped{$cmd};
	} keys %commands;
	# e.g. help tap_reverb
	if ( $effects_ladspa{"el:$name"}) {
	print "$name is the code for the following LADSPA effect:\n";
	#print yaml_out( $effects_ladspa{"el:$name"});
    print qx(analyseplugin $name);
	}
	
}

# are these subroutines so different from what's in Core_subs.pl?

package ::;

sub t_load_project {
	my $name = shift;
	my $untested = remove_spaces($name);
	print ("Project $untested does not exist\n"), return
		unless -d join_path project_root(), $untested; 
	load_project( name => remove_spaces($name) );

	print "loaded project: $project_name\n";
}
    
sub t_create_project {
	my $name = shift;
	load_project( 
		name => remove_spaces($name),
		create => 1,
	);
	print "created project: $project_name\n";

}
sub t_add_ctrl {
	my ($parent, $code, $values) = @_;
	print "code: $code, parent: $parent\n";
	$values and print "values: ", join " ", @{$values};
	if ( $effect_i{$code} ) {} # do nothing
	elsif ( $effect_j{$code} ) { $code = $effect_j{$code} }
	else { warn "effect code not found: $code\n"; return }
	print "code: ", $code, $/;
		my %p = (
				chain => $cops{$parent}->{chain},
				parent_id => $parent,
				values => $values,
				type => $code,
			);
			print "adding effect\n";
			# print (yaml_out(\%p));
		add_effect( \%p );
}
sub t_add_effect {
	my ($code, $values)  = @_;
	if ( $effect_i{$code} ) {} # do nothing
	elsif ( $effect_j{$code} ) { $code = $effect_j{$code} }
	else { warn "effect code not found: $code\n"; return }
	print "code: ", $code, $/;
		my %p = (
			chain => $this_track->n,
			values => $values,
			type => $code,
			);
			print "adding effect\n";
			#print (yaml_out(\%p));
		add_effect( \%p );
}
