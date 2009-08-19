<%@ include file="/WEB-INF/template/include.jsp" %>

<openmrs:require privilege="Register Patients" otherwise="/module/amrsregistration/login.htm" redirect="/module/amrsregistration/registration.form"/>

<%@ include file="/WEB-INF/template/headerMinimal.jsp" %>
<%@ include file="localHeader.jsp" %>
<openmrs:htmlInclude file="/dwr/interface/DWRPatientService.js" />
<openmrs:htmlInclude file="/dwr/interface/DWRAmrsRegistrationService.js" />
<openmrs:htmlInclude file="/dwr/engine.js" />
<openmrs:htmlInclude file="/dwr/util.js" />
<openmrs:htmlInclude file="/scripts/calendar/calendar.js" />
<openmrs:htmlInclude file="/moduleResources/amrsregistration/scripts/jquery-1.3.2.min.js" />
<openmrs:htmlInclude file="/moduleResources/amrsregistration/scripts/common.js" />
<openmrs:htmlInclude file="/moduleResources/amrsregistration/scripts/jquery.tablesorter.min.js" />

<%@ include file="portlets/dialogContent.jsp" %>
<script type="text/javascript">

    // Number of objects stored.  Needed for 'add new' purposes.
    var numObjs = new Array();
    numObjs["identifier"] = ${fn:length(patient.identifiers)};
    numObjs["name"] = ${fn:length(patient.names)};
    numObjs["address"] = ${fn:length(patient.addresses)};
    
    // number of identifier that is a target identifier	
	requiredIdType = 0;
    <c:forEach var="identifier" items="${patient.identifiers}" varStatus="varStatus">
        <c:if test="${amrsIdType == identifier.identifierType.name}">
        	requiredIdType ++;
        </c:if>
    </c:forEach>
    
    // Search time out variable. Need to clear this variable to cancel the server request, thus
    // preventing multiple request being submitted to the server.
    // Reset when:
    // - dwr return a result
    // - user entered more alpha-numeric or delete or backspace character
	searchTimeout = null;
	// how long should we wait after keystroke before dwr submit the request
	searchDelay = 1000;
    
    // variable that will hold the attributes shown in the screen and their values
    var attributes = null;
    
    $j(document).ready(function() {
		// selecting a patient from the potential matches
		// get the <tr> --> get the value of input element inside it and send it to server to get the patient object
		$j('.match').click(function(){
			var tr = $j(this).parent();
			var children = $j(tr).children(':input');
			var id = $j(children).attr('value');
			getPatientByIdentifier(jQuery.trim(id));
		});
		// show highlight effect on the selected row
		$j('.match').hover(
			function() {
				var parent = $j(this).parent();
				$j(parent).addClass("searchHighlight");
			},
			function() {
				var parent = $j(this).parent();
				$j(parent).removeClass("searchHighlight");
			}
		);
		// more or less toggle function
		$j('a[name=extendedToggle]').click(function(e) {
			e.preventDefault();
			// toggle the extended match result row
			$j('.resultTableExtended').toggle();
			// show more or less link
			if ($j('.resultTableExtended').is(':hidden')) {
				$j(this).html('more >>');
			} else {
				$j(this).html('<< less');
			}
		});
		
		// don't bold the <th> content
        $j('th').css('font', '1em verdana');
        // remove top border to prevent overlapping border
        $j('th').css('border-top', '0px');
		
		// make the search result table sortable
        $j("#tableSorter").tablesorter();
        
        // show the potential matches
		<c:if test="${fn:length(potentialMatches) > 0}">$j('#resultTableHeader').show();</c:if>
		
    });
    
    function getPatientByIdentifier(identifier) {
    	DWRAmrsRegistrationService.getPatientByIdentifier(identifier, renderPatientData);
    }
	
	function cancel() {
		// dismiss the mask (selecting from potential matches patient will show the mask)
		$j('#mask').hide();
		$j('.window').hide();
	}
    
    function updateData(identifier) {
    	// get the form and reset the form
    	$j(document.forms[0].reset());
    	// attach the patient id to the form
    	var hiddenInput = $j(document.createElement("input"));
    	$j(hiddenInput).attr("type", "hidden");
    	$j(hiddenInput).attr("name", "patientIdInput");
    	$j(hiddenInput).attr("id", "patientIdInput");
    	$j(hiddenInput).attr("value", identifier);
    	$j('#boxes').append($j(hiddenInput));
    	// submit the form
    	$j(document.forms[0].submit());
    }
		
	function createPreferred(preferred, type, id, container, hidden) {
		// container of the preferred will be <tr> for id and name
		// <table> for address
		var element = null;
			
		var input = $j(document.createElement('input'));
		$j(input).attr('type', 'radio');
		$j(input).attr('name', type + 'Preferred');
		$j(input).attr('value', id);
		if(preferred) {
			$j(input).attr('checked', 'checked');
		}
			
		if (type == 'address') {
			// for address, element is a row
			element = $j(document.createElement('tr'));
			
			td = $j(document.createElement('td'));
			$j(td).attr('colspan', '2');
			
			$j(element).append(td);
			
			$j(td).append(input);
			
			var label = $j(document.createTextNode('Preferred'));
			$j(td).append(label);
			
			$j(container).prepend(element);
		} else {
			// for identifier and name, the element is a cell
			element = $j(document.createElement('td'));
			
			$j(element).append(input);
			
			$j(container).append(element);
		}
		
		if (hidden)
			$j(element).hide();
	}
	
	function getTemplateType(type) {
		// the following are the id of the template for name, address and identifier
		// this element must exist and must be bind to an emptyName, emptyAddress and emptyIdentifier
		if (type == 'name')
			return $j('#nameContent').find('tr');
		if (type == 'address')
			return $j('#addressContent').find('table');
		if (type == 'identifier')
			return $j('#identifierContent');
	}
	
	function duplicateElement(type, id) {
		// clone the template and add preferred section
		var templateClone = getTemplateType(type).clone(true);
		createPreferred(false, type, id, templateClone, false);
		
		// custom mods for address
		if (type == 'address') {
			var td = $j(document.createElement('td'));
			td.append(templateClone);
			var tr = $j(document.createElement('tr'));
			tr.append(td);
			return tr;
		}
		
		return templateClone;
	}
	
	function createElement(type, id) {
		// method that will be called when "add new" button is pressed
		var element = duplicateElement(type, id);
		$j(element).attr('id', type + 'Content' + id);
		return element;
	}

    function addNew(type) {
    	// remove the error message
        $j('#' + type + 'Error').empty();
        
        // get the total number of element in the page (also used for id)
    	var prevIdSuffix = numObjs[type] - 1;
    	if (type == 'identifier')
    		// for identifier, total number rendered is subtracted by the number of targeted identifier attached to the patient
    		prevIdSuffix = prevIdSuffix - requiredIdType;
    		
    	var allowCreate = false;
    	
    	// alert('id: ' + prevIdSuffix);
    	// alert('numObjs['+type+']: ' + numObjs[type]);

		// always allow creating new element where the number is less than 0
    	if (prevIdSuffix < 0) {
    		allowCreate = true;
    	} else {
    		// when more than 0, then get all input element and check whethere one of them is filled
    		var allInputType = $j('#' + type + 'Content' + prevIdSuffix + ' input[type=text]');
    		
	    	for (i = 0; i < allInputType.length; i ++) {
	    		var o = allInputType[i];
	    		str = jQuery.trim(o.value);
	    		// if one of the input element is not empty then allow creating new element
	    		if (str.length > 0) {
	    			// allow creating new object when a non blank element is found
	    			allowCreate = true;
	    			break;
	    		}
	    	}
		}
    	
        if (allowCreate) {
        	// create a new element using the above function
            var newElement = createElement(type, (prevIdSuffix + 1));
            
            // put the new element to the correct position
            // each type will have their own template and position id
            // address: --> template: addressContent
            //          --> position: addressPosition
            //          --> added element: addressContentXX
            // In general, for each type they will have:
            // template: <type>Content
            // position: <type>Position
            // added element: <type>ContentXX
            $j('#' + type + 'Position').append(newElement);
            
            if (prevIdSuffix == 0) {
            	// alert('show flag');
            	
            	// show the preferred label and the preferred radio button when the total number of element more than 1
            	$j('#' + type + 'PreferredLabel').show();
            	var parent = $j('input:radio[name=' + type + 'Preferred]').parent();
            	if (type != 'address')
            		parent.show();
            	else
            		parent.parent().show();
            }
            // focus to the first element
            ele = $j('#' + type + 'Content' + numObjs[type] + ' input[type=text]:eq(0)');
            ele.focus();
            
            numObjs[type] = numObjs[type] + 1;
        }
        
        if (!allowCreate){
        	$j('#' + type + 'Error').html('Adding new row not permitted when the current ' + type + ' is blank');
        }
    }
	
	function removeTemplate() {
		// remove name, id and address template when submitting
		var obj = document.getElementById("identifierContent");
		if (obj != null)
			obj.parentNode.removeChild(obj);
		obj = document.getElementById("nameContent");
		if (obj != null)
			obj.parentNode.removeChild(obj);
		obj = document.getElementById("addressContent");
		if (obj != null)
			obj.parentNode.removeChild(obj);
		
		// remove added element but still blank from the form
		for (key in numObjs)
			deleteRow(key, true);
	}
	
	function deleteLastRow (type) {
		deleteRow(type, false);
	}
	
	function deleteRow(type, submit) {
		
		// remove blank name, id and address that is added but never get filled
		// the check only for the last element because we're not allowing adding
		// new one when the previous one still blank (see addNew)
		
		var prevIdSuffix = numObjs[type] - 1;
		if (type == 'identifier')
			prevIdSuffix = prevIdSuffix - requiredIdType;
		message = "";
    		
		if (prevIdSuffix > 0) {
			// check all input to see if it's blank
			var allInputType = $j('#' + type + 'Content' + prevIdSuffix + ' input[type=text]');
	    	var deleteInputs = true;
	    	for (i = 0; i < allInputType.length; i ++) {
	    		var o = allInputType[i];
	    		str = jQuery.trim(o.value);
	    		if (str.length > 0) {
	    			// don't delete if there's a single element with a value
	    			deleteInputs = false;
	    			break;
	    		}
	    	}
	    	if (deleteInputs) {
    			// alert('id: ' + prevIdSuffix);
    			// alert('type: ' + requiredIdType);
	    		var success = $j('#' + type + "Content" + prevIdSuffix).remove();
	    		numObjs[type] = numObjs[type] - 1;
	    		prevIdSuffix = prevIdSuffix - 1;
	    		// hide radio button when there's only one row left
	    		// assume the last one a preferred one
	    		if (prevIdSuffix == 0) {
	    			$j('#' + type + 'PreferredLabel').hide();
	            	parent = $j('input:radio[name=' + type + 'Preferred]').parent();
	            	if (type != 'address')
	            		$j(parent).hide();
	            	else
	            		$j(parent).parent().hide();
	    		}
	    	} else {
	    		message = "Removing " + type + " not permitted because deleted element is not empty";
	    	}
    	} else {
    		message = "Removing " + type + " not permitted because there is only one row left";
    	}
    	
    	if (!submit) {
    		// clear all element when the user press remove but there's only one element on the screen
    		if (prevIdSuffix <= 0)
    			$j('#' + type + 'Content' + prevIdSuffix + ' input[type=text]').attr("value", "");
    		if (message.length > 0)
	    		$j('#' + type + 'Error').html(message);
	    }
	}
	
	function createCell(content, row) {
		var column = $j(document.createElement('td'));
		var data = $j(document.createTextNode(content));
		$j(column).append($j(data));
		$j(row).append($j(column));
	}
    
    function handlePatientResult(result) {
		clearTimeout(searchTimeout);
    	
    	// clear the tbody from previous search result
		var tbody = $j('#resultTable');
		$j(tbody).empty();
		
		// hide extended toggle, more than ${maxReturned}, result table header
		$j('#extendedToggle').hide();
		$j('#moreMatches').hide();
		$j('#resultTableHeader').hide();
		// show filler (3 blank row and a no patient found text)
    	$j('.filler').show();
		
    	if (result.length > 0) {
    		
    		// check if the max result is returned or not
    		returnedPatient = result.length;
    		if (returnedPatient > ${maxReturned}) {
    			returnedPatient = ${maxReturned};
    			$j('#moreMatches').show();
    		}
    		
    		// loop through all result and display it
    		for(i = 0; i < returnedPatient; i ++) {
    			// create new row
    			var tr = $j(document.createElement('tr'));
    			// zebra like row
    			if (i % 2 == 0)
    				$j(tr).addClass("evenRow");
    			else
    				$j(tr).addClass("oddRow");
    			
    			// mark the fourth element to be an extended result that can be toggled
    			if (i > 2) {
    				$j(tr).addClass('resultTableExtended');
					$j('#extendedToggle').show();
    			}
    			
    			// bind highlight effect
    			$j(tr).hover(
    				function() {
						$j(this).addClass("searchHighlight");
    				},
    				function() {
						$j(this).removeClass("searchHighlight");
    				}
    			);
    			// bind click to show the selected patient
    			$j(tr).click(function() {
					var children = $j(this).children(':input');
					var id = $j(children).attr('value');
					getPatientByIdentifier(jQuery.trim(id));
    			});
    			
    			// create each cell for identifier, given, middle, family name, age, gender, and birthdate (+ estimated)
    			createCell(result[i].identifiers[0].identifier, tr);
    			createCell(result[i].personName.givenName, tr);
    			createCell(result[i].personName.middleName, tr);
    			createCell(result[i].personName.familyName, tr);
    			createCell(result[i].age, tr);
    			
    			var td = $j(document.createElement('td'));
    			
    			var input = $j(document.createElement('input'));
    			$j(input).attr('type', 'hidden');
    			$j(input).attr('name', 'hiddenId' + i);
    			$j(input).attr('value', result[i].patientId);
    			$j(tr).append($j(input));
    			
    			$j(td).css('text-align', 'center');
    			var data = $j(document.createElement('img'));
    			if (result[i].gender == 'F')
    				$j(data).attr('src', "${pageContext.request.contextPath}/images/female.gif");
    			else
    				$j(data).attr('src', "${pageContext.request.contextPath}/images/male.gif");
    			$j(td).append($j(data));
    			$j(tr).append($j(td));
    			
    			if (result[i].birthdateEstimated)
    				createCell('~', tr);
    			else
    				createCell('', tr);
    			
    			createCell(parseDate(result[i].birthdate, '<openmrs:datePattern />'), tr);
    			
    			$j(tbody).append($j(tr));
    		}
    		
    		// show the table and hide the filler
    		$j('#resultTableHeader').show();
    		$j('.filler').hide();
        
            // let the plugin know that we made a update 
            $j("#tableSorter").trigger("update");
    	}
    }
	
	// age function borrowed from http://anotherdan.com/2006/02/simple-javascript-age-function/
	function getAge(d) {
		var age = -1;
		now = new Date();
		while (now >= d) {
			age++;
			d.setFullYear(d.getFullYear() + 1);
		}
		return age;
	}
    
    function isAlphaNumericCharacter(key) {
		 return (key >= 48 && key <= 90) ||
				(key >= 96 && key <= 105);
	}
	
	function isDashCharacter(key) {
		return key == 189 || key == 109;
	}
	
	function isBackspaceDelete(key) {
		return key == 46 || key == 8;
	}
	
	function clickTimeOutSearch() {
		clearTimeout(searchTimeout);
		searchTimeout = setTimeout("patientSearch()", searchDelay);
	}
	
	function timeOutSearch(e) {
		c = e.keyCode;
		
		if (isAlphaNumericCharacter(c) || isDashCharacter(c) || isBackspaceDelete(c)) {
			clearTimeout(searchTimeout);
			searchTimeout = setTimeout("patientSearch()", searchDelay);
		}
	}

    function patientSearch() {

        var personName = {
        	givenName: $j('input[name=names[0].givenName]').attr('value'),
        	middleName: $j('input[name=names[0].middleName]').attr('value'),
        	familyName: $j('input[name=names[0].familyName]').attr('value')
        }
        // alert(DWRUtil.toDescriptiveString(personName, 2));
        
        var personAddress = {
        	address1: $j('input[name=addresses[0].address1]').attr('value'),
        	address2: $j('input[name=addresses[0].address2]').attr('value'),
        	neighborhoodCell: $j('input[name=addresses[0].neighborhoodCell]').attr('value'),
        	cityVillage: $j('input[name=addresses[0].cityVillage]').attr('value'),
        	townshipDivision: $j('input[name=addresses[0].townshipDivision]').attr('value'),
        	countyDistrict: $j('input[name=addresses[0].countyDistrict]').attr('value'),
        	stateProvince: $j('input[name=addresses[0].stateProvince]').attr('value'),
        	region: $j('input[name=addresses[0].region]').attr('value'),
        	subregion: $j('input[name=addresses[0].subregion]').attr('value'),
        	country: $j('input[name=addresses[0].country]').attr('value'),
        	postalCode: $j('input[name=addresses[0].postalCode]').attr('value')
        }
        // alert(DWRUtil.toDescriptiveString(personAddress, 2));
        
        var patientIdentifier = {
        	identifier: $j('input[name=identifiers[0].identifier]').attr('value'),
        	identifierType: $j('input[name=identifiers[0].identifierType]').attr('value')
        }
        // alert(DWRUtil.toDescriptiveString(patientIdentifier, 2));
        
        
        if (attributes == null) {
        	prepareAttributes();
        }
        
        for(i=0; i<attributes.length; i++) {
            if (attributes[i].value == null || attributes[i].value == "")
                continue;
        	else
                attributes[i].value = DWRUtil.getValue(attributes[i].attributeType.personAttributeTypeId).toString();
        }
        // alert("Attributes: " + DWRUtil.toDescriptiveString(attributes, 2));
        
        var birthStr = $j('input:text[name=birthdateInput]').attr('value');
        var birthdate = null;
        if (typeof(birthStr) != 'undefined' && birthStr.length > 0)
        	birthdate = new Date(Date.parse(birthStr));
        else {
        	birthStr = $j('input:text[name=birthdate]').attr('value');
        	if (typeof(birthStr) != 'undefined' && birthStr.length > 0)
        		birthdate = new Date(Date.parse(birthStr));
        }
        
        var gender = $j('input:radio[name=gender]:checked').attr('value');
        if (!gender)
        	gender = null;
        	
        var ageStr = $j('input:text[name=ageInput]').attr('value');
        var age = null;
        if (typeof(ageStr) != 'undefined' && ageStr.length > 0) {
        	age = ageStr;
        } else if (birthdate != null)
        	age = getAge(birthdate);
        else
        	age = null;
        
        DWRAmrsRegistrationService.getPatients(personName, personAddress, patientIdentifier, attributes, gender, birthdate, age, handlePatientResult);
    }
    
    function prepareAttributes() {
    	attributes = new Array();
        
        <openmrs:forEachDisplayAttributeType personType="" displayType="listing" var="attrType">
        	type = new Object();
        	type.personAttributeTypeId = "${attrType.personAttributeTypeId}";
        	type.name = "${attrType.name}";
        	type.format = "${attrType.format}";
        	
        	attr = new Object();
        	attr.attributeType = type;
        	attributes[${varStatus.index}] = attr;
		</openmrs:forEachDisplayAttributeType>
    }

    function clearAgeOrDOB(inputField) {
        var dob = document.getElementById("birthdateInput");
        var dobMsg = document.getElementById("birthdateTitle");
        var age = document.getElementById("ageInput");
        var ageMsg = document.getElementById("ageTitle");
        var orMsg = document.getElementById("orTitle");
        orMsg.style.color = "#CCCCCC";
        if (inputField.id == "birthdateInput") {
            dob.style.backgroundColor="white";
            dobMsg.style.color="black";
            age.style.backgroundColor="#D3D3D3"
            ageMsg.style.color="#CCCCCC"
            age.value="";
        }
        else if (inputField.id == "ageInput") {
            age.style.backgroundColor="white";
            ageMsg.style.color="black";
            dob.style.backgroundColor="#D3D3D3";
            dobMsg.style.color="#CCCCCC";
            dob.value="";
        }
    }

    function changeNameHeaderHack() {
        var headers = document.getElementsByTagName("th");
        for (var i=0; i<headers.length; i++) {
            if (headers[i].innerHTML == "Given") {
                headers[i].innerHTML = "First Name";
            } else if (headers[i].innerHTML == "Middle") {
                headers[i].innerHTML = "Middle Name";
            }
        }
    }


