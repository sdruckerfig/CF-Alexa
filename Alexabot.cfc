<!---

Sample invocation of the CF-Alexa Framework

--->

<cfcomponent extends="Alexa">

	<!--- 
	Define your intents here 
	
	The framework will automatically call the associated function
	and pass slot values as arguments.
	
	--->

	<cfset this.intents = {
		"MemberSearch"  = "getMemberInfo",
		"eventCalendarSearchIntent"  = "onGetCalendarEvents",
		"AMAZON.HelpIntent" = "onHelp",
		"AMAZON.CancelIntent" = "onStop",
		"AMAZON.StopIntent" = "onStop",
		"AMAZON.NoIntent" = "onStop",
		"AMAZON.YesIntent" = "onContinue"
	}>




	<!---
	
	INTENT Handlers
	
	--->

	<cffunction name="onContinue" access="public" returntype="void">

		<cfset local.lastIntent = getLastIntent()>

		<cfif structkeyexists(local.lastintent,"intent")>
			<cfswitch expression="#local.lastintent.intent#">
				<cfcase value="eventCalendarSearchIntent">
					<cfset say("Ok. I'm Listening...")>
				</cfcase>
				<cfdefaultcase>
					<cfset onHelp()>
				</cfdefaultcase>
			</cfswitch>
		<cfelse>
			<cfset onHelp()>
		</cfif>

	</cffunction>


	<cffunction name="onGetCalendarEvents" access="public" returntype="void">
		<cfargument name="date" type="string" required="no">

		<cfset stDates = parseDates(arguments.date)>
		
		<cfset local.startdate = parsedatetime(stdates.startdate)>
		<cfset local.startdate = 
		dateformat(local.startdate,"yyyy-mm-dd") & " " & timeformat(local.startdate,"HH:mm")>

		<cfset local.enddate = parsedatetime(stdates.enddate)>
		<cfset local.enddate = 
		dateformat(local.enddate,"yyyy-mm-dd") & " " & timeformat(local.enddate,"HH:mm")>


		<!--- get events --->
		<cfset local.cfcCS = createObject("component","CommonSpot")>
		<cfset local.events = local.cfcCS.getEvents()>
		
		<cfquery dbtype="query" name="local.events">
			select *
			from events
			where eventdate >= '#local.startdate#'
			and eventdate <= '#local.enddate#'
		</cfquery>
		
		<cfset say("I found #local.events.recordcount# events")>
		<cfloop query="local.events">
			
			<cfset local.eventdate = listToArray(left(local.events.eventdate,10),"-")>
			<cfset local.eventDate = createDate(local.eventdate[1],local.eventdate[2],local.eventdate[3])>
			<cfset local.eventDate = dateformat(local.eventdate,"dddd, mmmm d")>

			<cfset say("On #local.eventdate#, #local.events.title#")>
		</cfloop>

	</cffunction>


	<cffunction name="onStop" access="public" returntype="void">

		<cfset say("Goodbye.")>
		<cfset endSession()>

	</cffunction>

	<cffunction name="onHelp" access="public" returntype="void">

		<cfset say("To get information about a member, say how about member firstname lastname")>
		
		<cfset say("To hear about scheduled events, say what's going on today? what's going on tomorrow?, what's going on this week?, or what's going on on a specific date")>


	</cffunction>

	<cffunction name="getMemberInfo" access="public" returntype="void">
	
		<cfargument name="memberfirstname" type="string" required="yes">
		<cfargument name="memberlastname" type="string" required="yes">
		<cfargument name="city" type="string" required="no" default="">

		
		 <cfquery name="local.qgetmembers" datasource="somedsn">
            SELECT *
            FROM MemberSearch m 
            WHERE m.PUBLISH <> 1

            <cfif arguments.memberlastname is not "">
            	AND m.LAST_NAME LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.memberlastname#">
            </cfif>
            <cfif arguments.memberfirstname  is not "">
            	AND m.FIRST_NAME LIKE  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.memberfirstname#">
            </cfif>   
            <cfif arguments.city is not "">
            	AND m.CITY LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.city#">
            </cfif>

            ORDER BY m.LAST_NAME, m.FIRST_NAME
        </cfquery>


        <!--- try with soundex if it's a fail --->
        <cfif local.qgetmembers.recordcount is 0>
	        
	         <cfquery name="local.qgetmembers" datasource="somedsn">
	            SELECT *
	            FROM MemberSearch m 
	            WHERE m.PUBLISH <> 1
	            
	            <cfif arguments.memberlastname is not "">
	            	
	            	<!--- try first 3 letters --->
	            	AND left(m.last_NAME,3) like <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(arguments.memberlastname,3)#%">

	            	<!--- plus soundex --->
	            	AND soundEx(m.LAST_NAME) = soundEx(<cfqueryparam cfsqltype="cf_sql_varchar" value= "#arguments.memberlastname#">)

	            </cfif>
	            
	            <cfif arguments.memberfirstname  is not "">
	            	AND m.FIRST_NAME LIKE  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.memberfirstname#">
	            </cfif>   
	            <cfif arguments.city is not "">
	            	AND m.CITY LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.city#">
	            </cfif>

	            ORDER BY m.LAST_NAME, m.FIRST_NAME
	        </cfquery>

        </cfif>

        <cfif local.qgetmembers.recordcount is 0>
			<cfset say("I'm sorry, but I didn't find anyone named #arguments.memberfirstname# #arguments.memberlastname#")>
			<cfset setTitle("#arguments.memberfirstname# #arguments.memberlastname#")>
			<cfset setText("Member not found")>
		<cfelse>
			<cfif local.qgetMembers.recordcount is 1>

				<cfsavecontent variable="local.response">
				<cfoutput>#local.qGetMembers.first_name# #local.qgetmembers.last_name# of #local.qgetmembers.city#, #local.qgetmembers.state# was graduated from the #local.qgetmembers.law_school# law school.</cfoutput>
				</cfsavecontent>
			
				<cfif local.qgetmembers.company is not "">
					<cfset local.response &= "#local.qgetmembers.prefix# #local.qgetmembers.last_name# is currently employed by #local.qgetmembers.company#.">
				</cfif>

				<cfset local.response = replace(local.response,"&"," and ","ALL")>

				<cfset say(trim(local.response))>
				<cfset setTitle("#local.qGetMembers.first_name# #local.qGetMembers.last_name#")>
				<cfset setText(local.response)>
			<cfelse>
				<cfset say("I found #local.qgetmembers.recordcount# matches.")>
			</cfif>
			
       	</cfif>
    

	</cffunction>

	
	<cffunction name="onLaunch" access="public" returntype="void">
		<cfargument name="sessionInfo" required="yes">


		<cfset super.onLaunch(arguments.sessionInfo)>

		<cfset say("Welcome to the State Bar")>
		<cfset say("You can ask for information about any member, ask about events and add them to your calendar, check your membership status, or renew your membership.")>
	</cffunction>


</cfcomponent>