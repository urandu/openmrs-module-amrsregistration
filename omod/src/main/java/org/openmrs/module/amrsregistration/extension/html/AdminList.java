package org.openmrs.module.amrsregistration.extension.html;

import java.util.HashMap;
import java.util.Map;
import org.openmrs.module.Extension;
import org.openmrs.module.web.extension.AdministrationSectionExt;

public class AdminList extends AdministrationSectionExt {
    public Extension.MEDIA_TYPE getMediaType() {
        return Extension.MEDIA_TYPE.html;
    }

    public String getTitle() {
        return "AMRS Registration Module";
    }

    public Map<String, String> getLinks() {
        Map<String, String> localHashMap = new HashMap<String, String>();
        localHashMap.put("module/amrsregistration/registration.form",
                "amrsregistration.start.title");
        return localHashMap;
    }
}