</script>

<style>
	.header {
		border-top:1px solid lightgray;
		vertical-align: top;
		text-align: left;
	}
	
	.input{
		border-top:1px solid lightgray;
	}
	
	.footer {
		border-bottom:1px solid lightgray;
	}
	
	.spacing {
		padding-right: 2em;
	}
	
	#centeredContent {
	}
	
	.resultTableExtended {
		display: none;
	}
	
</style>

<div>
	<h2><spring:message code="amrsregistration.edit.start"/></h2>
</div>

<div id="mask"></div>
<div id="amrsContent">
	<span><spring:message code="amrsregistration.page.edit.title"></spring:message></span>
	<form id="patientForm" method="post" onSubmit="removeTemplate()" autocomplete="off">
	<div id="boxes"> 
		<div id="dialog" class="window">
			<div id="personContent"></div>
		</div>
	</div>
	<br /><br />
			
	<div id="floating" style="display: block;">
	    <table class="box" style="width: 80%; padding: 0px">
	    	<tr>
	    		<td>Patient Search</td>
	    		<td colspan="4">&nbsp;</td>
	    	</tr>
			<c:choose>
				<c:when test="${fn:length(potentialMatches) > 0}">
			        <tr class="filler" style="display: none">
			        	<td colspan="8"><span id="searchMessage">No patients found.</span></td>
			        </tr>
			        <tr class="filler" style="display: none">
			        	<td colspan="8">&nbsp;</td>
			        </tr>
			        <tr class="filler" style="display: none">
			        	<td colspan="8">&nbsp;</td>
			        </tr>
				</c:when>
				<c:otherwise>
			        <tr class="filler" style="display: block">
			        	<td colspan="8"><span id="searchMessage">No patients found.</span></td>
			        </tr>
			        <tr class="filler" style="display: block">
			        	<td colspan="8">&nbsp;</td>
			        </tr>
			        <tr class="filler" style="display: block">
			        	<td colspan="8">&nbsp;</td>
			        </tr>
				</c:otherwise>
			</c:choose>
		</table>
        <table id="tableSorter" class="box" style="width: 80%; padding: 0px; border-top:0px;">
			<thead>
        	<tr id="resultTableHeader" style="display: none;">
	        	<th><spring:message code="amrsregistration.labels.ID" /></th>
	        	<th><spring:message code="amrsregistration.labels.givenNameLabel" /></th>
	        	<th><spring:message code="amrsregistration.labels.middleNameLabel" /></th>
	        	<th><spring:message code="amrsregistration.labels.familyNameLabel" /></th>
	        	<th><spring:message code="amrsregistration.labels.age" /></th>
	        	<th style="text-align: center;"><spring:message code="amrsregistration.labels.gender" /></th>
	        	<th>&nbsp;</th>
	        	<th><spring:message code="amrsregistration.labels.birthdate" /></th>
	        </tr>
	        </thead>
	        <tbody id="resultTable">
				<c:choose>
					<c:when test="${fn:length(potentialMatches) > 0}">
			    		<c:forEach items="${potentialMatches}" var="patient" varStatus="varStatus" end="${maxReturned}">
			    			<c:choose>
			    				<c:when test="${varStatus.index % 2 == 0}">
					    			<c:choose>
					    				<c:when test="${varStatus.index > 3}">
					    					<tr class="evenRow resultTableExtended">
					    				</c:when>
					    				<c:otherwise>
					    					<tr class="evenRow">
					    				</c:otherwise>
					    			</c:choose>
			    				</c:when>
			    				<c:otherwise>
					    			<c:choose>
					    				<c:when test="${varStatus.index > 3}">
					    					<tr class="oddRow resultTableExtended">
					    				</c:when>
					    				<c:otherwise>
					    					<tr class="oddRow">
					    				</c:otherwise>
					    			</c:choose>
			    				</c:otherwise>
			    			</c:choose>
			    				<c:forEach items="${patient.identifiers}" var="identifier" varStatus="varStatus">
			    					<c:if test="${varStatus.index == 0}">
					    				<td class="match">
					    					<c:out value="${identifier.identifier}" />
					    				</td>
			        				</c:if>
			    				</c:forEach>
			    				<td class="match">
			    					<c:out value="${patient.personName.givenName}" />
			    				</td>
			    				<td class="match">
			    					<c:out value="${patient.personName.middleName}" />
			    				</td>
			    				<td class="match">
			    					<c:out value="${patient.personName.familyName}" />
			    				</td>
			    				<td class="match">
			    					<c:out value="${patient.age}" />
			    				</td>
			    				<td class="match" style="text-align: center;">
									<c:if test="${patient.gender == 'M'}"><img src="${pageContext.request.contextPath}/images/male.gif" alt='<spring:message code="Person.gender.male"/>' /></c:if>
									<c:if test="${patient.gender == 'F'}"><img src="${pageContext.request.contextPath}/images/female.gif" alt='<spring:message code="Person.gender.female"/>' /></c:if>
			    				</td>
			    				<td class="match">
			    					<c:if test="${patient.birthdateEstimated}">~</c:if>
			    				</td>
			    				<td class="match">
			    					<openmrs:formatDate date="${patient.birthdate}" />
			    				</td>
			    				<input type="hidden" name="hiddenId${varStatus.index}" value="${patient.patientId}" />
			    			</tr>
			    		</c:forEach>
					</c:when>
				</c:choose>
	        </tbody>
	    </table>
        <c:choose>
            <c:when test="${fn:length(potentialMatches) > 3}">
                <table id="extendedToggle" class="box" style="width: 80%; padding: 0px; border-top:0px; display: block;">
					<c:choose>
						<c:when test="${fn:length(potentialMatches) > maxReturned}">
					    	<tr id="moreMatches" style="display: block">
					    		<td class="toggle">
			    					<spring:message code="amrsregistration.page.edit.moreMatches" arguments="${maxReturned}"></spring:message>
								</td>
							</tr>
						</c:when>
						<c:otherwise>
					    	<tr id="moreMatches" style="display: none">
					    		<td class="toggle">
			    					<spring:message code="amrsregistration.page.edit.moreMatches" arguments="${maxReturned}"></spring:message>
								</td>
							</tr>
						</c:otherwise>
					</c:choose>
			    	<tr>
			    		<td class="toggle">
							<a href="#" name="extendedToggle">more >></a>
						</td>
					</tr>
			    </table>
            </c:when>
            <c:otherwise>
                <table id="extendedToggle" class="box" style="width: 80%; padding: 0px; border-top:0px; display: none;">
			    	<tr id="moreMatches" style="display: none">
			    		<td class="toggle">
			    			<spring:message code="amrsregistration.page.edit.moreMatches" arguments="${maxReturned}"></spring:message>
						</td>
					</tr>
			    	<tr>
			    		<td class="toggle">
							<a href="#" name="extendedToggle">more >></a>
						</td>
					</tr>
			    </table>
            </c:otherwise>
        </c:choose>
	</div>
	<br />

	<spring:hasBindErrors name="patient">
		<c:forEach items="${errors.allErrors}" var="error">
			<br />
			<span class="error"><spring:message code="${error.code}"/></span>
		</c:forEach>
	</spring:hasBindErrors>
	
	<table id="centeredContent">
		<tr>
			<th class="header">Names</th>
			<td class="input">

