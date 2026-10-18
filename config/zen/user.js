// Zen — managed by dotfiles (config/zen/user.js). install.sh writes this plus
// the private start page URL into the profile's user.js; applied on every launch.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Start on the start page (STARTPAGE_URL appended from private/homelab.env)
user_pref("browser.startup.page", 1);

// Dark everywhere
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("browser.theme.content-theme", 0);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("zen.theme.accent-color", "#8C9F82");
