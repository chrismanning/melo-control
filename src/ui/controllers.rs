use std::option::Option::Some;
use std::str::FromStr;
use std::sync::Arc;
use std::thread;

use druid::im::Vector;
use druid::widget::Controller;
use druid::{
    im, AppDelegate, Command, Data, DelegateCtx, Env, Event, EventCtx, ExtEventSink, Handled,
    Modifiers, MouseButton, MouseEvent, Selector, Target, Widget, WindowId,
};
use gurkle::HttpClient;
use itertools::Itertools;
use reqwest::Url;

use crate::api::GetCollectionsRequest;
use crate::api::MELO_API_URL;
use crate::data::collections::{Collection, CollectionDescriptor, Source, SourceRef};
use crate::data::deferred::Deferred;
use crate::data::navigation::NavRoute;
use crate::data::selection::{SelectableItem, SelectedState};
use crate::data::AppState;
use crate::ui::navigation::LOADED_COLLECTION;

pub struct OnLaunch<F> {
    run: F,
}

impl<F> OnLaunch<F> {
    pub fn new<T>(run: F) -> Self
    where
        F: Fn(&mut DelegateCtx, &mut T, &Env),
    {
        Self { run }
    }
}

impl<T: Data, F> AppDelegate<T> for OnLaunch<F>
where
    F: Fn(&mut DelegateCtx, &mut T, &Env),
{
    fn event(
        &mut self,
        ctx: &mut DelegateCtx,
        _window_id: WindowId,
        event: Event,
        data: &mut T,
        env: &Env,
    ) -> Option<Event> {
        if let Event::WindowConnected = event {
            debug!("Handling WindowConnected event");
            self.run.call_mut((ctx, data, env));
        }
        Some(event)
    }
}

pub const LOADED_COLLECTIONS: Selector<Option<im::Vector<CollectionDescriptor>>> =
    Selector::new("melo.loaded_collections");

pub struct CollectionsLoader;

impl AppDelegate<AppState> for CollectionsLoader {
    fn command(
        &mut self,
        _ctx: &mut DelegateCtx,
        _target: Target,
        cmd: &Command,
        data: &mut AppState,
        _env: &Env,
    ) -> Handled {
        if let Some(collections) = cmd.get(LOADED_COLLECTIONS) {
            data.collections_state.collection_descriptors = Deferred::Loaded(collections.clone());
            for collection in collections.iter().flatten().cloned() {
                data.routes.insert(SelectableItem::Selectable(
                    NavRoute::Collection(collection.clone()),
                    SelectedState::Unselected,
                ));
            }
            Handled::Yes
        // } else if let Some(payload) = cmd.get(LOADED_COLLECTION) {
        //     let (desc, collection) = payload.take().unwrap();
        //     info!("Handling loaded collection {:?}", desc);
        //     let collection = collection.map(Arc::new);
        //     data.collections_state
        //         .collections
        //         .insert(desc.clone(), Deferred::Loaded(collection.clone()));
        //     debug!("Collections: {:?}", &data.collections_state.collections);
        //     Handled::Yes
        } else {
            Handled::No
        }
    }
}

impl<W: Widget<AppState>> Controller<AppState, W> for CollectionsLoader {
    fn event(
        &mut self,
        child: &mut W,
        ctx: &mut EventCtx,
        event: &Event,
        data: &mut AppState,
        env: &Env,
    ) {
        if let Event::Command(cmd) = event {
            if let Some(payload) = cmd.get(LOADED_COLLECTION) {
                let (desc, collection) = payload.take().unwrap();
                info!("Handling loaded collection {:?}", desc);
                data.collections_state
                    .collections
                    .insert(desc.clone(), Deferred::Loaded(collection.clone()));
                // ctx.request_update();
            }
        } else {
            child.event(ctx, event, data, env)
        }
    }
}