<!-- Patient Names Section -->
		<table id="namePositionParent">
			<tr>
				<thead>
					<openmrs:portlet url="nameLayout" id="namePortlet" size="columnHeaders" parameters="layoutShowTable=false|layoutShowExtended=false" />
				<td>
					<c:choose>
						<c:when test="${fn:length(patient.names) > 1}">
				   			<span id="namePreferredLabel" style="display: block"><spring:message code="general.preferred"/></span>
						</c:when>
						<c:otherwise>
				    		<span id="namePreferredLabel" style="display: none"><spring:message code="general.preferred"/></span>
						</c:otherwise>
					</c:choose>
				</td>
				</thead>
			</tr>
	        <c:forEach var="name" items="${patient.names}" varStatus="varStatus">
	            <spring:nestedPath path="patient.names[${varStatus.index}]">
					<openmrs:portlet url="nameLayout" id="namePortlet${varStatus.index}" size="inOneRow" parameters="layoutMode=edit|layoutShowTable=false|layoutShowExtended=false" />
	            </spring:nestedPath>
	            <script type="text/javascript">
	            	$j(document).ready(function () {
	            		var hidden = ${fn:length(patient.names) <= 1};
						var preferred = ${name.preferred};
	            		var position = ${varStatus.index};
	            		var tbody = $j('#namePositionParent').find('tbody:eq(1)');
	            		var nameContentX = $j(tbody).find('tr:eq(' + position + ')');
	            		$j(nameContentX).attr('id', 'nameContent' + position);
	            		createPreferred(preferred, 'name', position, nameContentX, hidden);
	            		
	            		// bind onkeyup for each of the address layout text field
	            		var allTextInputs = $j('#nameContent' + position + ' input[type=text]');
	            		$j(allTextInputs).bind('keyup', function(event){
	            			timeOutSearch(event);
	            		});
	            	});
	            </script>
	        </c:forEach>
	    	<tbody id="namePosition">
		</table>
		<div id="nameContent" style="display: none;">
			<spring:nestedPath path="emptyName">
				<table>
					<openmrs:portlet url="nameLayout" id="namePortlet" size="inOneRow" parameters="layoutMode=edit|layoutShowTable=false|layoutShowExtended=false" />
				</table>
			</spring:nestedPath>
		</div>
		<div class="tabBar" id="nameTabBar">
			<span id="nameError" class="newError"></span>
			<input type="button" onClick="return deleteLastRow('name');" class="addNew" id="name" value="Remove"/>
			<input type="button" onClick="return addNew('name');" class="addNew" id="name" value="Add New Name"/>
		</div>
