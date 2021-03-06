# $Id: 98_AlarmControl.pm $

package main;

use strict;
use warnings;
use MIME::Base64;

my $version = "0.5.3.5";

my %gets = (
  "status:noArg"    =>  "",
  "version:noArg"   =>  "",
);

# Arm Steps
my %armSteps;
$armSteps{-1}{"count"}                =   8;
$armSteps{-1}{"state"}                =   "off";
$armSteps{-1}{"sub"}                  =   "off";
$armSteps{-1}{"attributes"}           =   "AM_allowedUnarmEvents:textField-long ".  #level:devspec|eventRegex|text ($ALIAS,$SENSOR,$SENSORALIAS)
                                          "AM_offMsg:textField-long ".
                                          "AM_offCmds:textField-long ";             #FHEM commands - special $TND = triggeredNotifyDevices as or-Regex (example: DEVICE1|DEVICE2)
$armSteps{-1}{"cmdAttribute"}         =   "AM_offCmds";                               

$armSteps{1}{"state"}                 =   "arming";
$armSteps{1}{"sub"}                   =   "on";
$armSteps{1}{"attributes"}            =   "AM_armDelay:textField-long ".
                                          "AM_armingCmds:textField-long ".          #level:FHEM commands
                                          "AM_armStatesWarn:textField-long ".       #level:devspec|perl condition in {}|text ($ALIAS,$SENSOR,$SENSORALIAS)
                                          "AM_armStatesDeny:textField-long ".       #level:devspec|perl condition in {}|text ($ALIAS,$SENSOR,$SENSORALIAS)
                                          "AM_armStatesWarnCmds:textField-long ".   #FHEM commands
                                          "AM_armStatesDenyCmds:textField-long ".   #FHEM commands  
                                          "AM_warnTextPrefix ".
                                          "AM_denyTextPrefix ";
                                            
$armSteps{1}{"cmdAttribute"}          =   "AM_armingCmds";
                                         
$armSteps{2}{"state"}                 =   "on";
$armSteps{2}{"sub"}                   =   "on";
$armSteps{2}{"attributes"}            =   "AM_step3Delay ".
                                          "AM_step3DelaySilent:1,0 ".
                                          "AM_onCmds:textField-long ".
                                          "AM_onMsg:textField-long ";               #level:FHEM commands
$armSteps{2}{"cmdAttribute"}          =   "AM_onCmds";
                                          
$armSteps{3}{"state"}                 =   "on";
$armSteps{3}{"sub"}                   =   "on";
$armSteps{3}{"attributes"}            =   "AM_step4Delay ".
                                          "AM_step4DelaySilent:1,0 ".
                                          "AM_on1Cmds:textField-long ";             #level:FHEM commands
$armSteps{3}{"cmdAttribute"}          =   "AM_on1Cmds";
                                          
$armSteps{4}{"state"}                 =   "on";
$armSteps{4}{"sub"}                   =   "on";
$armSteps{4}{"attributes"}            =   "AM_on2Cmds:textField-long ";             #level:FHEM commands
$armSteps{4}{"cmdAttribute"}          =   "AM_on2Cmds";

$armSteps{5}{"state"}                 =   "triggered";
$armSteps{5}{"sub"}                   =   "alarm";
$armSteps{5}{"attributes"}            =   "AM_step6Delay ".
                                          "AM_step6DelaySilent:1,0 ".
                                          "AM_triggeredCmds:textField-long ".       #level:FHEM commands
                                          "AM_triggeredCountdownCmds:textField-long ".
                                          "AM_triggeredNotifyDevs:textField-long "; # devspec
$armSteps{5}{"cmdAttribute"}          =   "AM_triggeredCmds";
                                          
$armSteps{6}{"state"}                 =   "alarm";
$armSteps{6}{"sub"}                   =   "alarm";
$armSteps{6}{"attributes"}            =   "AM_step7Delay ".
                                          "AM_step7DelaySilent:1,0 ".
                                          "AM_alarmStep1Cmds:textField-long ";      #level:FHEM commands
$armSteps{6}{"cmdAttribute"}          =   "AM_alarmStep1Cmds";
                                          
$armSteps{7}{"state"}                 =   "alarm";
$armSteps{7}{"sub"}                   =   "alarm";
$armSteps{7}{"attributes"}            =   "AM_step8Delay ".
                                          "AM_step8DelaySilent:1,0 ".
                                          "AM_alarmStep2Cmds:textField-long ";      #level:FHEM commands
$armSteps{7}{"cmdAttribute"}          =   "AM_alarmStep2Cmds";
                                          
$armSteps{8}{"state"}                 =   "alarm";
$armSteps{8}{"sub"}                   =   "alarm";
$armSteps{8}{"attributes"}            =   "AM_alarmStep3Cmds:textField-long ";      #level:FHEM commands
$armSteps{8}{"cmdAttribute"}          =   "AM_alarmStep3Cmds";

sub AlarmControl_Initialize($) {
  my ($hash) = @_;

  $hash->{SetFn}        =   "AlarmControl::Set";
  $hash->{GetFn}        =   "AlarmControl::Get";
  $hash->{DefFn}        =   "AlarmControl::Define";
  $hash->{NotifyFn}     =   "AlarmControl::Notify";
  $hash->{UndefFn}      =   "AlarmControl::Undefine";
  $hash->{DeleteFn}     =   "AlarmControl::Delete";
	$hash->{AttrFn}       =   "AlarmControl::Attr";
	$hash->{onFn}         =   "AlarmControl::doOn";
	$hash->{offFn}        =   "AlarmControl::doOff";
	$hash->{alarmFn}      =   "AlarmControl::doAlarm";
	#$hash->{FW_detailFn}  =   "AlarmControl::detailFn";
	#$hash->{FW_summaryFn} =   "AlarmControl::summaryFn";
	
	
  $hash->{AttrList}     =   #"disable:1,0 ".
											      #"disabledForIntervals ".
											      "AM_armLevelCount:1,2,3,4,5,6,7,8,9,10 ".
                            "AM_sensors:textField-long ".                             #level:devspec|eventRegex|text ($ALIAS,$SENSOR,$SENSORALIAS)
                            "AM_notifyEvents:textField-long ".                        #level:devspec|eventRegex|text ($ALIAS,$SENSOR,$SENSORALIAS,$COUNT,$PLURALE,$PLURALS)
                            "AM_disarmErrorCmds:textField-long ".                     #FHEM commands 
                            "AM_showDetailWidget:1,0 ".              
                            $armSteps{-1}{"attributes"}.
                            $armSteps{1}{"attributes"}.
                            $armSteps{2}{"attributes"}.
                            $armSteps{3}{"attributes"}.
                            $armSteps{4}{"attributes"}.
                            $armSteps{5}{"attributes"}.
                            $armSteps{6}{"attributes"}.
                            $armSteps{7}{"attributes"}.
                            $armSteps{8}{"attributes"}.
                            "userattr:textField-long ".
											      $readingFnAttributes;
											  
	$hash->{NotifyOrderPrefix} = "11-";    # order number NotifyFn
	
	## renew version in reload
  foreach my $d ( sort keys %{ $modules{AlarmControl}{defptr} } ) {
      my $hash = $modules{AlarmControl}{defptr}{$d};
      $hash->{VERSION} = $version;
  }
	return undef;
}


## Package
package AlarmControl;

use GPUtils qw(:all);    # for importing FHEM functions
use Data::Dumper;    #only for Debugging
use Date::Parse;
use MIME::Base64;

my $missingModul = "";
#eval "use JSON qw(decode_json encode_json);1" or $missingModul .= "JSON ";