pub fn load_collections(sink: ExtEventSink, env: &Env) {
    let url = env.get(MELO_API_URL);
    let url = Url::from_str(&*url).unwrap();

    thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .unwrap();
        let client = HttpClient::new(&url, None);
        let req = GetCollectionsRequest;
        let get_collections = rt.block_on(req.execute(&client)).unwrap();
        let collections = get_collections.library.collections;

        let collections = collections
            .iter()
            .cloned()
            .map_into()
            .collect::<im::Vector<CollectionDescriptor>>();

        sink.submit_command(LOADED_COLLECTIONS, Some(collections), Target::Global)
            .expect("command failed to submit");
    });
}

pub const SELECT_TRACK: Selector<(Arc<Source>, Modifiers)> = Selector::new("melo.select_track");
pub const SELECT_TRACKS: Selector<(Vector<Arc<Source>>, Modifiers)> =
    Selector::new("melo.select_tracks");

pub struct TrackSelector;

// impl AppDelegate<AppState> for TrackSelector {
//     fn command(&mut self, _ctx: &mut DelegateCtx, _target: Target, cmd: &Command, data: &mut AppState, _env: &Env) -> Handled {
//         match cmd.get(SELECT_TRACK) {
//             None => {}
//             Some((source, mods)) => {
//                 match &*data.current_route {
//                     NavRoute::Collection(collection_desc) => {
//                         let mut collections = &mut data.collections_state.collections;
//                         match collections.get_mut(&collection_desc.id) {
//                             None => {}
//                             Some(collection) => {
//                                 let mut collection = collection.lock().unwrap();
//                                 match &mut *collection {
//                                     Deferred::Loaded(Some(ref mut collection)) => {
//                                         if mods.contains(Modifiers::CONTROL) {
//                                             match collection.selected.remove(source) {
//                                                 None => {
//                                                     collection.selected.insert(source.clone());
//                                                 }
//                                                 Some(_) => {}
//                                             }
//                                         } else {
//                                             collection.selected.clear();
//                                             collection.selected.insert(source.clone());
//                                         }
//                                         debug!("Selected tracks: {:?}", &collection.selected);
//                                         return Handled::Yes;
//                                     }
//                                     _ => {}
//                                 }
//                             }
//                         }
//                     }
//                     _ => {}
//                 }
//             }
//         }
//         Handled::No
//     }
// }

impl TrackSelector {
    fn handle_select_track(
        ctx: &mut EventCtx,
        collection: &mut Collection,
        source: &Arc<Source>,
        mods: &Modifiers,
    ) {
        debug!("Handling SELECT_TRACK");
        debug!("Current selected tracks: {:?}", &collection.selected);
        debug!("mods: {:?}", mods);
        if mods.ctrl() {
            match collection
                .selected
                .remove(&SourceRef(Arc::downgrade(source)))
            {
                None => {
                    debug!("source wasn't selected; inserting");
                    collection
                        .selected
                        .insert(SourceRef(Arc::downgrade(source)));
                }
                Some(_) => {
                    debug!("source was selected; removed");
                }
            }
        } else {
            debug!("clearing selected");
            collection.selected.clear();
            collection
                .selected
                .insert(SourceRef(Arc::downgrade(source)));
        }
        debug!("Selected tracks: {:?}", &collection.selected);
        ctx.set_handled();
    }

    fn handle_select_tracks<'a>(
        ctx: &mut EventCtx,
        collection: &mut Collection,
        sources: impl Iterator<Item = &'a Arc<Source>>,
        mods: &Modifiers,
    ) {
        debug!("Handling SELECT_TRACKS");
        debug!("Current selected tracks: {:?}", &collection.selected);
        debug!("mods: {:?}", mods);
        if !mods.ctrl() {
            debug!("clearing selected");
            collection.selected.clear();
        }
        for source in sources {
            collection
                .selected
                .insert(SourceRef(Arc::downgrade(source)));
        }
        debug!("Selected tracks: {:?}", &collection.selected);
        ctx.set_handled();
    }
}