<!-- End of Patient Names Section -->
	
			</td>
		</tr>
		<tr>
			<th class="header">Demographics</th>
			<td class="input">
    
<!-- Gender and Birthdate Section -->
    	<table>
    		<tr>
				<td><spring:message code="Person.gender"/></td>
				<td id="birthdateTitle">
					<spring:message code="Person.birthdate"/>
					<i style="font-weight: normal; font-size: .8em;">(<spring:message code="general.format"/>: <openmrs:datePattern />)</i>
				</td>
    		</tr>
			<spring:nestedPath path="patient">
				<tr>
				<c:if test="${empty INCLUDE_PERSON_GENDER || (INCLUDE_PERSON_GENDER == 'true')}">
						<td style="padding-right: 3.6em;">
							<spring:bind path="patient.gender">
								<openmrs:forEachRecord name="gender">
									<input type="radio" name="gender" id="${record.key}" value="${record.key}" <c:if test="${record.key == status.value}">checked</c:if> onclick="clickTimeOutSearch()" />
										<label for="${record.key}"> <spring:message code="Person.gender.${record.value}"/> </label>
								</openmrs:forEachRecord>
							</spring:bind>
						</td>
				</c:if>
				<c:choose>
					<c:when test="${patient.birthdate == null}">
							<td style="padding-right: 4em;">
								<input type="text" name="birthdateInput" id="birthdateInput" size="11" value=""  onclick="showCalendar(this)" onkeyup="timeOutSearch(event)" onchange="clearAgeOrDOB(this)"/>
								<span id="orTitle"><spring:message code="general.or"/></span>
								<span id="ageTitle"><spring:message code="Person.age"/></span>
								<input type="text" name="ageInput" id="ageInput" size="5" value="" onkeyup="timeOutSearch(event)" onchange="clearAgeOrDOB(this)"/>
							</td>
					</c:when>
					<c:otherwise>
							<td style="padding-right: 4em;">
								<script type="text/javascript">
									function updateEstimated(txtbox) {
										var input = document.getElementById("birthdateEstimatedInput");
										if (input) {
											input.checked = false;
											input.parentNode.className = "";
										}
										else if (txtbox)
											txtbox.parentNode.className = "listItemChecked";
									}
									
									function updateAge() {
										var birthdateBox = document.getElementById('birthdateInput');
										var ageBox = document.getElementById('ageInput');
										try {
											var birthdate = parseSimpleDate(birthdateBox.value, '<openmrs:datePattern />');
											var age = getAge(birthdate);
											if (age > 0)
												ageBox.innerHTML = "(" + age + ' <spring:message code="Person.age.years"/>)';
											else if (age == 1)
												ageBox.innerHTML = '(1 <spring:message code="Person.age.year"/>)';
											else if (age == 0)
												ageBox.innerHTML = '( < 1 <spring:message code="Person.age.year"/>)';
											else
												ageBox.innerHTML = '( ? )';
											ageBox.style.display = "";
										} catch (err) {
											ageBox.innerHTML = "";
											ageBox.style.display = "none";
										}
									}
								</script>
								<spring:bind path="patient.birthdate">			
									<input type="text" 
											name="${status.expression}" size="10" id="birthdate"
											value="${status.value}"
											readonly="readonly"
											onchange="updateAge(); updateEstimated(this);"
											onclick="showCalendar(this)" onkeyup="timeOutSearch(event)" />
								</spring:bind>
								
								<span id="age"></span> &nbsp; 
								
								<span id="birthdateEstimatedCheckbox" class="listItemChecked" style="padding: 5px;">
									<spring:bind path="patient.birthdateEstimated">
										<label for="birthdateEstimatedInput"><spring:message code="Person.birthdateEstimated"/></label>
										<input type="hidden" name="_${status.expression}">
										<input type="checkbox" name="${status.expression}" value="true" 
											   <c:if test="${status.value == true}">checked</c:if> 
											   id="birthdateEstimatedInput" 
											   onclick="if (!this.checked) updateEstimated()" />
									</spring:bind>
								</span>
								
								<script type="text/javascript">
									if (document.getElementById("birthdateEstimatedInput").checked == false)
										updateEstimated();
									updateAge();
								</script>
							</td>
					</c:otherwise>
				</c:choose>
				</tr>
			</spring:nestedPath>
		</table>
