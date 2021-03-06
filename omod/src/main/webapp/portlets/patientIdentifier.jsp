    <tr id="identifierContent${varStatus.index}" <c:if test='${varStatus.index == 0 && (identifier.identifier == null || identifier.identifier == "")}'>style="display: none;"</c:if> >
        <td class="spacing" style="white-space: nowrap">
            <spring:bind path="identifier">
                <c:if test="${identifier.dateCreated != null}">
                    ${status.value}
                </c:if>
                <input type="<c:choose><c:when test='${identifier.dateCreated != null}'>hidden</c:when><c:otherwise>text</c:otherwise></c:choose>" id="${status.expression}" name="${status.expression}" value="${status.value}" onkeyup="timeOutSearch(event)"/>
            </spring:bind>
        </td>
        <td class="spacing" style="white-space: nowrap">
            <spring:bind path="identifierType">
                <c:choose>
                    <c:when test="${identifier.dateCreated != null}">
                        <openmrs:forEachRecord name="patientIdentifierType">
                            <c:if test="${record.patientIdentifierTypeId == status.value}">
                                ${record.name}
                                <input type="hidden" id="patient.identifiers[${varStatus.index}].identifierType" name="identifierType" value="${status.value}" />
                            </c:if>
                        </openmrs:forEachRecord>
                    </c:when>
                    <c:otherwise>
                        <select id="${status.expression}" name="${status.expression}">
                            <option value=""></option>
                            <openmrs:forEachRecord name="patientIdentifierType">
                            	<c:if test="${amrsIdType != record.name}">
                                    <option value="${record.patientIdentifierTypeId}"
                                    <c:if test="${record.patientIdentifierTypeId == status.value}">selected</c:if> >
                                        ${record.name}
                                    </option>
                                </c:if>
                            </openmrs:forEachRecord>
                        </select>
                    </c:otherwise>
                </c:choose>
            </spring:bind>
        </td>
		<td class="spacing" style="white-space: nowrap">
			<spring:bind path="location">
                <c:choose>
                    <c:when test="${identifier.dateCreated != null}">
                        <openmrs:forEachRecord name="location">
                            <c:if test="${record.locationId == status.value}">
                                ${record.name}
                                    <input type="hidden" id="patient.identifiers[${varStatus.index}].location" name="patient.identifiers[${varStatus.index}].location" value="${status.value}" />
                            </c:if>
                        </openmrs:forEachRecord>
                    </c:when>
                    <c:otherwise>
                        <select id="${status.expression}" name="${status.expression}">
                            <option value=""></option>
                            <openmrs:forEachRecord name="location">
                                <option value="${record.locationId}" <c:if test="${record.locationId == status.value}">selected</c:if>>
                                    ${record.name}
                                </option>
                            </openmrs:forEachRecord>
                        </select>
                        <c:if test="${status.errorMessage != ''}"><span class="error">${status.errorMessage}</span></c:if>
                    </c:otherwise>
                </c:choose>
			</spring:bind>
		</td>
        <td name="addedIdentifierData" <c:choose><c:when test="${identifier.dateCreated != null}">style="display: '';"</c:when><c:otherwise>style="display: none;"</c:otherwise></c:choose>>
            <spring:bind path="preferred">
                <input type="radio" id="identifierPreferred${varStatus.index}" name="identifierPreferred" value="${status.value}" <c:if test='${status.value == "true"}'>checked</c:if>">
            </spring:bind>
        </td>
        <td onclick="removeRow(this.parentNode, 'identifier')" id="rm_identifierContent" name="addedIdentifierData" <c:choose><c:when test="${identifier.dateCreated != null}">style="display: '';"</c:when><c:otherwise>style="display: none;"</c:otherwise></c:choose>>
            <a href="#delete"  style="color:red;">X</a>
        </td>
        <td id="addNewIdentifierData" <c:if test='${identifier.dateCreated != null}'>style="display: none;"</c:if> >
            <input type="button" onClick="return addNew('identifier');" class="addNew" id="identifier" value="Add New Identifier"/>
        </td>
	</tr>