impl<W: Widget<Collection>> Controller<Collection, W> for TrackSelector {
    fn event(
        &mut self,
        child: &mut W,
        ctx: &mut EventCtx,
        event: &Event,
        collection: &mut Collection,
        env: &Env,
    ) {
        match event {
            Event::Command(cmd) => {
                if let Some((source, mods)) = cmd.get(SELECT_TRACK) {
                    Self::handle_select_track(ctx, &mut *collection, source, mods);
                    // ctx.children_changed();
                } else if let Some((sources, mods)) = cmd.get(SELECT_TRACKS) {
                    Self::handle_select_tracks(ctx, &mut *collection, sources.iter(), mods);
                    // ctx.children_changed();
                }
            }
            Event::Notification(notif) => {
                if let Some((source, mods)) = notif.get(SELECT_TRACK) {
                    Self::handle_select_track(ctx, &mut *collection, source, mods);
                    // ctx.children_changed();
                } else if let Some((sources, mods)) = notif.get(SELECT_TRACKS) {
                    Self::handle_select_tracks(ctx, &mut *collection, sources.iter(), mods);
                    // ctx.children_changed();
                }
            }
            _ => {}
        }
        child.event(ctx, event, collection, env);
    }
}

pub struct AggregateAppDelegate<T> {
    delegates: Vec<Box<dyn AppDelegate<T>>>,
}

impl<T> AggregateAppDelegate<T> {
    pub fn new(delegates: Vec<Box<dyn AppDelegate<T>>>) -> Self {
        AggregateAppDelegate { delegates }
    }
}

impl<T: Data> AppDelegate<T> for AggregateAppDelegate<T> {
    fn event(
        &mut self,
        ctx: &mut DelegateCtx,
        window_id: WindowId,
        event: Event,
        data: &mut T,
        env: &Env,
    ) -> Option<Event> {
        for delegate in self.delegates.iter_mut() {
            match delegate.event(ctx, window_id, event.clone(), data, env) {
                Some(_) => {}
                None => return None,
            }
        }
        Some(event)
    }

    fn command(
        &mut self,
        ctx: &mut DelegateCtx,
        target: Target,
        cmd: &Command,
        data: &mut T,
        env: &Env,
    ) -> Handled {
        for delegate in self.delegates.iter_mut() {
            match delegate.command(ctx, target.clone(), cmd, data, env) {
                Handled::Yes => {
                    return Handled::Yes;
                }
                Handled::No => {}
            }
        }
        Handled::No
    }

    fn window_added(&mut self, id: WindowId, data: &mut T, env: &Env, ctx: &mut DelegateCtx) {
        for delegate in self.delegates.iter_mut() {
            delegate.window_added(id, data, env, ctx)
        }
    }

    fn window_removed(&mut self, id: WindowId, data: &mut T, env: &Env, ctx: &mut DelegateCtx) {
        for delegate in self.delegates.iter_mut() {
            delegate.window_removed(id, data, env, ctx)
        }
    }
}

pub struct ClickHandler<T> {
    action: Box<dyn Fn(&MouseEvent, &mut EventCtx, &mut T, &Env)>,
}

impl<T> ClickHandler<T> {
    pub fn new(action: impl Fn(&MouseEvent, &mut EventCtx, &mut T, &Env) + 'static) -> Self {
        ClickHandler {
            action: Box::new(action),
        }
    }
}

impl<T, W: Widget<T>> Controller<T, W> for ClickHandler<T> {
    fn event(&mut self, child: &mut W, ctx: &mut EventCtx, event: &Event, data: &mut T, env: &Env) {
        match event {
            Event::MouseDown(mouse_event) => {
                if mouse_event.button == MouseButton::Left && !ctx.is_disabled() {
                    ctx.set_active(true);
                    ctx.request_paint();
                    trace!("Widget {:?} pressed", ctx.widget_id());
                }
            }
            Event::MouseUp(mouse_event) => {
                if ctx.is_active() && mouse_event.button == MouseButton::Left {
                    ctx.set_active(false);
                    if ctx.is_hot() && !ctx.is_disabled() {
                        (self.action)(mouse_event, ctx, data, env);
                    }
                    ctx.request_paint();
                    trace!("Widget {:?} released", ctx.widget_id());
                }
            }
            _ => {}
        }

        child.event(ctx, event, data, env);
    }
}