## import FHEM functions
BEGIN {
    GP_Import(
        qw(devspec2array
          readingsSingleUpdate
          readingsBulkUpdate
          readingsBulkUpdateIfChanged
          readingsBeginUpdate
          readingsEndUpdate
          defs
          modules
          Log3
          CommandAttr
          attr
          AnalyzeCommandChain
          AnalyzePerlCommand
          EvalSpecials
          CommandDeleteAttr
          CommandDeleteReading
          CommandSet
          AttrVal
          ReadingsVal
          Value
          IsDisabled
          deviceEvents
          init_done
          addToDevAttrList
          addToAttrList
          delFromDevAttrList
          delFromAttrList
          gettimeofday
          InternalTimer
          RemoveInternalTimer
          computeAlignTime
          ReplaceEventMap
          getKeyValue
          setKeyValue
          getUniqueId
          CallFn
          FW_ME
          FW_dev2image
          FW_makeImage
          FW_directNotify
          notifyRegexpChanged)
    );
}

sub Define($$) {
    my ( $hash, $def ) = @_;
    my @a = split( "[ \t][ \t]*", $def );
    
    return "only one AlarmControl instance allowed" if ( devspec2array('TYPE=AlarmControl') > 1 );
    return "too few parameters: define <name> AlarmControl" if ( @a != 2 );
    return "Cannot define AlarmControl device. Perl modul ${missingModul}is missing." if ($missingModul);
    
    my $name = $a[0];

    $hash->{VERSION} = $version;
    $hash->{MID}     = 'da39a3ee5e6dfdss434b0d3255bfef95601890afd80709'; # 
    $hash->{NOTIFYDEV} = "global" if (ReadingsVal($name,"state","-") ne "on");    # notify devices (NotifyFn)
    
    Log3( $name, 3, "AlarmControl [$name] - defined" );

    $modules{AlarmControl}{defptr}{ $hash->{MID} } = $hash; #MID for internal purposes
    
    # set default attributes
    CommandAttr( undef, $name . ' room Alarm' ) if ( AttrVal( $name, 'room', 'none' ) eq 'none' );
    CommandAttr( undef, $name . ' AM_armLevelCount 3' ) if ( AttrVal( $name, 'AM_armLevelCount', -1 ) eq -1 );
    CommandAttr( undef, $name . ' AM_armDelay 240' ) if ( AttrVal( $name, 'AM_armDelay', -1 ) eq -1 );
    CommandAttr( undef, $name . ' AM_offMsg Die Alarmanlage wurde erfolgreich ausgeschaltet!' ) if ( AttrVal( $name, 'AM_offTMsg', -1 ) eq -1 );
    CommandAttr( undef, $name . ' AM_onMsg Die Alarmanlage wurde scharf gestellt!' ) if ( AttrVal( $name, 'AM_onTMsg', -1 ) eq -1 );
    CommandAttr( undef, $name . ' AM_warnTextPrefix Achtung!' ) if ( AttrVal( $name, 'AM_warnTextPrefix', -1 ) eq -1 );
    CommandAttr( undef, $name . ' AM_denyTextPrefix Warnung: Die Alarmanlage konnte nicht eingeschaltet werden!' ) if ( AttrVal( $name, 'AM_denyTextPrefix', -1 ) eq -1 );
    
    my $index = $hash->{TYPE}."_".$hash->{NAME}."_passwd";
	  my ($err, $password) = getKeyValue($index);
	
	  $hash->{helper}{PWD_NEEDED}=1 if ($err || !$password);
	  
	  $hash->{helper}{armSteps}= \%armSteps;
	  
	  
	  if ($init_done) {
      readingsSingleUpdate($hash,"state","inactive",1) if (ReadingsVal($name,"state","-") eq "-");
    }
	
    RemoveInternalTimer($hash);

    $hash->{helper}{wrongPwd} = "";
    $hash->{helper}{commandText} = "";
    
    return undef;
}

sub Undefine($$) {
  my ($hash, $arg) = @_;
  
  RemoveInternalTimer($hash);
  
  return undef;
}

# If Device is deleted, delete the password data
sub Delete($$) {
  my ($hash, $name) = @_;  
  
  my $old_index = $hash->{TYPE}."_".$name."_passwd";
  
  my $old_key =getUniqueId().$old_index;
  
  my ($err, $old_pwd) = getKeyValue($old_index);
  
  return undef unless(defined($old_pwd));
      
  setKeyValue($old_index, undef);

  
  Log3 $name, 3, "AlarmControl: device $name as been deleted. Passwords have been deleted too.";
}

sub Set($@) {
  my ($hash, $name, $cmd, @args) = @_;
	
	my @sets = ();
	
	# level count for arm levels
	my $levels=AttrVal($name,"AM_armLevelCount",3);
	my $aLevels="";
	for (my $i=1;$i<=$levels;$i++) {
		$aLevels.="," if ($i!=1);
		$aLevels.=$i;
	}
	
	my $state = ReadingsVal($name,"state","off");
	
	# set commmands by filter
	push @sets, "on:$aLevels" if(!$hash->{helper}{PWD_NEEDED} && ReadingsVal($name,"state","off") eq "off" && !IsDisabled($name));
	push @sets, "off:textField" if(!$hash->{helper}{PWD_NEEDED} && ReadingsVal($name,"state","off") !~ /^(off|inactive)$/ && !IsDisabled($name));
	push @sets, "passwords" if($hash->{helper}{PWD_NEEDED});
	push @sets, "setPasswords" if(!$hash->{helper}{PWD_NEEDED});
	push @sets, "active:noArg" if(!$hash->{helper}{PWD_NEEDED} && IsDisabled($name));
	push @sets, "level:$aLevels" if(!$hash->{helper}{PWD_NEEDED} && ReadingsVal($name,"state","off") !~ /^(off|inactive)$/ && !IsDisabled($name));
	
	return join(" ", @sets) if (defined($cmd) && $cmd eq "?");
	
	if (IsDisabled($name) && $cmd !~ /^(active|inactive|.*assword.)?$/) {
    Log3 $name, 3, "AlarmControl [$name]: Device is disabled at set Device $cmd";
    return "Device is disabled. Enable it on order to use command ".$cmd;
  }
	
	my $usage = "Unknown argument ".$cmd.", choose one of ".join(" ", @sets) if(scalar @sets > 0);
	
	# check for valid set commands
	if ( defined($cmd) && $cmd =~ /^on|off|level|passwords|active|set(P|p)asswords$/ ) {
	  return "AlarmControl [$name] Invalid argument to set $cmd, has to be numeric" if ( $cmd =~ /^(on|level)$/ && $args[0] !~ /\d+/ );
		return "AlarmControl [$name] Invalid argument to set $cmd, has to be 1 < arg < $levels" if ( $cmd =~ /^(on|level)$/ && (($args[0] > $levels)||($args[0]<1)) );
		return "AlarmControl [$name] Invalid argument to set $cmd, has to be <password1> <password2> [...]. <passwords> has to be numeric." if ($cmd =~ /^(newP|p)asswords?$/ && !@args && $args[0] !~ /\d+/ && $args[1] !~ /\d+/); 
    
    # activate instance
    if ( $cmd eq "active") {
      return "Device $name is already active!" if (!IsDisabled($name));
      activate($hash,$name);
    }
    
    # arm 	
	  elsif ( $cmd eq "on" || $cmd eq "off" ) {
	    
	    my $step = $cmd eq "on"?1:-1;
	   
	    # if device ist active
	    if (!$hash->{helper}{PWD_NEEDED} && !IsDisabled($name)) {
	      if (($cmd eq "on" && $state eq "off" && $args[0] =~/^-?\d+$/ && $args[0]>0 && $args[0]<=AttrVal($name,"AM_armLevelCount",3)) || $cmd eq "off") {
	        setState($hash,$name,$step,$args[0]);
	      }
	      else {
	        if ($state ne "off" && $cmd eq "on") {
	          error($hash,$name,"AlarmControl [$name]: Cannot arm. Device is already armed");
            return "Cannot arm. Device is already armed";
	        }
	        error($hash,$name,"AlarmControl [$name]: Cannot arm with level: ".$args[0],2);
          return "Cannot arm with level: ".$args[0];
        }
	    }
	    # if device ist inactive
	    else {
	      error($hash,$name,"AlarmControl [$name]:  Could not be (un)armed. Device is disabled or Password is not set",2);
				return "$name could not be (un)armed. Device is disabled or Password is not set.";
	    }
	    
    }
    elsif ($cmd eq "level") {
      if ($args[0] =~/^-?\d+$/ && $args[0]>0 && $args[0]<=AttrVal($name,"AM_armLevelCount",3)) {
        readingsSingleUpdate($hash,"level",$args[0],1);
        getNotifyDev($hash,$args[0]);
      }
      else {
        error($hash,$name,"AlarmControl [$name]: Cannot set level: ".$args[0],2);
        return "Cannot set level to ".$args[0];
      }
    }

    # set/edit passwords
    elsif ($cmd =~ /^passwords?$/ ){
			return setPwd ($hash,$name,@args) if($hash->{helper}{PWD_NEEDED});
			error($hash,$name,"AlarmControl [$name]: SOMEONE UNWANTED TRIED TO SET NEW PASSWORDs!!! - ".$args[0],1);
      return "I didn't ask for a password, so go away!!!";
		}
	
	}
	
	else {
    return $usage;
  }

  return undef;
}


