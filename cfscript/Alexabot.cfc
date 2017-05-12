/*

Sample invocation of the CF-Alexa Framework

*/

component output="false" displayname="AlexaBot" extends="Alexa" hint="I am an example app using the CF-Alexa framework" {

	/* 
	Define your intents here 
	
	The framework will automatically call the associated function
	and pass slot values as arguments.
	
	*/

	this.intents = {
		"MemberSearch" = "getMemberInfo",
		"eventCalendarSearchIntent" = "onGetCalendarEvents",
		"AMAZON.HelpIntent" = "onHelp",
		"AMAZON.CancelIntent" = "onStop",
		"AMAZON.StopIntent" = "onStop",
		"AMAZON.NoIntent" = "onStop",
		"AMAZON.YesIntent" = "onContinue"
	}

	/*
	
	INTENT Handlers
	
	*/

	public void function onContinue() {

		local.lastIntent = getLastIntent();

		if( structkeyexists( local.lastintent, "intent" ) ) {
			switch( local.lastintent.intent ) {
				case 'eventCalendarSearchIntent':
					say( "Ok. I'm Listening..." );
				break;
			
				default:
					onHelp();
				break;
			}
		} else {
			onHelp();
		}

	}

	public void function onGetCalendarEvents( required string date ) {

		stDates = parseDates( arguments.date );
		
		local.startdate = parsedatetime( stdates.startdate );
		local.startdate = 
		dateformat( local.startdate, "yyyy-mm-dd" ) & " " & timeformat( local.startdate, "HH:mm" );

		local.enddate = parsedatetime( stdates.enddate );
		local.enddate = dateformat( local.enddate, "yyyy-mm-dd" ) & " " & timeformat( local.enddate, "HH:mm" );

		/* get events */
		local.cfcCS = createObject("component","CommonSpot");
		local.events = local.cfcCS.getEvents();
		
		local.params = { startDate = local.startDate, endDate = local.endDate };
		local.options = { dbtype = 'query' };

		local.events = queryExecute( 'SELECT * FROM events WHERE eventdate >= :startdate AND eventdate <= :endDate', local.params, local.options );
		
		say( "I found #local.events.recordcount# events" );

		for( local.event in local.events ) {
			
			local.eventdate = listToArray( left( local.event.eventdate, 10 ), "-" );
			local.eventDate = createDate( local.eventdate[ 1 ], local.eventdate[ 2 ], local.eventdate[ 3 ] );
			local.eventDate = dateformat( local.eventdate, "dddd, mmmm d" );

			say( "On #local.eventdate#, #local.events.title#" );

		}

	}

	public void function onStop() {

		say("Goodbye.");
		endSession();

	}

	public void function onHelp() {

		say( "To get information about a member, say how about member firstname lastname" );
		
		say( "To hear about scheduled events, say what's going on today? what's going on tomorrow?, what's going on this week?, or what's going on on a specific date" );


	}

	public void function getMemberInfo( required string memberFirstName, required string memberLastName, string city = '' ) {
	
		local.sql = 'SELECT * FROM MemberSearch m WHERE m.PUBLISH <> 1 AND m.FIRST_NAME LIKE :firstName AND m.LAST_NAME LIKE :lastName';
		local.params = { firstName = arguments.memberFirstName, lastName = arguments.memberLastName };
		local.options = { datasource = 'somedsn' };

		if( len( arguments.city ) ) {

			local.sql &= ' AND m.CITY LIKE :city';
			local.params[ 'city' ] = arguments.city;
			
		}

		local.sql &= 'ORDER BY m.LAST_NAME, m.FIRST_NAME';

		local.qGetMembers = queryExecute( local.sql, local.params, local.options );

        /* try with soundex if it's a fail */
        if( !local.qGetMembers.recordCount ) {

			local.sql = 'SELECT * FROM MemberSearch m WHERE m.PUBLISH <> 1 AND m.FIRST_NAME LIKE :firstName AND LEFT( m.LAST_NAME, 3 ) LIKE :shortLastName AND soundEx( m.LAST_NAME ) = :lastName';
			local.params = { firstName = arguments.memberFirstName, lastName = arguments.memberLastName, shortLastName = left( arguments.memberLastName, 3 ) };
			local.options = { datasource = 'somedsn' };

			if( len( arguments.city ) ) {

				local.sql &= ' AND m.CITY LIKE :city';
				local.params[ 'city' ] = arguments.city;
				
			}

			local.sql &= 'ORDER BY m.LAST_NAME, m.FIRST_NAME';

			local.qGetMembers = queryExecute( local.sql, local.params, local.options );

        }

        if( !local.qGetMembers.recordcount ) {
			say( "I'm sorry, but I didn't find anyone named #arguments.memberFirstName# #arguments.memberLastName#" );
			setTitle( "#arguments.memberFirstName# #arguments.memberLastName#" );
			setText( "Member not found" );
		} else {
			if( local.qGetMembers.recordcount is 1 ) {

				local.response = "#local.qGetMembers.first_name# #local.qGetMembers.last_name# of #local.qGetMembers.city#, #local.qGetMembers.state# was graduated from the #local.qGetMembers.law_school# law school.";

				if( len( local.qGetMembers.company ) ) {
					local.response &= "#local.qGetMembers.prefix# #local.qGetMembers.last_name# is currently employed by #local.qGetMembers.company#.";
				}

				local.response = replace( local.response, "&", " and ", "ALL" );

				say( trim( local.response ) );
				setTitle( "#local.qGetMembers.first_name# #local.qGetMembers.last_name#" );
				setText( local.response );
			} else {
				say( "I found #local.qGetMembers.recordcount# matches." );
			}
			
       	}
    

	}
	
	public void function onLaunch( required struct sessionInfo ) {

		super.onLaunch(arguments.sessionInfo);

		say( "Welcome to the State Bar" );
		say( "You can ask for information about any member or ask about events." );

	}

}