pub use druid::theme::*;
use druid::{Color, Key};

pub const MENU_ITEM_BG: Key<Color> = Key::new("app.menu-bg");
pub const MENU_ITEM_BG_ACTIVE: Key<Color> = Key::new("app.menu-bg-active");
pub const MENU_ITEM_BG_INACTIVE: Key<Color> = Key::new("app.menu-bg-inactive");
pub const MENU_ITEM_BG_DISABLED: Key<Color> = Key::new("app.menu-bg-disabled");
pub const MENU_ITEM_FG: Key<Color> = Key::new("app.menu-fg");
pub const MENU_ITEM_FG_ACTIVE: Key<Color> = Key::new("app.menu-fg-active");
pub const MENU_ITEM_FG_INACTIVE: Key<Color> = Key::new("app.menu-fg-inactive");
pub const MENU_ITEM_FG_DISABLED: Key<Color> = Key::new("app.menu-fg-disabled");