## get certain information
sub Get($@)
{
  my ($hash, $name, $cmd, @args) = @_;
  my $ret = undef;
  
  if ( $cmd eq "status") {
    return "Status: ".$hash->{STATE}.
					 "<br />Level: ".ReadingsVal($name, "level", "none").
					 "<br />Last Message: ".ReadingsVal($name, "message", "none")
					 ;
  }
  elsif ($cmd eq "version") {
    return $version;
  }
  else {
    $ret ="$name get with unknown argument $cmd, choose one of " . join(" ", sort keys %gets);
  }
 
  return $ret;
}


# NotifyFn: global and devices in sensors
sub Notify($$) {
  my ($hash,$dev) = @_;
  
  my $name = $hash->{NAME};
  my $devName = $dev->{NAME};
  my $events = deviceEvents($dev,1);
  
  return if( !$events );
  
  
  my $state = ReadingsVal($name,"state","inactive");
  my $level = ReadingsVal($name,"level",1);
  
  return undef if (IsDisabled($name));
  
  Log3 $name,5, "AlarmControl [$name]: Device: ".Dumper($dev)." - Events: ".Dumper($events);
  
  
  if( $dev->{NAME} eq "global" && (grep(m/^INITIALIZED$/, @{$events}) || grep(m/^REREADCFG$/, @{$events}))) {
    ## get the sensors for each level
		getSensors($hash,"AM_sensors");
		getSensors($hash,"AM_armStatesDeny");
		getSensors($hash,"AM_armStatesWarn");
		getSensors($hash,"AM_allowedUnarmEvents");
		getSensors($hash,"AM_notifyEvents");
		getSensors($hash,"AM_triggeredNotifyDevs");
		getArmDelay($hash);
		getAlarmStepAttrs($hash);
		## get the commands for each level and step
		foreach my $key (keys %armSteps) {
		  if (defined($armSteps{$key}{"cmdAttribute"})) {
		    getCommands($hash,$armSteps{$key}{"cmdAttribute"},AttrVal($name,$armSteps{$key}{"cmdAttribute"},"-"));
		  }
		}
		if (AttrVal($name,"AM_triggeredCountdownCmds","-") ne "-") {
		  getCommands($hash,"AM_triggeredCountdownCmds",AttrVal($name,"AM_triggeredCountdownCmds","-"),AttrVal($name,"AM_step6Delay",240));
		}
		if (AttrVal($name,"AM_disarmErrorCmds","-") ne "-") {
		  getCommands($hash,"AM_disarmErrorCmds",AttrVal($name,"AM_disarmErrorCmds","-"),"-");
		}
	}
	else {
    
    if ($dev->{NAME} ne "global" && $dev->{NAME} ne $name) {
      # only if AlarmControl device is in on state
      if ($state eq "on") {
        
        if (defined($hash->{helper}{sensors}{$level})) {
          my %sensors = %{$hash->{helper}{sensors}{$level}};
      
          my @sens = keys %sensors;
          
          Log3 $name,5, "AlarmControl [$name]: Notify Sensors: ".Dumper(%sensors)." - ".Dumper(@sens);
          
          if (defined($hash->{helper}{sensors}{$level}{$devName}{event}) && 
              grep(m/^$hash->{helper}{sensors}{$level}{$devName}{event}$/, @{$events}) &&
              inArray(\@sens,$devName)) {
                
            ## trigger device into ReadingsVal
            
            readingsSingleUpdate($hash,"triggerDevice",$devName,1);
            
            ## Alarm triggered
            setState($hash,$name,5,5);
            Log3 $name,4, "AlarmControl [$name]: Alarm triggered!!";
          } 
          elsif (!defined($hash->{helper}{sensors}{$level}{$devName}{event})) {
            delete($hash->{helper}{sensors}{$level}{$devName});
          }
        }
        
      }
      # unarm by event
      if ($state ne "off" && !IsDisabled($name)) {
        if (defined($hash->{helper}{allowedUnarmEvents}{$level})) {
          # get the allowed unarm sensors
          my %sensors = %{$hash->{helper}{allowedUnarmEvents}{$level}};
          
          my @sens = keys %sensors;
          
          Log3 $name,5, "AlarmControl [$name]: Notify Sensors: ".Dumper(%sensors)." - ".Dumper(@sens);
          
          if (defined($hash->{helper}{allowedUnarmEvents}{$level}{$devName}{event}) && 
              grep(m/^$hash->{helper}{allowedUnarmEvents}{$level}{$devName}{event}$/, @{$events}) &&
              inArray(\@sens,$devName)) {
                
            ## trigger device into ReadingsVal
            
            readingsSingleUpdate($hash,"unarmDevice",$devName,1);
            
            doUnarmByEvent($hash,$name,$hash->{helper}{allowedUnarmEvents}{$level}{$devName}{text},$devName);
            Log3 $name,4, "AlarmControl [$name]: Unarmed by device ".$devName;
          } 
          elsif (!defined($hash->{helper}{allowedUnarmEvents}{$level}{$devName}{event})) {
            delete($hash->{helper}{allowedUnarmEvents}{$level}{$devName});
          }
        }
        
        if (defined($hash->{helper}{notifyEvents}{$level})) {
          # get the notify sensors
          my %sensors = %{$hash->{helper}{notifyEvents}{$level}};
          
          my @sens = keys %sensors;
          
          Log3 $name,5, "AlarmControl [$name]: Notify Sensors: ".Dumper(%sensors)." - ".Dumper(@sens);
          
          if (defined($hash->{helper}{notifyEvents}{$level}{$devName}{event}) && 
              grep(m/^$hash->{helper}{notifyEvents}{$level}{$devName}{event}$/, @{$events}) &&
              inArray(\@sens,$devName)) {
                
            ## trigger device into ReadingsVal
            
            readingsSingleUpdate($hash,"notifyDevice",$devName,1);
            
            doNotifyEvent($hash,$name,$hash->{helper}{notifyEvents}{$level}{$devName}{text},$devName);
            Log3 $name,4, "AlarmControl [$name]: Got notify event from device ".$devName;
          } 
          elsif (!defined($hash->{helper}{notifyEvents}{$level}{$devName}{event})) {
            delete($hash->{helper}{notifyEvents}{$level}{$devName});
          }
        }
        
      }
      # gather events from devices while triggered
      if ($state eq "triggered" && !IsDisabled($name)) {
        
        if (defined($hash->{helper}{triggeredNotifyDevs}{$level})) {
          # get the notify sensors
          my %sensors = %{$hash->{helper}{triggeredNotifyDevs}{$level}};
          
          my @sens = keys %sensors;
          
          Log3 $name,5, "AlarmControl [$name]: Triggered Notify Sensors: ".Dumper(%sensors)." - ".Dumper(@sens);
          
          if (defined($hash->{helper}{triggeredNotifyDevs}{$level}{$devName}{event}) && 
              grep(m/^$hash->{helper}{triggeredNotifyDevs}{$level}{$devName}{event}$/, @{$events}) &&
              inArray(\@sens,$devName)) {
                
            my @ev = @{$events};
          
            ## trigger device into ReadingsVal        
            readingsSingleUpdate($hash,"triggeredNotifyDevice",$devName,1);
            
            gatherEvents($hash,$name,"triggeredNotifyDevs",$devName,@ev);
            
            Log3 $name,4, "AlarmControl [$name]: Got triggered notify event from device ".$devName.": ".$ev[0];
            
          }
          
        }
      }
    }
    # do something when certain countdown values are reached
    if ($dev->{NAME} eq $name) {
      if ($state eq "triggered") {
        doCountdownCmds($hash,$events);
        Log3 $name,5, "AlarmControl [$name]: Notify Countdown: ".Dumper($events);
      }
    }
  }
  
  Log3 $name,5, "AlarmControl [$name]: Alarm Event: ".Dumper($events);
  
  return undef;
}

