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

		this.AlexaResponse.response.outputSpeech.ssml &= "<p>" & arguments.text & "</p>";

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
			this.AlexaResponse.response.card[ "text" ] = arguments.content;
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
	public void function setImage( required string smallImageUrl, string largeImageUrl = "" ) {

		this.AlexaResponse.response.card.type = "Standard";
		this.AlexaResponse.response.card[ "image" ] = {
			"smallImageUrl" = arguments.smallImageUrl
		};
		if( len( arguments.largeImageUrl ) ) {
			this.AlexaResponse.response.card[ "image" ][ "largeImageUrl" ] = arguments.largeImageUrl;
		}

		if( structKeyExists( this.AlexaResponse.response.card, "content" ) ) {
			this.AlexaResponse.response.card[ "text" ] = this.AlexaResponse.response.card.content;
			structDelete( this.AlexaResponse.response.card, "content" );
		}

	}

	/* 
	
	BASIC Intent Handlers
	
	*/
	
	/**
	* @displayname	onLaunch
	* @description	I set up a new session
	* @return		void
	*/
	private void function onLaunch() {

		application.AlexaSessions[ this.sessionId ] = {
			history = []
		};

	}
	
	/**
	* @displayname	onSessionEnd
	* @description	I clear out sessions
	* @return		void
	*/
	public void function onSessionEnd() {

		structDelete( application.AlexaSessions, this.sessionId );

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

		var request = deserializeJson( toString( getHttpRequestData().content ) );
		var methodName = '';
		var attribCollection = {};
		var slots = {};
		var slot = '';

		this.sessionid = request.session.sessionid;

		switch( request.request.type ) {

			case "IntentRequest":
				
				methodName = request.request.intent.name;

				if( structKeyExists( request.request.intent, "slots" );
					slots = request.request.intent.slots;
				}
				
				for( slot in slots ) {

					if( structKeyExists( slots[ slot ], "value" );
						attribCollection[ slots[ slot ].name ] = slots[ slot ].value;
					} else {
						/* handle optional values */
						attribCollection[ slots[ slot ].name ] = "";
					}

				}

				/* store intent info for on-going conversations */
				setHistory( methodName, attribCollection );

				/* get target method name from this.intents */
				cfcMethod = variables[ this.intents[ methodName ] ];

				cfcMethod( argumentCollection = attribCollection );

				return getResponse();
				break;

			case "LaunchRequest":

				onLaunch();
				return getResponse();
				break;
			
			case "SessionEndedRequest":

				onSessionEnd();
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

		var response = duplicate( this.AlexaResponse );
		response.response.outputSpeech.ssml = "<speak>" & response.response.outputSpeech.ssml & "</speak>";

		return response;

	}

	/* helper functions */

	/**
	* @displayname	parseDates
	* @description	I get the start and end dates from the ALexa date format
	* @param		date {String} required - I am the Alexa format date string
	* @return		struct
	*/
	public struct function parseDates( required string date ) {

		var datePieces = listToArray( arguments.date, "-" );
		var startDate = '';
		var endDate = '';
		
		if( arguments.date contains "W" ) {
			
			if( arraylen( datePieces ) is 2 and datePieces[ 2 ] contains "W" ) {
				return parseWeek( datePieces );
			} else if( arraylen( datePieces ) is 3 {
				return parseWeekendDates( datepieces );
			}	
		
		} else {
		
			startdate = createdatetime( datepieces[ 1 ], datepieces[ 2 ], datepieces[ 3 ], 0, 0, 0 );
			enddate = createdatetime( datepieces[ 1 ], datepieces[ 2 ], datepieces[ 3 ], 23, 59, 59 );
			
			return {
				startDate = dateformat( startDate, 'mm/dd/yyyy' ) & " " & timeformat( startDate, "HH:nn" ),
				endDate = dateformat( endDate, 'mm/dd/yyyy' ) & " " & timeformat( endDate, "HH:nn" )
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

		var weekNumber = removeChars( arguments.date[ 2 ], 1, 1 );
		var weekStart = parseDatetime( getDateByWeek( arguments.date[ 1 ], weekNumber ) );
		var weekendStart = dateAdd( 'd', 5, weekStart );

		return {
			startDate = dateFormat( weekendStart, "mm/dd/yyyy" ) & " 00:00",
			endDate = dateFormat( dateAdd( 'd', 1, weekendStart ), "mm/dd/yyyy" ) & " 23:59"
		};

	}

	/**
	* @displayname	parseWeek
	* @description	I get the week start and end dates 
	* @param		date {Array} required - I am the date array from parseDates
	* @return		struct
	*/
	private struct function parseWeek( required array date ) {

		var weekNumber = removeChars( arguments.date[ 2 ], 1, 1 );
		var startDate = getDateByWeek( arguments.date[ 1 ], weekNumber );

		return {
			startDate = startDate,
			endDate = dateformat( dateAdd( 'd', 6, parseDatetime( startDate ) ), 'mm/dd/yyyy' ) & " 23:59";
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

		var firstDayOfYear = CreateDate( arguments.year, 1, 1 );

		var firstDayOfCalendarYear = ( firstDayOfYear - DayOfWeek( firstDayOfYear ) + 2 );

		var firstDayOfWeek = ( firstDayOfCalendarYear + ( ( arguments.week - 1 ) * 7 ) );

		return DateFormat( firstDayOfWeek, 'mm/dd/yyyy' );

	}

}