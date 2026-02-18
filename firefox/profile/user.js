user_pref("privacy.exposeContentTitleInWindow", false);
user_pref("privacy.exposeContentTitleInWindow.pbm", false);

// Limit the number of web content processes. Each content process carries
// significant baseline memory overhead. Tabs beyond this count share processes.
// Default: 8
user_pref("dom.ipc.processCount", 4);

// Allow Firefox to automatically unload inactive tabs when the system is
// under memory pressure, freeing their memory until the tab is revisited.
// Default: true (but may be overridden by platform; explicit here for safety)
user_pref("browser.tabs.unloadOnLowMemory", true);