<!-- End of Gender and Birthdate Section -->
	
			</td>
		</tr>
		<tr>
			<th class="header">Identifiers</th>
			<td class="input">

<!-- Patient Identifier Section -->
		<table id="identifierPositionParent">
			<tr>
			    <td>
			        <spring:message code="amrsregistration.labels.ID"/>
			    </td>
			    <td>
			        <spring:message code="PatientIdentifier.identifierType"/>
			    </td>
				<td>
					<spring:message code="PatientIdentifier.location"/>
				</td>
				<td>
					<c:choose>
						<c:when test="${fn:length(patient.identifiers) > 1}">
				    		<span id="identifierPreferredLabel" style="display: block"><spring:message code="general.preferred"/></span>
						</c:when>
						<c:otherwise>
				    		<span id="identifierPreferredLabel" style="display: none"><spring:message code="general.preferred"/></span>
						</c:otherwise>
					</c:choose>
				</td>
			</tr>
	        <c:forEach var="identifier" items="${patient.identifiers}" varStatus="varStatus">
	            <spring:nestedPath path="patient.identifiers[${varStatus.index}]">
	            	<c:if test="${amrsIdType != identifier.identifierType.name}">
	            		<%@ include file="portlets/patientIdentifier.jsp" %>
						<script type="text/javascript">
							var hidden = ${fn:length(patient.identifiers) <= 1};
							var preferred = ${identifier.preferred};
							var container = $j('#identifierContent${varStatus.index}');
							createPreferred(preferred, 'identifier', ${varStatus.index}, container, hidden);
			            </script>
	            	</c:if>
	            </spring:nestedPath>
	        </c:forEach>
	    	<tbody id="identifierPosition">
      	</table>
        <spring:nestedPath path="emptyIdentifier">
			<table style="display: none;">
            	<%@ include file="portlets/patientIdentifier.jsp" %>
            </table>
        </spring:nestedPath>
        <div class="tabBar" id="identifierTabBar">
			<span id="identifierError" class="newError"></span>
            <input type="button" onClick="return deleteLastRow('identifier');" class="addNew" id="identifier" value="Remove"/>
            <input type="button" onClick="return addNew('identifier');" class="addNew" id="identifier" value="Add New Identifier"/>
        </div>