# AttrFn
sub Attr(@) {
  my ($cmd,$name,$attrName,$attrVal) = @_;
  
  my $hash = $defs{$name};
  
  my $state = ReadingsVal($name,"state","off");
  
  return "AlarmControl [$name]: Attributes can only be set if not armed!" if ($state ne "off" && $state ne "inactive");
  
  # check for the right syntax  
  if ( $attrName =~ /^(AM_on(.*)?Cmds)|AM_(sensors|armStates(Deny|Warn))$/ ) {
    if ( $cmd eq "set" ) {
        if (($attrName =~ /^AM_(sensors|(allowedUnarm|notify)Events)$/ && $attrVal !~ /^((\d*:.+\|.+)(\n)?)*$/) || 
            ($attrName =~ /^AM_(on(.*)|triggered|arming)?(Countdown)?Cmds$/ && $attrVal !~ /^((\d*\:.+)(\n)?)*$/) ||
            ($attrName =~ /^AM_armStates(Deny|Warn)/ && $attrVal !~ /^((\d*:.+\|\{.*\}\|.+)(\n)?)*$/)) {
          
          return error($hash,$name,"Wrong format for attribute ".$attrName,1);

        }

    }
  }
  
    
  #get NotifyDev
	if ( $attrName =~ /^AM_(sensors|(allowedUnarm|notify)Events|armStates(Deny|Warn)|triggeredNotifyDevs)$/ ) {
	
		if ( $cmd eq "set" && $attrVal ne "0" && $init_done) {
			
			getSensors($hash,$attrName,$attrVal);
			
		}
	}

	
	if ( $attrName =~ /^AM_alarmStep.|(o(n|ff)(.*)|triggered|arming|disarmError)?(Countdown)?Cmds$/) {
    if ( $cmd eq "set" && $attrVal ne "0" && $init_done) {
      
      getCommands($hash,$attrName,$attrVal);
      
    }
	}
	
	if ( $attrName eq "AM_step6Delay") {
	  if ( $cmd eq "set" && $attrVal ne "0" && $init_done) {
      
     
      InternalTimer(gettimeofday()+0.3, "AlarmControl::getHighIntervalStep6", $hash, 0);
      
    }
	}
	
	if ( $attrName eq "AM_armDelay") {
	  if ( $cmd eq "set" && $attrVal ne "0" && $init_done) {
      
     
      InternalTimer(gettimeofday()+0.3, "AlarmControl::getArmDelay", $hash, 0);
      
    }
	}
	
	if ( $attrName eq "AM_armLevelCount") {
	  if ( $cmd eq "set" && $attrVal ne "0" && $init_done) {
	    InternalTimer(gettimeofday()+0.5, "AlarmControl::getAlarmStepAttrs", $hash, 0);
	  }
	}
	
	
	#if ($attr)
  
  return undef;
}

# get commands from attribute
sub getCommands($$;$$) {
  my ($hash,$attrName,$attrVal,$wait) = @_;
  
  my $name = $hash->{NAME};
  
  delete ($hash->{helper}{cmds}{$attrName});
  
  $attrVal = AttrVal($name,$attrName,"-") if (!defined($attrVal));
  
  if ($attrName eq "AM_triggeredCountdownCmds") {
    my @levels = split(/\n/,$attrVal);
    foreach my $level (@levels) {
    
      # time seconds from cmds
      my @lev = split(/:/,$level,2);
      
      $wait = $hash->{helper}{highIntervalStep6} if ($hash->{helper}{highIntervalStep6});
      $wait = AttrVal($name,"AM_step6Delay",240) if (!defined($wait));
      
      
      for(my $i=0;$i<=$wait;$i=$i+$lev[0]) {
      

        $hash->{helper}{cmds}{$attrName}{$i} = $lev[1]?$lev[1]:"-" if ($lev[1] && $i>0);
         
        
      }
    }
  }
  
  
  if ($attrVal ne "-") {
    # get number of levels
    my $countLevels = AttrVal($name,"AM_armLevelCount",3);
    for(my $i=0;$i<=$countLevels;$i++) {

      # make helpers for different alarm levels	
      my @levels = split(/\n/,$attrVal);
      foreach my $level (@levels) {
        
        # split level from cmds
        my @lev = split(/:/,$level,2) if ($attrName !~ /^AM_(off|triggered|disarmError)Cmds$/);
        
        if (!defined ($hash->{helper}{cmds}{$attrName}{$i})) {
        
          $hash->{helper}{cmds}{$attrName}{$lev[0]} = $lev[1]?$lev[1]:"-" if ($lev[0] && $lev[1] && $i eq $lev[0]);
          $hash->{helper}{cmds}{$attrName}{$i} = $level?$level:"-" if (!$lev[1]);
          
        }
        else {
          $hash->{helper}{cmds}{$attrName}{$lev[0]} .=";". $lev[1] if ($lev[0] && $lev[1] && $i eq $lev[0]);
          $hash->{helper}{cmds}{$attrName}{$i} .= ";".$level if (!$lev[1]);
        }
      }
    }
  }
  
  InternalTimer(gettimeofday()+0.3, "AlarmControl::getHighIntervalStep6", $hash, 0) if ($attrName ne "AM_triggeredCountdownCmds");
  
  return undef;
}

# get sensors or sensors with deny and warn states from attribute
sub getSensors($$;$) {
  my ($hash,$attrName,$attrVal) = @_;
  
  my $name = $hash->{NAME};
  
  $attrVal = AttrVal($hash->{NAME},$attrName,"-") if (!defined($attrVal));
  
  my $helperName = "AM_sensors";
  my @helperNames = split("_",$attrName);
  $helperName = $helperNames[1] if ($helperNames[1]);
  
  delete ($hash->{helper}{$helperName});
  delete ($hash->{helper}{notifyDev}{$helperName});
  
  my $highInterval = AttrVal($hash->{NAME},"AM_step6Delay",0);
  
  if ($attrVal ne "-") {
    # make helpers for different alarm levels			
  	my @levels = split(/\n/,$attrVal);
  	my @tempArr;
    foreach my $level (@levels) {
    
      # split level from sensors
      my @lev = split(/:/,$level,2);
      
      # split into 3 columns at | but only if | is not inside {} (|| as or)
      my @sens = split(/(?![^{]+\})(?![^(]+\))\|/,$lev[1]);
      
      my $tempVar = $lev[0]."_".$sens[0];
      
      if (!defined($hash->{helper}{notifyDev}{$helperName}{$lev[0]})) {
        $hash->{helper}{notifyDev}{$helperName}{$lev[0]} = $sens[0];
        
      } 
      else {
        if (!inArray(\@tempArr,$tempVar)) {
          $hash->{helper}{notifyDev}{$helperName}{$lev[0]} .= ",".$sens[0];      
        }
      }
      
      push @tempArr,$tempVar;
      
      # get all sensors for this line
      my @sensors = devspec2array($sens[0]);
      
      foreach my $sensor (@sensors) {

          $hash->{helper}{$helperName}{$lev[0]}{$sensor}{text} = $sens[2] if (defined($sens[2]));
          $hash->{helper}{$helperName}{$lev[0]}{$sensor}{event} = $sens[1];    
          $hash->{helper}{$helperName}{$lev[0]}{$sensor}{alarmInterval} = $sens[3] if (defined($sens[3]));      
         
      }
    }
    Log3 $name,5, "AlarmControl [$name]: TempArr ".Dumper(@tempArr);
  }
  InternalTimer(gettimeofday()+0.3, "AlarmControl::getHighIntervalStep6", $hash, 0);
  
  getNotifyDev($hash);
  
  return undef;
}

