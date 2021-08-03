#![feature(fn_traits)]
#![recursion_limit = "256"]

#[macro_use]
extern crate druid;
#[macro_use]
extern crate log;
extern crate simplelog;

use druid::commands::QUIT_APP;

use druid::{AppLauncher, Color, LocalizedString, Menu, MenuItem, SysMods, WindowDesc};
use log::LevelFilter;
use simple_logger::SimpleLogger;

use crate::data::collections::CollectionsState;
use crate::data::deferred::Deferred;
use crate::data::navigation::NavRoute;
use crate::data::selection::{SelectableItem, SelectedState};
use crate::data::{AppState, OrdSet};
use crate::ui::build_root_widget;
use crate::ui::controllers::{load_collections, AggregateAppDelegate, CollectionsLoader, OnLaunch};

mod api;
mod data;
mod ui;

const HORIZONTAL_WIDGET_SPACING: f64 = 20.0;
const VERTICAL_WIDGET_SPACING: f64 = 20.0;
const TEXT_BOX_WIDTH: f64 = 200.0;
const WINDOW_TITLE: LocalizedString<AppState> = LocalizedString::new("Melo Control");

fn main() {
    SimpleLogger::new()
        .with_level(LevelFilter::Debug)
        .init()
        .unwrap();

    let main_window = WindowDesc::new(build_root_widget())
        .title(WINDOW_TITLE)
        .window_size((800.0, 600.0))
        .with_min_size((600.0, 400.0))
        .menu(|_id, _t, _env| {
            let file_menu = Menu::new("File").entry(
                MenuItem::new("Exit")
                    .command(QUIT_APP)
                    .hotkey(SysMods::Cmd, "q"),
            );
            Menu::new(WINDOW_TITLE).entry(file_menu)
        });

    let mut routes = OrdSet::new();
    routes.insert(SelectableItem::Selectable(
        NavRoute::Home,
        SelectedState::Selected,
    ));
    routes.insert(SelectableItem::Selectable(
        NavRoute::RecentlyAdded,
        SelectedState::Unselected,
    ));
    routes.insert(SelectableItem::Selectable(
        NavRoute::Settings,
        SelectedState::Unselected,
    ));

    let initial_state = AppState {
        routes,
        current_route: NavRoute::Home,
        collections_state: CollectionsState::new(),
    };

    AppLauncher::with_window(main_window)
        .delegate(AggregateAppDelegate::new(vec![
            Box::new(OnLaunch::new(move |ctx, data: &mut AppState, env| {
                data.collections_state.collection_descriptors = Deferred::Loading;
                load_collections(ctx.get_external_handle(), &env)
            })),
            Box::new(CollectionsLoader),
        ]))
        .configure_env(|env, _| {
            env.set(api::MELO_API_URL, "http://localhost:5000/api");

            env.set(ui::theme::MENU_ITEM_FG_ACTIVE, Color::grey8(0xff));
            env.set(ui::theme::MENU_ITEM_FG_INACTIVE, Color::grey8(0xf2));
            env.set(ui::theme::MENU_ITEM_BG_ACTIVE, Color::grey8(0x4f));
            env.set(ui::theme::MENU_ITEM_BG_INACTIVE, Color::grey8(0x33));
        })
        // .log_to_console()
        .launch(initial_state)
        .expect("Failed to launch application");
}