<!-- End of Patient Identifier Section -->
	
			</td>
		</tr>
		<tr>
			<th class="header">Addresses</th>
			<td class="input">

<!-- Patient Address Section -->
		<table>
			<c:forEach var="address" items="${patient.addresses}" varStatus="varStatus">
				<tr><td>
			    <spring:nestedPath path="patient.addresses[${varStatus.index}]">
			    	<openmrs:portlet url="addressLayout" id="addressPortlet${varStatus.index}" size="full" parameters="layoutShowTable=true|layoutShowExtended=false" />
			    </spring:nestedPath>
				</td></tr>
	            <script type="text/javascript">
	            	$j(document).ready(function () {
		            	var hidden = ${fn:length(patient.addresses) <= 1};
						var preferred = ${address.preferred};
	            		var position = ${varStatus.index};
	            		var nameContentX = $j('#addressPortlet' + position).find('table');
	            		$j(nameContentX).attr('id', 'addressContent' + position);
	            		createPreferred(preferred, 'address', position, nameContentX, hidden);
	            		
	            		// bind all inputs
	            		var allTextInputs = $j('#addressContent' + position + ' input[type=text]');
	            		$j(allTextInputs).bind('keyup', function(event){
	            			timeOutSearch(event);
	            		});
	            	});
	            </script>
			</c:forEach>
	        <tbody id="addressPosition" />
		</table>
        <div id="addressPositionClear" style="clear:both"></div>
		<div id="addressContent" style="display: none;">
			<spring:nestedPath path="emptyAddress">
				<openmrs:portlet url="addressLayout" id="addressPortlet" size="full" parameters="layoutShowTable=true|layoutShowExtended=false" />
			</spring:nestedPath>
	    </div>
	    <div class="tabBar" id="addressTabBar">
			<span id="addressError" class="newError"></span>
	        <input type="button" onClick="return deleteLastRow('address');" class="addNew" id="address" value="Remove"/>
	        <input type="button" onClick="return addNew('address');" class="addNew" id="address" value="Add New Address"/>
	    </div>