sub getArmDelay($) {
  my ($hash) = @_;
  
  my $name = $hash->{NAME};
  
  my $attrName = "AM_armDelay";
  
  delete($hash->{helper}{delay}{$attrName});
  
  # get number of levels
  my $countLevels = AttrVal($name,"AM_armLevelCount",3);
  for(my $i=1;$i<=$countLevels;$i++) {

    # make helpers for different alarm levels	
    my @levels = split(/\n/,AttrVal($name,$attrName,240));
    foreach my $level (@levels) {
      
      # split level from cmds
      my @lev = split(/:/,$level,2);

      
      $hash->{helper}{delay}{$attrName}{$lev[0]} = $lev[1]?$lev[1]:"-" if ($lev[0] && $lev[1] && $i eq $lev[0]);
      $hash->{helper}{delay}{$attrName}{$i} = $level?$level:"-" if (!$lev[1]);
        

    }
    
  }
  
  
  return undef;
}

sub getHighIntervalStep6($) {
  my ($hash) = @_;
  
  my $name = $hash->{NAME};
  
  my $highInterval  = AttrVal($name,"AM_step6Delay",240);
  
  # get levels
  my $levels = AttrVal($name,"AM_armLevelCount",3);
  
  for (my $i=1;$i <= $levels; $i++) {
    
    if (defined($hash->{helper}{sensors}{$i})) {
      # alls sensors for level $i
      my %sensors = %{$hash->{helper}{sensors}{$i}};
       
      # use keys (sensornames) as array
      my @sens = keys %sensors;
       
      foreach my $sensor (@sens) {
        
        if (defined($hash->{helper}{sensors}{$i}{$sensor}{alarmInterval})) {
          $highInterval = $hash->{helper}{sensors}{$i}{$sensor}{alarmInterval} if ($hash->{helper}{sensors}{$i}{$sensor}{alarmInterval} > $highInterval);
        }
          
      }
    }
  }
  
  $hash->{helper}{highIntervalStep6} = $highInterval;
  
  getCommands($hash,"AM_triggeredCountdownCmds");
  
  return undef;
  
}


# make NotifyDev
sub getNotifyDev($;$$) {
  my ($hash,$level,$step) = @_;
  
  my $name = $hash->{NAME};
  
  $step = 1 if (!defined($step));
  
 
  # we need the level to get the right devices (only events in this level will be processed)
  $level = ReadingsVal($name,"level",1) if (!defined($level));
  
  my $notifyDev = "global,".$name;
  
  if ($step < 5) {
  
    if (defined($hash->{helper}{notifyDev}{sensors}{$level})) {
    
      # all sensors for Alarm
      $notifyDev .= ",".$hash->{helper}{notifyDev}{sensors}{$level};
    
    }
    # add unarm devices, if available
    if (defined($hash->{helper}{notifyDev}{allowedUnarmEvents}{$level})) {
      
      # add unarm devices, we would need their events too (merge)
      $notifyDev .= ",".$hash->{helper}{notifyDev}{allowedUnarmEvents}{$level};
    }
    
     # add notify  devices, we would need their events too (merge)
    if (defined($hash->{helper}{notifyDev}{notifyEvents}{$level})) {
      
      # add unarm devices, we would need their events too (merge)
      $notifyDev .= ",".$hash->{helper}{notifyDev}{notifyEvents}{$level};
    }
  }
  else {
    ## get sensors that should trigger notify after triggering AM_sensors
    if (defined($hash->{helper}{notifyDev}{triggeredNotifyDevs}{$level})) {
    
      # all sensors for Alarm
      $notifyDev .= ",".$hash->{helper}{notifyDev}{triggeredNotifyDevs}{$level};
    
    }
  }
  
  # only the keys (device names)
  #@sens = keys %sensors;
  
  # build the NotifyDev on the fly
  $hash->{NOTIFYDEV} = $notifyDev;
  #notifyRegexpChanged($hash, $notifyDev);
  
  map {FW_directNotify("#FHEMWEB:$_", "location.reload()", "")} devspec2array("TYPE=FHEMWEB");
  
  Log3 $name,4, "AlarmControl [$name]: Changed NotifyDev to ".$notifyDev;
  
  return undef;
}

sub getAlarmStepAttrs($) {
  my ($hash) = @_;
  
  my $name = $hash->{NAME};
  
  my $count = AttrVal($name,"AM_armLevelCount",3);
  
  for(my $i=0;$i<=$count;$i++) {
     addToDevAttrList($name,"AM_levelDescr".$i.":textField-long");
  }
  return undef;
}

# activate instance
sub activate($$) {
  my ($hash, $name) = @_;
  
  readingsSingleUpdate($hash,"state","off",1) if (IsDisabled($name));
  CommandDeleteAttr( undef, $name . ' disable' ) if (AttrVal($name,"disable",1) == 1);
  
  Log3 $name, 3, "$name - Device activated";
  
  return undef;
}

# set new status for Device
sub setState($$$;$$) {
  my ($hash,$name,$state,$arg) = @_;
  
  $arg = 0 if (!defined($arg));
  
  my $armSteps = \%armSteps;
  
  my $function_name = $armSteps->{$state}{"sub"}."Fn";
  
  delete($hash->{helper}{break});

  CallFn($name, $function_name, $hash,$name,$arg);
  
  return undef;
}

# off function
sub doOff($$$;$$) {
  my ($hash,$name,$arg,$internal,$noCommand) = @_;
  
  my $check = defined($internal) && $internal eq "83903423hjhjkhbg324giujhkdsf87u90�32njidvf93jhjiou"?1:0;
  
  Log3 $name,4, "AlarmControl [$name]: check for internal: ".$check;
  
  RemoveInternalTimer($hash);
  
  if (checkPwd($hash,$arg) || $check) {
    
    $hash->{helper}{doOff} = 1;
    
    Log3 $name,4, "AlarmControl [$name]: password correct or internal off: set disarmed - checkValue: ".$check;
    
    $hash->{helper}{commandText} = AttrVal($name,"AM_offMsg","-");
    
    # add notify text to off text for further commands
    if (defined($hash->{helper}{notifyText})) {
      my %sensors = %{$hash->{helper}{notifyText}};
      # only the keys (device names)
      my @sens = keys %sensors;
      foreach my $sensor (@sens) {
        $hash->{helper}{commandText}.=". ".$hash->{helper}{notifyText}{$sensor};
      }
    }
    
    # update with text
    doUpdate($hash,0,$armSteps{-1}{state},-1,AttrVal($name,"AM_offMsg","none")) if (!$noCommand);
    # update without text
    doUpdate($hash,0,$armSteps{-1}{state},-1,"noUserCommand") if ($noCommand);
    
    $hash->{NOTIFYDEV}="global,".$name;
  
    InternalTimer(gettimeofday()+1.5, "AlarmControl::resetCounter", $hash, 0);
    InternalTimer(gettimeofday()+1.3, "AlarmControl::deleteHelpers", $hash, 0);

    error($hash,$name,"none",4);
  
  }
  else {
    my $error="Wrong passcode: ".$arg;
    error($hash,$name,$error,1);
    
    # cache for false password
    $hash->{helper}{wrongPwd} = $arg;
    
    doPasswordError($hash,$name);
	}
  
  return undef;
}

