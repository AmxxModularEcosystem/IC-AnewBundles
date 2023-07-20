#include <amxmodx>
#include <json>
#include <regex>
#include <VipM/ItemsController>

#define BUNDLE_NAME_MAX_LEN 32

new Trie:g_tBundles = Invalid_Trie;
new Array:g_aBundleNames = Invalid_Array;

public plugin_precache() {
    register_plugin("[IC] ANew Bundles", "1.0.0", "ArKaNeMaN");

    VipM_IC_Init();

    LoadBundles();

    // debug only
    // register_clcmd("IC_AnewBundles_Take", "@ClCmd_Take");

    // IC_AnewBundle_Give #<UserId>|<AuthId>|<UserName> <BundleName>
    register_srvcmd("IC_AnewBundle_Give", "@SrvCmd_Give");

    // IC_AnewBundle_GiveRandom #<UserId>|<AuthId>|<UserName>
    register_srvcmd("IC_AnewBundle_GiveRandom", "@SrvCmd_GiveRandom");
}

@ClCmd_Take(const UserId) {
    if (!is_user_alive(UserId)) {
        client_print(UserId, print_console, "Вы мертвы.");
        return PLUGIN_HANDLED;
    }

    new sBundleName[BUNDLE_NAME_MAX_LEN];
    read_argv(1, sBundleName, charsmax(sBundleName));

    GiveBundle(UserId, sBundleName);
    return PLUGIN_HANDLED;
}

@SrvCmd_Give() {
    new UserId = read_argv_player(1);
    if (!UserId || !is_user_alive(UserId)) {
        server_print("Selected player is dead.");
        return PLUGIN_HANDLED;
    }
    
    new sBundleName[BUNDLE_NAME_MAX_LEN];
    read_argv(2, sBundleName, charsmax(sBundleName));

    GiveBundle(UserId, sBundleName);
    return PLUGIN_HANDLED;
}

@SrvCmd_GiveRandom() {
    new UserId = read_argv_player(1);
    if (!UserId || !is_user_alive(UserId)) {
        server_print("Selected player is dead.");
        return PLUGIN_HANDLED;
    }

    GiveRandomBundle(UserId);
    return PLUGIN_HANDLED;
}

public GiveBundle(const UserId, const sBundleName[]) {
    new Array:aItems;
    if (TrieGetCell(g_tBundles, sBundleName, aItems)) {
        return VipM_IC_GiveItems(UserId, aItems);
    } else {
        log_amx("[WARNING] Bundle '%s' not found.", sBundleName);
        return false;
    }
}

public GiveRandomBundle(const UserId) {
    new sBundleName[BUNDLE_NAME_MAX_LEN];
    ArrayGetString(g_aBundleNames, random_num(0, ArraySize(g_aBundleNames)), sBundleName, charsmax(sBundleName));

    GiveBundle(UserId, sBundleName);
}

LoadBundles() {
    TrieDestroy(g_tBundles);
    ArrayDestroy(g_aBundleNames);
    g_tBundles = TrieCreate();
    g_aBundleNames = ArrayCreate(BUNDLE_NAME_MAX_LEN, 1);

    if (file_exists(GetConfigPath("Bundles.json"))) {
        LoadBundlesFromFile(GetConfigPath("Bundles.json"));
    } else {
        // log_amx("[DEBUG] File `%s` is not exists.", GetConfigPath("Bundles.json"));
    }

    if (dir_exists(GetConfigPath("Bundles/"))) {
        LoadBundlesFromDir(GetConfigPath("Bundles/"));
    } else {
        // log_amx("[DEBUG] Directory `%s` is not exists.", GetConfigPath("Bundles/"));
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
        ArrayPushString(g_aBundleNames, sBundleName);
        // log_amx("[DEBUG] Bundle `%s` loaded from file.", sBundleName);
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
        ArrayPushString(g_aBundleNames, sFile);
        // log_amx("[DEBUG] Bundle `%s` loaded from folder.", sFile);
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

read_argv_player(const iArgNum, const bStrictName = false) {
    new const STEAM_ID_PREFIX[] = "STEAM_";
    new const VALVE_ID_PREFIX[] = "VALVE_";

    static sArg[64];
    read_argv(iArgNum, sArg, charsmax(sArg));

    new iArgLen = strlen(sArg);

    if (sArg[0] == '#') {
        new i = str_to_num(sArg[1]);
        if (i >= 1 && i <= MAX_PLAYERS) {
            return i;
        } else {
            return 0;
        }
    } else if (
        equal(sArg, STEAM_ID_PREFIX, charsmax(STEAM_ID_PREFIX))
        || equal(sArg, VALVE_ID_PREFIX, charsmax(VALVE_ID_PREFIX))
    ) {
        for (new i = 1; i <= MAX_PLAYERS; ++i) {
            if (!is_user_connected(i)) {
                continue;
            }

            static sSteamId[MAX_AUTHID_LENGTH];
            get_user_authid(i, sSteamId, charsmax(sSteamId));

            if (equal(sSteamId, sArg)) {
                return i;
            }
        }
    } else {
        for (new i = 1; i <= MAX_PLAYERS; ++i) {
            if (!is_user_connected(i)) {
                continue;
            }

            static sName[MAX_NAME_LENGTH];
            get_user_name(i, sName, charsmax(sName));
            
            if (equal(sName, sArg, bStrictName ? 0 : iArgLen)) {
                return i;
            }
        }
    }

    return 0;
}
