#include <amxmodx>
#include <json>
#include <regex>
#include <VipM/ItemsController>

#define BUNDLE_NAME_MAX_LEN 32

new Trie:g_tBundles = Invalid_Trie;

public plugin_precache() {
    register_plugin("[IC] ANew Bundles", "1.0.0", "ArKaNeMaN");

    VipM_IC_Init();

    LoadBundles();
}

public GiveBundle(const UserId, const sBundleName[]) {
    new Array:aItems;
    if (TrieGetCell(g_tBundles, sBundleName, aItems)) {
        VipM_IC_GiveItems(UserId, aItems);
    } else {
        log_amx("[WARNING] Bundle '%s' not found.", sBundleName);
    }
}

LoadBundles() {
    TrieDestroy(g_tBundles);
    g_tBundles = TrieCreate();

    if (file_exists(GetConfigPath("Bundles.json"))) {
        LoadBundlesFromFile(GetConfigPath("Bundles.json"));
    }

    if (dir_exists(GetConfigPath("Bundles/"))) {
        LoadBundlesFromDir(GetConfigPath("Bundles/"));
    }

    log_amx("[INFO] Loaded %d bundles.", TrieGetSize(g_tBundles));
}

LoadBundlesFromFile(const sFilePath[]) {
    new JSON:jBundles = Json_GetFile(sFilePath);

    if (jBundles == Invalid_JSON) {
        return;
    }

    if (!json_is_object(jBundles)) {
        log_amx("[ERROR] File '%s' must contains JSON object.", sFilePath);
        return;
    }

    for (new i = 0, ii = json_object_get_count(jBundles); i < ii; ++i) {
        new sBundleName[BUNDLE_NAME_MAX_LEN];
        json_object_get_name(jBundles, i, sBundleName, charsmax(sBundleName));

        TrieSetCell(g_tBundles, sBundleName, VipM_IC_JsonGetItems(json_object_get_value_at(jBundles, i)));
    }
}

LoadBundlesFromDir(sDirPath[]) {
    new sFile[PLATFORM_MAX_PATH], iDirHandler, FileType:iType;
    iDirHandler = open_dir(sDirPath, sFile, charsmax(sFile), iType);
    if (!iDirHandler) {
        log_amx("[ERROR] Can't open folder '%s'.", sDirPath);
        return;
    }

    new Regex:iRegEx_FileName, ret;
    iRegEx_FileName = regex_compile("(.+).json$", ret, "", 0, "i");

    do {
        if (
            iType != FileType_File
            || regex_match_c(sFile, iRegEx_FileName) <= 0
        ) {
            continue;
        }

        regex_substr(iRegEx_FileName, 1, sFile, charsmax(sFile));

        TrieSetCell(g_tBundles, sFile, VipM_IC_JsonGetItems(Json_GetFile(fmt("%s%s.json", sDirPath, sFile))));
    } while (next_file(iDirHandler, sFile, charsmax(sFile), iType));

    regex_free(iRegEx_FileName);
    close_dir(iDirHandler);
}

JSON:Json_GetFile(const sPath[], const sDefaultContent[] = NULL_STRING) {
	if (!file_exists(sPath)) {
		if (!sDefaultContent[0]) {
			log_amx("[ERROR] File '%s' not found.", sPath);
			return Invalid_JSON;
		}

		write_file(sPath, sDefaultContent);
		log_amx("[INFO] File '%s' not found and was created with default content.", sPath);
	}

	new JSON:jFile = json_parse(sPath, true, true);

	if (jFile == Invalid_JSON) {
		log_amx("[ERROR] JSON syntax error in '%s'.", sPath);
		return Invalid_JSON;
	}

	return jFile;
}

GetConfigPath(const sPath[]) {
	static __amxx_configsdir[PLATFORM_MAX_PATH];
	if (!__amxx_configsdir[0]) {
		get_localinfo("amxx_configsdir", __amxx_configsdir, charsmax(__amxx_configsdir));
	}
	
	new sOut[PLATFORM_MAX_PATH];
	formatex(sOut, charsmax(sOut), "%s/plugins/ItemsController/AnewBundles/%s", __amxx_configsdir, sPath);

	return sOut;
}
