use std::str::FromStr;
use std::thread;

use druid::widget::{Controller, Label, List, ListIter};
use druid::{
    im, Env, Event, EventCtx, ExtEventSink, Insets, Selector, SingleUse, Target, Widget, WidgetExt,
};
use gurkle::HttpClient;
use itertools::Itertools;
use reqwest::Url;

use crate::api::{GetCollectionRequest, MELO_API_URL};
use crate::data::collections::{Collection, CollectionDescriptor};
use crate::data::deferred::Deferred;
use crate::data::navigation::NavRoute;
use crate::data::selection::{SelectableItem, SelectedState};
use crate::data::AppState;

use crate::ui::theme;

pub fn navigation_menu_widget() -> impl Widget<AppState> {
    return List::new(|| {
        Label::dynamic(|data: &SelectableItem<NavRoute>, _env| data.inner().title())
            .with_text_color(theme::MENU_ITEM_FG)
            .fix_height(20.)
            .expand_width()
            .padding(Insets::uniform(4.))
            .on_click(|ctx, data, _env| {
                trace!("Nav item clicked: {:?}", data.inner().title());
                data.select();
                ctx.submit_command(NAVIGATE.with(data.inner().clone()));
            })
            .background(theme::MENU_ITEM_BG)
            .env_scope(|env, data: &SelectableItem<NavRoute>| {
                trace!("Updating scoped env for '{}'", &data.inner().title());
                match &data {
                    SelectableItem::Selectable(_, state) => match &state {
                        SelectedState::Selected => {
                            trace!("Selected {}", data.inner().title());
                            env.set(theme::MENU_ITEM_BG, env.get(theme::MENU_ITEM_BG_ACTIVE));
                            trace!("MENU_ITEM_BG: {:?}", env.get(theme::MENU_ITEM_BG_ACTIVE));
                            env.set(theme::MENU_ITEM_FG, env.get(theme::MENU_ITEM_FG_ACTIVE));
                            trace!("MENU_ITEM_FG: {:?}", env.get(theme::MENU_ITEM_FG_ACTIVE));
                        }
                        SelectedState::Unselected => {
                            trace!("Unselected {}", data.inner().title());
                            env.set(theme::MENU_ITEM_BG, env.get(theme::MENU_ITEM_BG_INACTIVE));
                            trace!("MENU_ITEM_BG: {:?}", env.get(theme::MENU_ITEM_BG_INACTIVE));
                            env.set(theme::MENU_ITEM_FG, env.get(theme::MENU_ITEM_FG_INACTIVE));
                            trace!("MENU_ITEM_FG: {:?}", env.get(theme::MENU_ITEM_FG_INACTIVE));
                        }
                    },
                    SelectableItem::Disabled(_) => {
                        env.set(theme::MENU_ITEM_BG, env.get(theme::MENU_ITEM_BG_DISABLED));
                        env.set(theme::MENU_ITEM_FG, env.get(theme::MENU_ITEM_FG_DISABLED));
                    }
                    SelectableItem::Subheading(_) => {
                        env.set(theme::MENU_ITEM_BG, env.get(theme::MENU_ITEM_BG_INACTIVE));
                        env.set(theme::MENU_ITEM_FG, env.get(theme::MENU_ITEM_FG_INACTIVE));
                    }
                }
            })
    })
    .lens(AppState::routes)
    // .controller(Navigator)
    ;

    // Flex::column()
    //     .with_default_spacer()
    //     .with_child(Label::new("Collections")
    //         .with_text_color(theme::MENU_ITEM_FG_INACTIVE)
    //         .align_left().padding(5.0)
    //     )
    //     .with_child(new_collections_list())
    //     .background(theme::MENU_ITEM_BG_INACTIVE)
    //     .expand_height()
}

pub const NAVIGATE: Selector<NavRoute> = Selector::new("melo.navigate");

pub struct Navigator;

impl<W: Widget<AppState>> Controller<AppState, W> for Navigator {
    fn event(
        &mut self,
        child: &mut W,
        ctx: &mut EventCtx,
        event: &Event,
        data: &mut AppState,
        env: &Env,
    ) {
        if let Event::Command(cmd) = event {
            if let Some(selected_route) = cmd.get(NAVIGATE) {
                debug!("Navigating to route {:?}", &selected_route);
                data.current_route = selected_route.clone();
                trace!("routes: {:?}", &data.routes);
                data.routes.for_each_mut(|route, _| {
                    if route.inner() != selected_route {
                        route.unselect();
                        trace!("unselected route: {:?}", &route);
                    }
                });
                trace!("routes after deselection: {:?}", &data.routes.0);
                if let NavRoute::Collection(collection) = selected_route {
                    match data.collections_state.collections.get(collection) {
                        Some(Deferred::Loaded(Some(_))) => {}
                        _ => {
                            data.collections_state
                                .collections
                                .insert(collection.clone(), Deferred::Loading);
                            load_collection(ctx.get_external_handle(), &env, collection.clone());
                            // ctx.request_update();
                            // ctx.request_paint();
                            // ctx.request_layout();
                            // ctx.children_changed();
                        }
                    }
                }
            }
        }
        child.event(ctx, event, data, env)
    }
}

pub const LOADING_COLLECTION: Selector<String> = Selector::new("melo.loading_collection");

pub const LOADED_COLLECTION: Selector<SingleUse<(CollectionDescriptor, Option<Collection>)>> =
    Selector::new("melo.loaded_collection");

pub fn load_collection(sink: ExtEventSink, env: &Env, collection: CollectionDescriptor) {
    let url = env.get(MELO_API_URL);
    let url = Url::from_str(&*url).unwrap();

    thread::spawn(move || {
        debug!(
            "Loading collection '{}' {}",
            &collection.name, &collection.id
        );
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .unwrap();

        let client = HttpClient::new(&url, None);
        let req = GetCollectionRequest {
            id_eq: collection.id.clone(),
        };
        let get_collection = rt.block_on(req.execute(&client)).unwrap();
        let collections = get_collection.library.collections;

        let collections = collections
            .into_iter()
            .map_into()
            .collect::<im::Vector<_>>();

        sink.submit_command(
            LOADED_COLLECTION,
            SingleUse::new((collection, collections.into_iter().next())),
            Target::Global,
        )
        .expect("command failed to submit");
    });
}