<!-- End of Patient Address Section -->
	
			</td>
		</tr>
		<c:if test="${displayAttributes}">
		<tr>
			<th class="header footer">Attributes</th>
			<td class="input footer">
    
<!-- Patient Attributes Section -->
    	<table>
			<spring:nestedPath path="patient">
				<openmrs:forEachDisplayAttributeType personType="" displayType="listing" var="attrType">
					<tr>
						<td><spring:message code="PersonAttributeType.${fn:replace(attrType.name, ' ', '')}" text="${attrType.name}"/></td>
						<td>
							<spring:bind path="attributeMap">
								<openmrs:fieldGen 
									type="${attrType.format}" 
									formFieldName="${attrType.personAttributeTypeId}" 
									val="${status.value[attrType.name].hydratedObject}" 
									parameters="optionHeader=[blank]|showAnswers=${attrType.foreignKey}" />
							</spring:bind>
						</td>
					</tr>
				</openmrs:forEachDisplayAttributeType>
			</spring:nestedPath>
		</table>
<!-- End of Patient Attributes Section -->
	
			</td>
		</tr>
		</c:if>
	</table>
	<input type="hidden" name="_page1" value="true" />
	&nbsp;
	<input type="submit" name="_target2" value="<spring:message code='amrsregistration.button.continue'/>">
	&nbsp; &nbsp;
	<input type="submit" name="_cancel" value="<spring:message code='amrsregistration.button.startover'/>">
	<br/>
	<br/>
	</form>
</div>
<script type="text/javascript">
	// bind onkeyup for each of the address layout text field
	$j(document).ready(function() {
		var first = $j('#nameContent0 input[type=text]:eq(0)');
		first.focus();
	});

    changeNameHeaderHack();
</script>

<%@ include file="/WEB-INF/template/footer.jsp" %>
