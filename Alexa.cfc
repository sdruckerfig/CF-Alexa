<cfcomponent>

	<!---
	
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
	 

	--->

	<cfset this.isTesting = true>

	<cfsavecontent variable="this.responseTemplate">
		{
		  "version" : "1.0",
		  "sessionAttributes" : {},
		  "response" : {
		  	"outputSpeech" : {
		  	  "type" : "SSML",
		  	  "ssml" : ""
		  	},
		  	"card" : {
		  	  "type" : "Simple",
		  	  "title"  : "",
		  	  "content"  : ""
		  	},
		  	"reprompt" : {
		  		"outputSpeech" : {
		  		   "type" : "PlainText",
		  		   "text" :  "Can I help you with anything else?"
		  		}
		  	},
		  	"shouldEndSession" : false
		  }
		}
	</cfsavecontent>

	
	<cfset this.AlexaResponse = deserializeJson(this.responseTemplate)>


	<cffunction name="say" access="public" returntype="void">
		<cfargument name="text" required="yes">

		<cfset this.AlexaResponse.response.outputSpeech.ssml = this.AlexaResponse.response.outputSpeech.ssml & "<p>" & arguments.text & "</p>">

	</cffunction>

	<cffunction name="endSession" access="public" returntype="void">
		<cfset this.AlexaResponse.response.shouldEndSession = true>
	</cffunction>


	<!--- 

	CARD HANDLING

	--->
	<cffunction name="setTitle" access="public" returntype="void">
		<cfargument name="title" required="yes">

		<cfset this.AlexaResponse.response.card.title = arguments.title>

	</cffunction>

	<cffunction name="setText" access="public" returntype="void">
		<cfargument name="content" required="yes">

		<cfif structKeyExists(this.AlexaResponse.response.card,"image")>
			<cfset this.AlexaResponse.response.card.text = arguments.content>
		<cfelse>
			<cfset this.AlexaResponse.response.card.content = arguments.content>
		</cfif>

	</cffunction>

	<cffunction name="setImage" access="public" returntype="void">
		
		<cfargument name="smallImageUrl" required="yes" hint="720w x 480h">
		<cfargument name="largeImageUrl" required="no" hint="1200w x 800h" default="">

		<cfset this.AlexaResponse.response.card.type="Standard">
		<cfset this.AlexaResponse.response.card["image"] = {
			"smallImageUrl" = arguments.smallImageUrl
		}>
		<cfif arguments.largeImageUrl is not "">
			<cfset this.AlexaResponse.response.card["image"]["largeImageUrl"] = arguments.largeImageUrl>
		</cfif>

		<cfset this.AlexaResponse.response.card["text"] = this.AlexaResponse.response.card["content"]>
		<cfset structDelete(this.AlexaResponse.response.card,"content")>

	</cffunction>

	<!--- 
	
	BASIC Intent Handlers
	
	--->

	<cffunction name="onLaunch" access="private" returntype="void">
		<cfargument name="sessionInfo" required="yes">
		<cfset Application.AlexaSessions[arguments.sessionInfo.sessionId] = {
			history = []
		}>
	</cffunction>

	<cffunction name="onSessionEnd" access="public" returntype="void">
		<cfargument name="sessionInfo" required="yes">
		<cfset structDelete(application.AlexaSessions,sessionInfo.sessionId)>
	</cffunction>

	<cffunction name="setSessionVariable" access="public" returntype="void">
	
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="string" reqired="yes">

		<cfset Application.AlexaSessions[this.sessionId][arguments.key] = arguments.value>

	</cffunction>

	<cffunction name="getSessionVariable" access="public" returntype="any">
	
		<cfargument name="key" type="string" required="yes">
		

		<cfreturn Application.AlexaSessions[this.sessionId][arguments.key]>

	</cffunction>

	<!---

	Maintain session history

	--->
	<cffunction name="setHistory" access="public" returnType="void">
		<cfargument name="intent" type="string" required="yes">
		<cfargument name="slots" type="struct" required="yes">

		<cfif not structkeyExists(Application,"AlexaSessions")>
			<cfset Application.AlexaSessions = {}>
		</cfif>
		<cfif not structkeyExists(application.AlexaSessions,this.sessionId)>
			<cfset Application.AlexaSessions[this.sessionId] = {
				history = []
			}>
		</cfif>

		<cfset arrayPrepend(application.AlexaSessions[this.sessionId].history, {
			intent = arguments.intent,
			slots = arguments.slots
		})>
	</cffunction>

	<cffunction name="getHistory" access="public" returntype="array">
		<cfreturn application.AlexaSessions[this.sessionId].history>
	</cffunction>

	<cffunction name="getLastIntent" access="public" returntype="struct">

		<cfif arraylen(application.AlexaSessions[this.sessionId].history) le 1>
			<cfreturn {}>
		<cfelse>
			<cfreturn application.AlexaSessions[this.sessionId].history[2]>
		</cfif>

	</cffunction>

	<!---
	
	ENDPOINT
	
	--->

	<cffunction name="get" access="remote" returntype="struct" returnformat="json">
	  
	  <cfset local.request = deserializeJson(
        toString(getHttpRequestData().content)
   	  )>

   	  <cfset this.sessionid = local.request.session.sessionid>

   	  <cfswitch expression="#local.request.request.type#">
   	  	<cfcase value="IntentRequest">
	   	  	
	   	  	<cfset local.methodName = local.request.request.intent.name>

	   	  	<cfset local.attribCollection = {}>
	   	  	<cfif structkeyexists(local.request.request.intent,"slots")>
	   	  		<cfset local.slots = local.request.request.intent.slots>
	   	  	<cfelse>
	   	  		<cfset local.slots = {}>
	   	  	</cfif>
	   	  	
	   	  	<cfloop collection="#local.slots#" item="local.thisItem">
	   	  		
	   	  		<cfif structkeyExists(local.slots[local.thisitem],"value")>
	   	  			<cfset local.attribCollection[local.slots[local.thisItem].name] = local.slots[local.thisItem].value>
	   	  		<cfelse>
	   	  			<!--- handle optional values --->
	   	  			<cfset local.attribCollection[local.slots[local.thisItem].name] = "">
	   	  		</cfif>
	   	  	</cfloop>


	   	  	<!--- store intent info for on-going conversations --->
	   	  	<cfset setHistory(local.methodName,attribCollection)>

	   	  	<!--- get target method name from this.intents --->
	   	  	<cfset cfcMethod = variables[this.intents[local.methodName]]>

	  		<cfset cfcMethod(argumentCollection=local.attribCollection)>
	  		<cfreturn getResponse()>
   	  	</cfcase>
   	  	<cfcase value="LaunchRequest">
   	  		<cfset this.sessionid = local.request.session.sessionid>
   	  		<cfset onLaunch(local.request.session)>
   	  		<cfreturn getResponse()>
   	  	</cfcase>
   	  	<cfcase value="SessionEndedRequest">
   	  		<cfset onSessionEnd(local.request.session)>
   	  		<cfreturn {}>
   	  	</cfcase>
	 </cfswitch>
	</cffunction>


	<cffunction name="getResponse" access="public" returntype = "struct">
		<cfset local.response = duplicate(this.AlexaResponse)>
		<cfset local.response.response.outputSpeech.ssml = "<speak>" & local.response.response.outputSpeech.ssml & "</speak>">
		<cfreturn local.response>
	</cffunction>


	<!--- helper functions --->
	<cffunction name="parseDates" access="public" returntype="struct">
		
		<cfargument name="date" type="string" required="yes">

		<cfset local.retval = {
		   startdate="",
		   enddate = ""
		}>

		<cfset local.datePieces = listToArray(arguments.date,"-")>
		
		<cfif date contains "W">	
			
			<cfif arraylen(local.datePieces) is 2 and local.datePieces[2] contains "W">
				<cfset local.retval = parseWeek(local.datePieces)>
			<cfelseif arraylen(local.datePieces) is 3>
			    <cfset local.retval = parseWeekendDates(local.datepieces)>
			</cfif>	
		
		<cfelse>
		
			<cfset local.startdate = createdatetime(datepieces[1],datepieces[2],datepieces[3],0,0,0)>
			<cfset local.enddate = createdatetime(datepieces[1],datepieces[2],datepieces[3],23,59,59)>
			
			<cfset local.retval = {
				startDate = dateformat(local.startDate,'mm/dd/yyyy') & " " & timeformat(local.startDate, "HH:nn"),
				endDate = dateformat(local.startDate,'mm/dd/yyyy') & " " & timeformat(local.endDate,"HH:nn")
			}>

		</cfif>

		<cfreturn local.retval>

	</cffunction>


	<cffunction name="parseWeekendDates" access="private" returntype="struct">

		<cfargument name="date" type="array"  required="yes">

		<cfset local.weekNumber = removeChars(arguments.date[2],1,1)>
		<cfset local.weekStart = parseDatetime(GetDateByWeek(arguments.date[1],local.weekNumber))>
		<cfset local.weekendStart = dateAdd('d',5,local.weekStart)>
		<cfset local.weekendEnd = dateAdd('d',1,local.weekendStart)>

		<cfreturn {
			startDate = dateFormat(local.weekendStart,"mm/dd/yyyy"),
			endDate = dateFormat(local.weekendEnd,"mm/dd/yyyy") & " 23:59"
		}>

	</cffunction>

	<cffunction name="parseWeek" access="private" returntype="struct">
		<cfargument  name="date" type="array" required="yes">

		<cfif arraylen(arguments.date) is 2>

           <cfset local.weekNumber = removeChars(arguments.date[2],1,1)>
           
           <cfset local.startDate = getDateByWeek(arguments.date[1],local.weekNumber)>
           
           <cfset local.endDate =  dateAdd('d',6,parseDatetime(local.startDate))>
           <cfset local.endDate = dateformat(local.endDate,'mm/dd/yyyy') & " 23:59">


           <cfreturn {
             startDate =  local.startDate,
             endDate = local.endDate
           }>

        <cfelse>
         	<cfthrow message="invalid format for week specification">
        </cfif>
	</cffunction>

	<cffunction
    name="GetDateByWeek"
    access="public"
    returntype="date"
    output="false"
    hint="Gets the first day of the week of the given year/week combo, by Ben Nadel, tweaked by Steve Drucker - returns monday date">

    <!--- Define arguments. --->
    <cfargument
        name="Year"
        type="numeric"
        required="true"
        hint="The year we are looking at."
        />

    <cfargument
        name="Week"
        type="numeric"
        required="true"
        hint="The week we are looking at (1-53)."
        />

    <!---
        Get the first day of the year. This one is
        easy, we know it will always be January 1st
        of the given year.
    --->
    <cfset LOCAL.FirstDayOfYear = CreateDate(
        ARGUMENTS.Year,
        1,
        1
        ) />

    <!---
        Based on the first day of the year, let's
        get the first day of that week. This will be
        the first day of the calendar year.
    --->
    <cfset LOCAL.FirstDayOfCalendarYear = (
        LOCAL.FirstDayOfYear -
        DayOfWeek( LOCAL.FirstDayOfYear ) +
        2
        ) />

    <!---
        Now that we know the first calendar day of
        the year, all we need to do is add the
        appropriate amount of weeks. Weeks are always
        going to be seven days.
    --->
    <cfset LOCAL.FirstDayOfWeek = (
        LOCAL.FirstDayOfCalendarYear +
        (
            (ARGUMENTS.Week - 1) *
            7
        )) />


    <!---
        Return the first day of the week for the
        given year/week combination. Make sure to
        format the date so that it is not returned
        as a numeric date (this will just confuse
        too many people).
    --->
    <cfreturn DateFormat( LOCAL.FirstDayOfWeek,'mm/dd/yyyy' ) />
</cffunction>

</cfcomponent>
