	/*
	
	Easily handle speech and card responses and route intent, launch, and sessionend requests.
	Also keeps track of user's session history in order to facilitate the construction of "conversations"

	By: Steve Drucker 
	Blog: https://druckit.wordpress.com
	sdrucker@figleaf.com
	www.figleaf.com
	training.figleaf.com
	@sdruckerfig

	Contact us for ColdFusion hosting, training, consulting, and other professional services.

	License: MIT
	Copyright 2017. Fig Leaf Software. All rights reserved.

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
	

	TODO:
	 

	*/

component output="false" displayname="Alexa" hint="Extend this CFC to create your own Alexa responder" {

	this.isTesting = true;

	savecontent variable="this.responseTemplate" {
		writeOutput( '{
			"version": "1.0",
			"sessionAttributes": {},
			"response": {
				"outputSpeech": {
					"type": "SSML",
					"ssml": ""
				},
				"card": {
					"type": "Simple",
					"title": "",
					"content": ""
				},
				"reprompt": {
					"outputSpeech": {
						 "type": "PlainText",
						 "text": "Can I help you with anything else?"
					}
				},
				"shouldEndSession": false
			}
		}');
	}
	
	this.AlexaResponse = deserializeJson( this.responseTemplate );

	/**
	* @displayname	say
	* @description	I return the ssml of any text you want Alexa to speak
	* @param		text {String} required - I am the text Alexa should speak
	* @return		void
	*/
	public void function say( required string text ) {

		this.AlexaResponse.response.outputSpeech.ssml = this.AlexaResponse.response.outputSpeech.ssml & "<p;" & arguments.text & "</p;";

	}

	/**
	* @displayname	endSession
	* @description	I tell Alexa that we're ending our session
	* @return		void
	*/
	public void function endSession() {

		this.AlexaResponse.response.shouldEndSession = true;

	}

	/* 

	CARD HANDLING

	*/

	/**
	* @displayname	setTitle
	* @description	I insert the title into the card returned to the Alexa app
	* @param		title {String} required - I am the title to set into the card
	* @return		void
	*/
	public void function setTitle( required string title ) {

		this.AlexaResponse.response.card.title = arguments.title;

	}
	
	/**
	* @displayname	setText
	* @description	I insert text into the card returned to the Alexa app
	* @param		content {String} required - I am the text to set into the card
	* @return		void
	*/
	public void function setText( required string content ) {

		if( structKeyExists( this.AlexaResponse.response.card, "image" ) {
			this.AlexaResponse.response.card.text = arguments.content;
		} else {
			this.AlexaResponse.response.card.content = arguments.content;
		}

	}

	/**
	* @displayname	setImage
	* @description	I insert an image into the card returned to the Alexa app
	* @param		smallImageUrl {String} required - I am the url to a 720w x 480h version of the image
	* @param 		largeImageUrl {String} - I am the url to a 1200w x 800h version of the image
	* @return		void
	*/
	public void function setImage( required string smallImageUrl, string largeImageUrl = '' ) {

		this.AlexaResponse.response.card.type = "Standard";
		this.AlexaResponse.response.card[ "image" ] = {
			"smallImageUrl" = arguments.smallImageUrl
		};
		if( len( arguments.largeImageUrl ) ) {
			this.AlexaResponse.response.card[ "image" ][ "largeImageUrl" ] = arguments.largeImageUrl;
		}

		this.AlexaResponse.response.card[ "text" ] = this.AlexaResponse.response.card[ "content" ];
		structDelete( this.AlexaResponse.response.card, "content" );

	}

	/* 
	
	BASIC Intent Handlers
	
	*/
	
	/**
	* @displayname	onLaunch
	* @description	I set up a new session
	* @return		void
	*/
	private void function onLaunch( required struct sessionInfo ) {

		application.AlexaSessions[ arguments.sessionInfo.sessionId ] = {
			history = []
		};

	}
	
	/**
	* @displayname	onSessionEnd
	* @description	I clear out sessions
	* @return		void
	*/
	public void function onSessionEnd( required struct sessionInfo ) {

		structDelete( application.AlexaSessions, sessionInfo.sessionId );

	}
	
	/**
	* @displayname	setSessionVariable
	* @description	I set a session variable
	* @return		void
	*/
	public void function setSessionVariable( required string key, required string value ) {

		application.AlexaSessions[ this.sessionId ][ arguments.key ] = arguments.value;

	}
	
	/**
	* @displayname	getSessionVariable
	* @description	I return a session variable
	* @return		string
	*/
	public string function getSessionVariable( required string key ) {

		return application.AlexaSessions[ this.sessionId ][ arguments.key ];

	}

	/*

	Maintain session history

	*/

	/**
	* @displayname	setHistory
	* @description	I set the session history
	* @return		void
	*/
	public void function setHistory( required string intent, required string slots ) {

		if( this.isTesting and not structkeyExists( application.AlexaSessions, this.sessionId ) ) {
			application.AlexaSessions[ this.sessionId ] = {
				history = []
			};
		}
		arrayPrepend( application.AlexaSessions[ this.sessionId ].history, {
			intent = arguments.intent,
			slots = arguments.slots
		});

	}

	/**
	* @displayname	getHistory
	* @description	I return the session history
	* @return		array
	*/
	public array function getHistory() {

		return application.AlexaSessions[ this.sessionId ].history;

	}

	/**
	* @displayname	getLastIntent
	* @description	I return the last intent
	* @return		struct
	*/
	public struct function getLastIntent() {

		if( arraylen( application.AlexaSessions[ this.sessionId ].history ) lte 1 {
			return {};
		} else {
			return application.AlexaSessions[ this.sessionId ].history[ 2 ];
		}

	}

	/*
	
	ENDPOINT
	
	*/

	/**
	* @displayname	get
	* @description	I am the endpoint of the Alexa application
	* @return		struct (JSON)
	*/
	remote struct function get() returnformat='json' {

		local.request = deserializeJson(
				toString( getHttpRequestData().content )
			);

			this.sessionid = local.request.session.sessionid;

			switch( local.request.request.type ) {

				case "IntentRequest":
					
					local.methodName = local.request.request.intent.name;

					local.attribCollection = {};
					if( structkeyexists( local.request.request.intent, "slots" );
						local.slots = local.request.request.intent.slots;
					} else {
						local.slots = {};
					}
					
					for( local.thisItem in local.slots ) {

						if( structkeyExists( local.slots[ local.thisitem ], "value" );
							local.attribCollection[ local.slots[ local.thisItem ].name ] = local.slots[ local.thisItem ].value;
						} else {
							/* handle optional values */
							local.attribCollection[ local.slots[ local.thisItem ].name ] = "";
						}

					}

					/* store intent info for on-going conversations */
					setHistory( local.methodName, attribCollection );

					/* get target method name from this.intents */
					cfcMethod = variables[ this.intents[ local.methodName ] ];

					cfcMethod( argumentCollection = local.attribCollection );

					return getResponse();
					break;

				case "LaunchRequest":

					this.sessionid = local.request.session.sessionid;
					onLaunch( local.request.session );
					return getResponse();
					break;
				
				case "SessionEndedRequest":

					onSessionEnd( local.request.session );
					return {};
					break;
		}

	}

	/**
	* @displayname	getResponse
	* @description	I return the response ssml
	* @return		struct
	*/
	public struct function getResponse() {

		local.response = duplicate( this.AlexaResponse );
		local.response.response.outputSpeech.ssml = "<speak;" & local.response.response.outputSpeech.ssml & "</speak;";

		return local.response;

	}


	/* helper functions */

	/**
	* @displayname	parseDates
	* @description	I get the start and end dates from the ALexa date format
	* @param		date {String} required - I am the Alexa format date string
	* @return		struct
	*/
	public struct function parseDates( required string date ) {

		local.datePieces = listToArray(arguments.date,"-");
		
		if( date contains "W" ) {
			
			if( arraylen( local.datePieces ) is 2 and local.datePieces[ 2 ] contains "W" ) {
				return parseWeek( local.datePieces );
			} else if( arraylen( local.datePieces ) is 3 {
				return parseWeekendDates( local.datepieces );
			}	
		
		} else {
		
			local.startdate = createdatetime( datepieces[ 1 ], datepieces[ 2 ], datepieces[ 3 ], 0, 0, 0 );
			local.enddate = createdatetime( datepieces[ 1 ], datepieces[ 2 ], datepieces[ 3 ], 23, 59, 59 );
			
			return {
				startDate = dateformat( local.startDate, 'mm/dd/yyyy' ) & " " & timeformat( local.startDate, "HH:nn" ),
				endDate = dateformat( local.startDate, 'mm/dd/yyyy' ) & " " & timeformat( local.endDate, "HH:nn" )
			};

		}

	}

	/**
	* @displayname	parseWeekendDates
	* @description	I get the weekend start and end dates 
	* @param		date {Array} required - I am the date array from parseDates
	* @return		struct
	*/
	private struct function parseWeekendDates( required array date ) {

		local.weekNumber = removeChars( arguments.date[ 2 ], 1, 1 );
		local.weekStart = parseDatetime( getDateByWeek( arguments.date[ 1 ], local.weekNumber ) );
		local.weekendStart = dateAdd( 'd', 5, local.weekStart );
		local.weekendEnd = dateAdd( 'd', 1, local.weekendStart );

		return {
			startDate = dateFormat( local.weekendStart, "mm/dd/yyyy" ),
			endDate = dateFormat( local.weekendEnd, "mm/dd/yyyy" ) & " 23:59"
		};

	}

	/**
	* @displayname	parseWeek
	* @description	I get the week start and end dates 
	* @param		date {Array} required - I am the date array from parseDates
	* @return		struct
	*/
	private struct function parseWeek( required array date ) {

		if( !arraylen( arguments.date ) is 2 ) {
			throw message="invalid format for week specification";
		}

		local.weekNumber = removeChars( arguments.date[ 2 ], 1, 1 );
		 
		local.startDate = getDateByWeek( arguments.date[ 1 ], local.weekNumber );
		 
		local.endDate = dateAdd( 'd', 6, parseDatetime( local.startDate ) );
		local.endDate = dateformat( local.endDate, 'mm/dd/yyyy' ) & " 23:59";

		return {
			startDate = local.startDate,
			endDate = local.endDate
		};

	}

	/**
	* @displayname	getDateByWeek
	* @description	Gets the first day of the week of the given year/week combo, by Ben Nadel, tweaked by Steve Drucker - returns monday date
	* @param		year {Numeric} required - I am the year we are looking at
	* @param 		week {Numeric} - I am the week we are looking at (1-53).
	* @return		date
	*/
	public date function getDateByWeek( required numeric year, required numeric week ) {

		local.firstDayOfYear = CreateDate( arguments.year, 1, 1 );

		local.firstDayOfCalendarYear = ( local.firstDayOfYear - DayOfWeek( local.firstDayOfYear ) + 2 );

		local.firstDayOfWeek = ( local.firstDayOfCalendarYear + ( ( arguments.week - 1 ) * 7 ) );

		return DateFormat( local.firstDayOfWeek, 'mm/dd/yyyy' );

	}

}