# on function
sub doOn($;$$$) {
  my ($hash,$name,$arg,$step) = @_;
  
  RemoveInternalTimer($hash);
  
  $name = $hash->{NAME} if (!defined($name));
  $arg  = ReadingsVal($name,"level",1) if (!defined($arg));
  $step = ReadingsVal($name,"step",2)+1 if (!defined($step));
  
  my $state = ReadingsVal($name,"state","off");
  
  doUpdate($hash,$arg,$armSteps{$step}{state},$step,AttrVal($name,"AM_onMsg","none")) if ($state ne "off");
  
  $step = ReadingsVal($name,"step",2)+1;
  
  # arming if state is off
  if ($state eq "off") {
    ## deny arming for certain device states
    my $warnDeny = checkWarnDeny($hash,$arg);
    
    Log3 $name,4, "AlarmControl [$name]: check warn and deny status with level $arg!";
  
    if ($warnDeny) {
      ## arm as usual
      doArm($hash,$name,$arg);
    }
    else {
      # don't arm / set off (reset)
      Log3 $name,3, "AlarmControl [$name]: Armimg denied!";
      CallFn($name, "offFn", $hash,$name,-1,"83903423hjhjkhbg324giujhkdsf87u90�32njidvf93jhjiou",1);
    }
  }
  else {
    if ($step <= 4) {
      my $nStep = $step;
      my $wait = AttrVal($name,"AM_step".$nStep."Delay",6);
      my $nHash;
      $nHash->{hash}  = $hash;
      $nHash->{"wait"}= $wait;
      $nHash->{"countdownStep"}=$step;
      $nHash->{"functionDo"}= "AlarmControl::doOn";
      doCountdown($nHash);
    }
  }
  
  resetCounter($hash);
  
  return undef;
}

# arm function
sub doArm($$$) {
  my ($hash,$name,$arg) = @_;
  
  RemoveInternalTimer($hash);
  
  my $wait = AttrVal($name,"AM_armDelay",240);
  
  $wait = $hash->{helper}{delay}{"AM_armDelay"}{$arg} if (defined($hash->{helper}{delay}{"AM_armDelay"}{$arg}));
  
  $wait = 1 if ($wait eq "-");
  
  $hash->{helper}{number} = transSecToMin($wait,"tts");
    
  Log3 $name,4, "AlarmControl [$name]: Armimg allowed!";

  doUpdate($hash,$arg,$armSteps{1}{state},1);
  
  Log3 $name,3, "AlarmControl [$name]: Device was armed!";

  getNotifyDev ($hash,$arg);
  
  my $nHash;
  $nHash->{hash}  = $hash;
  $nHash->{"countdownStep"}=1;
  $nHash->{"wait"}= $wait;
  $nHash->{"functionDo"}= "AlarmControl::doOn";
  
  doCountdown($nHash);

    
  return undef;
}

# alarm function
sub doAlarm($;$$) {
  my ($hash,$name,$step) = @_;
  
  $name = $hash->{NAME} if (!defined($name));
  if (!defined($step)) {
    $step = ReadingsVal($name,"step",5)+1; 
  }

  RemoveInternalTimer($hash);
  
  for(my $i=$step-1;$i>=0;$i--) {
    $hash->{helper}{break}{$i} = "break";
  }
  
  my $level = ReadingsVal($name,"level",1);
  
  $hash->{helper}{commandText} = $hash->{helper}{sensors}{$level}{ReadingsVal($name,"triggerDevice","-")}{text};
 
  
  if ($step>=6) {
    Log3 $name,3, "AlarmControl [$name]: ALARM!";
  }
  
  doUpdate($hash,$level,$armSteps{$step}{state},
            $step,
            $hash->{helper}{sensors}{$level}{ReadingsVal($name,"triggerDevice","-")}{text});
            
  my $plusStep = $step+1;
              
  my $wait = AttrVal($name,"AM_step".$plusStep."Delay",30);
  
  if ($step==5 && defined($hash->{helper}{sensors}{$level}{ReadingsVal($name,"triggerDevice","-")}{alarmInterval})) {
    $wait = $hash->{helper}{sensors}{$level}{ReadingsVal($name,"triggerDevice","-")}{alarmInterval};
  }
  
  if ($plusStep>=7) {
    resetCounter($hash);
  }
  
  if ($step >= 5) {
    getNotifyDev($hash,$level,$step);
  }
  
  if ($plusStep>$armSteps{-1}{"count"}) {
    resetCounter($hash);
    return undef;
  }
  
  
  my $nHash;
  $nHash->{hash}  = $hash;
  $nHash->{"wait"}= $wait;
  $nHash->{"countdownStep"}=$step;
  $nHash->{"functionDo"}= "AlarmControl::doAlarm";
  
  doCountdown($nHash);
  
  return undef;
}

# if you want to have a tts countdown.
sub doCountdownCmds($$) {
  my ($hash,$events) = @_;
  my $name = $hash->{NAME};
  
  # $events to array
  my @events = @{$events};
  foreach my $event (@events) {
    # split time from command
    my @ev = split(/\: /,$event,2);
    
    if (defined($ev[0]) && $ev[0] eq "countdown") {
     # if we have a command
      if (defined($hash->{helper}{cmds}{"AM_triggeredCountdownCmds"}{$ev[1]})) {
        # save the number for tts, IM and so on
        $hash->{helper}{number} = transSecToMin($ev[1],"tts");
        # excecute command(s)
        doUserCommands($hash,$hash->{helper}{cmds}{"AM_triggeredCountdownCmds"}{$ev[1]});
      }  
    }
  }
  
  return undef;
}

# any countdouwn
sub doCountdown($) {
  my ($nHash) = @_;
  
  my $hash = $nHash->{hash};
  my $name = $hash->{NAME};
  
  if ($hash->{helper}{break}{$nHash->{"countdownStep"}} && $hash->{helper}{break}{$nHash->{"countdownStep"}} eq "break") {
    delete($hash->{helper}{break});
    #resetCounter($hash);
    return undef;
  }
  
  # countdown is 0 do it
  if ($nHash->{"wait"}==-1) {
    $nHash->{"wait"}="0";
    InternalTimer(gettimeofday()+0.1, $nHash->{"functionDo"}, $hash, 0) if (!defined($hash->{helper}{doOff}));
    return undef;
  }
  
  my $step = $nHash->{"countdownStep"};
  
  my $makeEvent = 1;
  $makeEvent = 0 if (AttrVal($name,"AM_step".$step."DelaySilent",0) == 1);
    
  readingsBeginUpdate($hash);
    
    readingsBulkUpdate($hash,"countdown",$nHash->{"wait"});
		readingsBulkUpdate($hash,"countdownH",transSecToMin($nHash->{"wait"},"countdown"));
    readingsBulkUpdate($hash,"countdownTTS",transSecToMin($nHash->{"wait"},"tts"));
  
  readingsEndUpdate($hash, $makeEvent);
  
  my $state = ReadingsVal($name,"state","off");

  if ($nHash->{"wait"}!=1) {
    $nHash->{"wait"}--;
  }
  else {
    $nHash->{"wait"}=-1;
  }  
  
  InternalTimer(gettimeofday()+1, "AlarmControl::doCountdown", $nHash, 0) if ($nHash->{"wait"}!=-2 && $state !~ /^off$/); 
   
  return undef;
}

#update main readings
sub doUpdate($$$$;$) {
  my ($hash,$level,$state,$step,$message) = @_;
  my $name = $hash->{NAME}; 
  
  
  my $triggerDevice = ReadingsVal($name,"triggerDevice","-");
  
  
  if (defined($message) && $triggerDevice ne "-") {
    $message = getMessageDeviceNames($hash,$triggerDevice,$message);
  }
  
  my $oldLevel = ReadingsVal($name,"level",$level);
  
  readingsBeginUpdate($hash);
		
		readingsBulkUpdate($hash,"level",$level);
    readingsBulkUpdate($hash,"state",$state) if (defined($state));
    readingsBulkUpdate($hash,"step",$step);
    readingsBulkUpdate($hash,"message",$message) if (defined($message) && $message ne "noUserCommand");
  
  readingsEndUpdate($hash, 1);
  
  Log3 $name, 4, "AlarmControl [$name]: set state for $name to $state" if (defined($state));
  
  # if off, then preserve old Level for command selection
  $level = $oldLevel if ($level == 0);
  
  # do userCommands
  
 
  if (defined($level) && defined($step) && defined($hash->{helper}{cmds}{$armSteps{$step}{"cmdAttribute"}}{$level})) {
    Log3 $name, 5, "AlarmControl [$name]: $level,$step,".$hash->{helper}{cmds}{$armSteps{$step}{"cmdAttribute"}}{$level};
    my $commands = $hash->{helper}{cmds}{$armSteps{$step}{"cmdAttribute"}}{$level};
    
    doUserCommands($hash,$commands) if ($commands && (!defined($message) || (defined($message) && $message ne "noUserCommand")));
  }
  
  return undef;
}

