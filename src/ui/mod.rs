use druid::widget::Split;
use druid::{Widget, WidgetExt};

use crate::data::AppState;

use crate::ui::navigation::{navigation_menu_widget, Navigator};

pub mod collection;
pub mod controllers;
pub mod main_panel;
pub mod metadata_editor;
pub mod navigation;
pub mod theme;
pub mod transform;
pub mod widgets;

pub fn build_root_widget() -> impl Widget<AppState> {
    let sidebar = navigation_menu_widget().fix_width(150.0).expand_height();
    Split::columns(sidebar, main_panel::main_panel())
        .solid_bar(true)
        .bar_size(4.)
        .draggable(true)
        .min_size(150.0, 0.0)
        .split_point(0.3)
        .expand()
        .background(theme::BACKGROUND_DARK)
        .controller(Navigator)
}