# sub for usercommands (Analyse Command chain)
sub doUserCommands($$) {
  my ($hash,$commands) = @_;
  my $name = $hash->{NAME}; 
  
  # Trigger Notify Devices
  my $TND = "";
  
  if (defined($hash->{helper}{triggeredNotifyDevs}{events})) {
    my %sensors = %{$hash->{helper}{triggeredNotifyDevs}{events}};
    my @sens = keys %sensors;
    
    $TND = join("|", @sens);
  }
  
  # we process certain special variables in the commands
  my %specials = (
                  "%NAME"         => $name,
                  "%TEXT"         => $hash->{helper}{commandText}?$hash->{helper}{commandText}:"",
                  "%NUMBER"       => $hash->{helper}{number}?$hash->{helper}{number}:"",
                  "%SENSOR"       => ReadingsVal($name,"triggerDevice","-"),
                  "%ALIAS"        => AttrVal(ReadingsVal($name,"triggerDevice","-"),"alias",ReadingsVal($name,"triggerDevice","-")),
                  "%DESCR"        => AttrVal($name,"AM_levelDescr".ReadingsVal($name,"level",0),""),
                  "%PWD"          => $hash->{helper}{wrongPwd}?$hash->{helper}{wrongPwd}:"",
                  "%TND"          => $TND,
  );
  
  my $final_cmd = EvalSpecials($commands, %specials);
  
  my $errors = AnalyzeCommandChain(undef, $final_cmd);
  
  Log3 $name, 4, "AlarmControl [$name]: Executed commands $commands";
  Log3 $name, 2, "AlarmControl [$name]: Got error by excecuting $commands: ".$errors if ($errors);
  
  $hash->{helper}{commandText} = "" if (defined($hash->{helper}{commandText}));
  
  $hash->{helper}{wrongPwd} = "" if (defined($hash->{helper}{wrongPwd}));
  
  return undef;
}

# sub for unarming by event
sub doUnarmByEvent($$$$) {
  my ($hash,$name,$message,$devName) = @_;
  
  if (defined($message) && $devName ne "-") {
    $message = getMessageDeviceNames($hash,$devName,$message);
  }
  
  ## message
  readingsSingleUpdate($hash,"message",$message,1);
  ## unarm 
  CallFn($name, "offFn", $hash,$name,-1,"83903423hjhjkhbg324giujhkdsf87u90�32njidvf93jhjiou");
  
  return undef;
}

sub doNotifyEvent($$$$) {
  my ($hash,$name,$message,$devName) = @_;
  
  if (defined($message) && $devName ne "-") {
    
  
    my $countEvents = ReadingsVal($name,"countEvents_".$devName,0)+1;
  
    readingsSingleUpdate($hash,"countEvents_".$devName,$countEvents,1);
    
    $message = getMessageDeviceNames($hash,$devName,$message);
    
    $hash->{helper}{notifyText}{$devName} = $message;
  }
 
  
  return undef;
}

# error if unarm tried with wrog password
sub doPasswordError($$) {
  my ($hash,$name) = @_;
  
  # do commands for unarm Error
  my $commands = AttrVal($name,"AM_disarmErrorCmds","-");
  doUserCommands($hash,$commands) if ($commands ne "-");
  
  return undef;
}



sub gatherEvents($$$$@) {
  my ($hash,$name,$attr,$devName,@ev) = @_;
  
  if (@ev) {
    
    foreach my $event (@ev) {
      $hash->{helper}{$attr}{events}{$devName} = $event;
      
    }
  }
  
  
  return undef; 
}

# warn or deny if certain devices have certain states
sub checkWarnDeny($$) {
  my ($hash,$level) = @_;
  my $name = $hash->{NAME};
  
  my %sensors;
  my %specials;
  my @sens;
  my $sensor;
  my $commands;
  my $cond;
  my $final_cond;
  my $message;
  
  $level = ReadingsVal($name,"level",1) if (!defined($level));
  
  Log3 $name,4, "AlarmControl [$name]: checking warn and deny status with level $level!";
  
  # for denying
  if (defined($hash->{helper}{armStatesDeny}{$level})) {
    %sensors = %{$hash->{helper}{armStatesDeny}{$level}};
    @sens = keys %sensors;
    
    Log3 $name,5, "AlarmControl [$name]: Deny sensors in level $level: ".Dumper(@sens);
    
    # loop over all sensors
    foreach $sensor (@sens) {
   
      # eval Specials
      %specials = (
        "%SENSOR" => $sensor,
      );
      $cond = $hash->{helper}{armStatesDeny}{$level}{$sensor}{event};
      
      Log3 $name,4, "AlarmControl [$name]: Deny sensor in level $level: ".$cond;

      $final_cond = EvalSpecials($cond, %specials);
      
      $message = $hash->{helper}{armStatesDeny}{$level}{$sensor}{text} if (defined($hash->{helper}{armStatesDeny}{$level}{$sensor}{text}));
      
      if (defined($message) && $sensor ne "-") {
        $message = getMessageDeviceNames($hash,$sensor,$message);
      }
      
      # if user condition is true
      if (AnalyzePerlCommand (undef, $final_cond)) {
        # update reading with given user text
        readingsSingleUpdate($hash,"message",$message,1);
        
        $hash->{helper}{commandText} = AttrVal($name,"AM_denyTextPrefix","Achtung")." ".$message;
        
        # get user commands for this case
        $commands = AttrVal($name,"AM_armStatesDenyCmds","-");
        
        # do user commands
        doUserCommands($hash,$commands) if ($commands ne "-");
        
        # return false, if condition matches
        return 0;
      }    
         
    }
  }
    
  # for warning
  if (defined($hash->{helper}{armStatesWarn}{$level})) {
    %sensors = %{$hash->{helper}{armStatesWarn}{$level}};
    @sens = keys %sensors;
    
    my $do=0;
    
    Log3 $name,5, "AlarmControl [$name]: Warn sensors in level $level: ".Dumper(@sens);
    
    # loop over all sensors
    foreach $sensor (@sens) {
      # eval Specials
      %specials = (
        "%SENSOR" => $sensor,
      );
      $cond = $hash->{helper}{armStatesWarn}{$level}{$sensor}{event};

      Log3 $name,4, "AlarmControl [$name]: Warn sensor in level $level: ".$cond;

      $final_cond = EvalSpecials($cond, %specials);
      
      Log3 $name,4, "AlarmControl [$name]: Warn sensor in level $level (eval): ".$final_cond;
      
      # if user condition is true
      if (AnalyzePerlCommand (undef, $final_cond)) {
        # update reading with given user text
        readingsSingleUpdate($hash,"message",$hash->{helper}{armStatesWarn}{$level}{$sensor}{text},1);
        
        if (!defined($hash->{helper}{commandText})) {
          $hash->{helper}{commandText} = AttrVal($name,"AM_warnTextPrefix","Achtung")." ".$hash->{helper}{armStatesWarn}{$level}{$sensor}{text};
        }
        else {
          if ($hash->{helper}{commandText} !~ /$hash->{helper}{armStatesWarn}{$level}{$sensor}{text}/) {
            $hash->{helper}{commandText} .= ". ".$hash->{helper}{armStatesWarn}{$level}{$sensor}{text};
          }
        }
       
        
        $do=1;
      }    
       
    }
    if ($do==1) {
      # get user commands for this case
      $commands = AttrVal($name,"AM_armStatesWarnCmds","-");
            
      # do user commands
      doUserCommands($hash,$commands) if ($commands ne "-");
    }
  }
  
  return 1;
  
}

sub resetCounter($) {
  my ($hash) = @_;
  
  readingsBeginUpdate($hash);
  
    readingsBulkUpdate($hash,"countdown",0);
		readingsBulkUpdate($hash,"countdownH","00:00");
    readingsBulkUpdate($hash,"countdownTTS",0);
  
  readingsEndUpdate($hash, 1);
  
  return undef;
}

sub deleteHelpers($) {
  my ($hash) = @_;
  
  # reset some texts 
  delete($hash->{helper}{commandText}) if (defined($hash->{helper}{commandText}));
  delete($hash->{helper}{notifyText}) if (defined($hash->{helper}{notifyText}));
  delete($hash->{helper}{alarmText}) if (defined($hash->{helper}{alarmText}));
  delete($hash->{helper}{doOff});
  delete ($hash->{helper}{triggeredNotifyDevs}{events});
  CommandDeleteReading(undef,$hash->{NAME}." countEvents_.*");
    
  return undef;
}

# write password to file
sub setPwd($$@) {
	my ($hash, $name, @pwds) = @_;
	 
	return "Passwords can't be empty" if (!@pwds);
	
	if ($pwds[0] eq "newPasswords") {
		shift(@pwds);
		if (AlarmKrimi_checkPwd ($hash,$pwds[0])) {
			shift(@pwds);
		}
		else {
			return "Old Password is wrong";
		}
	}
	
	return "Passwords can't be empty" if (!@pwds || !$pwds[0] || $pwds[0] eq "");
	
	my $index = $hash->{TYPE}."_".$hash->{NAME}."_passwd";
  my $key = getUniqueId().$index;
	
	#push (@pwds,$salt);
	
	my $pwdString=join(':', @pwds);
	
	$pwdString=encode_base64($pwdString);
	$pwdString =~ s/^\s+|\s+$//g;
		 
	my $err = setKeyValue($index, $pwdString);
  
  if(defined($err)) {
  	return "error while saving the password - $err";
  	error($hash,$name,"error while saving the password - $err",1);
  }
  
	delete($hash->{helper}{PWD_NEEDED}) if(exists($hash->{helper}{PWD_NEEDED}));
	
	error($hash,$name,"none",4);
	
	return "password successfully saved";
	 
}

# check given password against the one we saved
sub checkPwd ($$) {
	my ($hash, $pwd) = @_;
	my $name = $hash->{NAME};
    
  my $index = $hash->{TYPE}."_".$hash->{NAME}."_passwd";
  my $key = getUniqueId().$index;
	
	my ($err, $password) = getKeyValue($index);
        
  if ($err) {
		$hash->{helper}{PWD_NEEDED} = 1;
    Log3 $name, 4, "[$name] - unable to read password from file: $err";
    return undef;
  }  
	
	if ($password && $pwd) {
		my @pwds=split(":",decode_base64($password));
				
		return "no password saved" if (!@pwds);
		
		foreach my $pw (@pwds) {
			return 1 if ($pw eq $pwd);
		}
	}
	
	return 0;
}

# get the password
sub getPwd ($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
    
  my $index = $hash->{TYPE}."_".$hash->{NAME}."_passwd";
  my $key = getUniqueId().$index;
	
	my ($err, $password) = getKeyValue($index);
        
  if ($err) {
		$hash->{helper}{PWD_NEEDED} = 1;
    Log3 $name, 4, "[$name] - unable to read password from file: $err";
    return undef;
  }  
	
	if ($password) {
		my @pwds=split(":",decode_base64($password));
				
		return "no password saved" if (!@pwds);
		
		my $i=0;
		foreach my $pw (@pwds) {
			return $pw if ($i==0);
			$i++;
		}
	}
	
	return 0;
}

# error messages
sub error($$$;$) {
  my ($hash, $name, $error, $level) = @_;
  
  $level = 1 if (!defined($level));
  
  readingsBeginUpdate($hash);
  		
		readingsBulkUpdate($hash,"error",$error);
    readingsBulkUpdate($hash,"lastError",$error) if ($error ne "none");
    
  
  readingsEndUpdate($hash, 1);

	Log3 $name, $level , $error;
	
	return $error;
  
}

# some time converters for human readable and tts texts
sub transSecToMin($$) {
	my ($sec,$type)=@_;
	my $ret="";
	my @t = localtime( $sec );
	if ($type eq "tts") {
		$ret.=$t[1]." Minuten " if ($t[1]>0 && $t[1]!=1 && $t[0]==0);
		$ret.="einer Minute " if ($t[1]>0 && $t[1]==1 && $t[0]==0);
		$ret.=$t[1]." Minuten und " if ($t[1]>0 && $t[1]!=1 && $t[0]!=0);
		$ret.="einer Minute und " if ($t[1]>0 && $t[1]==1 && $t[0]!=0);
		$ret.=$t[0]." Sekunden" if ($t[0]>0 && $t[0]!=1);
		$ret.=$t[0]." Sekunde" if ($t[0]>0 && $t[0]==1);
	}
	elsif ($type eq "countdown") {
		$t[2]--;
		$ret = sprintf( "%02d:%02d:%02d",$t[2],$t[1], $t[0] ) if ($t[2]>0);
		$ret = sprintf( "%02d:%02d",$t[1], $t[0] ) if ($t[2]==0);
	}
	return $ret;
}

# check if string is part of array
sub inArray {
  my ($arr,$search_for) = @_;
  foreach (@$arr) {
  	return 1 if ($_ eq $search_for);
  }
  return 0;
}

# return message with device names
sub getMessageDeviceNames($$$) {
  my ($hash,$devName,$message) = @_;
 
  my $alias = AttrVal($devName,"alias",$devName);
  my $sensoralias = AttrVal($devName,"alias",$devName).($alias eq $devName?"":" (".$devName.")");
  my $count = ReadingsVal($hash->{NAME},"countEvents_".$devName,0);
  my $descr = AttrVal($hash->{NAME},"AM_levelDescr".ReadingsVal($hash->{NAME},"level",0),"");
  
  my $pluralE = $count>1?"e":"";
  my $pluralS = $count>1?"s":""; 
  
  $message =~ s/\$DESCR/$descr/;
  $message =~ s/\$SENSOR/$devName/;
  $message =~ s/\$ALIAS/$alias/;
  $message =~ s/\$SENSORALIAS/$sensoralias/;
  $message =~ s/\$COUNT/$count/;
  $message =~ s/\$PLURALE/$pluralE/;
  $message =~ s/\$PLURALS/$pluralS/;
  
  return $message;
}
    
    
# show widget in detail view of AM device
sub detailFn(){
  my ($FW_wname, $devname, $room, $pageHash) = @_; # pageHash is set for summaryFn.

  my $hash = $defs{$devname};
  my $name=$hash->{NAME};
  
  Log3 $name, 4, "[$name] - summaryFn called - FW_wname: $FW_wname, device: $devname, room: $room";
  
  $hash->{mayBeVisible} = 1;
 
  
  return undef; # if (IsDisabled($name) || AttrVal($name,"AM_showDetailWidget",1)!=1);
 
  
  return detailHtml($hash,$name,1);
}

sub summaryFn ($$$$) {
  my ($FW_wname, $devname, $room, $pageHash) = @_;   # pageHash is set for summaryFn in FHEMWEB
  
  my $hash   = $defs{$devname};
  my $name=$hash->{NAME};
  
  Log3 $name, 4, "[$name] - summaryFn called - FW_wname: $FW_wname, device: $devname, room: $room";
  
  return detailHtml($hash,$name,1);
}

sub detailHtml($$;$) {
  my ($hash,$name,$detail) = @_;
  

  
  my $ret = "";
  my $rot = "";
  
  $rot .= "<script type=\"text/javascript\" src=\"$FW_ME/www/pgm2/AlarmControl.js?version=".$version."\"></script>";
  
  
  
  #$ret .= FW_makeImage(FW_dev2image($name),"Test");
  
  #$ret .= 'Test';
  
  return $rot.$ret;
  
}
    
1;

=pod
=begin html

<a name="AlarmKrimi"></a>
<h3>AlarmKrimi</h3>
<ul>
  

</ul>

=end html
=cut