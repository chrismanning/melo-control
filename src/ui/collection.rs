use std::sync::Arc;

use druid::widget::{Flex, Label, LineBreaking, List, Scroll};
use druid::{Env, EventCtx, Insets, Lens, MouseEvent, Widget, WidgetExt};
use itertools::Itertools;

use crate::data::collections::{
    Collection, CollectionDescriptor, CollectionSourceGroupsLens, Source,
    SourceGroupSourceSelection, SourceRef, SourceSelection,
};
use crate::data::deferred::Deferred;
use crate::data::AppState;
use crate::ui::controllers::{ClickHandler, TrackSelector, SELECT_TRACK, SELECT_TRACKS};
use crate::ui::theme;

pub fn collection_widget() -> impl Widget<Collection> {
    Scroll::new(
        List::new(|| {
            let album_artists = Label::dynamic(|item: &SourceGroupSourceSelection, _env| {
                let source_group = &item.source_group;
                match source_group.group_tags.album_artist.iter().join(" / ") {
                    x if x == String::new() => "<unknown artist>".to_string(),
                    x => x,
                }
            })
            .with_line_break_mode(LineBreaking::Clip);
            let album_title = Label::dynamic(|item: &SourceGroupSourceSelection, _env| {
                let source_group = &item.source_group;
                let album_artist = source_group.group_tags.album_title.to_owned();
                album_artist.unwrap_or_else(|| "<unknown album>".to_string())
            })
            .with_line_break_mode(LineBreaking::Clip);
            let year = Label::dynamic(|item: &SourceGroupSourceSelection, _env| {
                let source_group = &item.source_group;
                let date = source_group.group_tags.date.to_owned();
                date.unwrap_or_else(|| "<unknown date>".to_string())
            })
            .with_line_break_mode(LineBreaking::Clip)
            .fix_width(50.0);
            let tracks = List::new(|| {
                let track_number = Label::dynamic(|track: &Arc<Source>, _env| {
                    let track_number = track.metadata.mapped_tags.track_number.to_owned();
                    track_number.unwrap_or_else(|| "".to_string())
                })
                .with_line_break_mode(LineBreaking::Clip)
                .fix_width(30.0);
                let track_title = Label::dynamic(|track: &Arc<Source>, _env| {
                    let title = track.metadata.mapped_tags.track_title.to_owned();
                    title.unwrap_or_else(|| "<unknown title>".to_string())
                })
                .with_line_break_mode(LineBreaking::Clip)
                .expand_width();
                Flex::row()
                    .with_child(track_number)
                    .with_default_spacer()
                    .with_flex_child(track_title, 1.0)
                    .controller(ClickHandler::new(|mouse_event, ctx, data: &mut Arc<Source>, _env| {
                        debug!("Track clicked: {:?}", data);

                        ctx.submit_notification(SELECT_TRACK.with((data.clone(), mouse_event.mods)));
                    }))
                    .lens(SourceSelection::source)
                    // TODO selected track background colour
                    .background(theme::MENU_ITEM_BG)
                    .env_scope(|env: &mut Env, data: &SourceSelection| {
                        let selected = &data.selected_sources;
                        if selected.contains(&SourceRef(Arc::downgrade(&data.source))) {
                            env.set(theme::MENU_ITEM_BG, env.get(theme::MENU_ITEM_BG_ACTIVE));
                            trace!("MENU_ITEM_BG: {:?}", env.get(theme::MENU_ITEM_BG_ACTIVE));
                            env.set(theme::MENU_ITEM_FG, env.get(theme::MENU_ITEM_FG_ACTIVE));
                            trace!("MENU_ITEM_FG: {:?}", env.get(theme::MENU_ITEM_FG_ACTIVE));
                        } else {
                            env.set(theme::MENU_ITEM_BG, env.get(theme::MENU_ITEM_BG_INACTIVE));
                            trace!("MENU_ITEM_BG: {:?}", env.get(theme::MENU_ITEM_BG_INACTIVE));
                            env.set(theme::MENU_ITEM_FG, env.get(theme::MENU_ITEM_FG_INACTIVE));
                            trace!("MENU_ITEM_FG: {:?}", env.get(theme::MENU_ITEM_FG_INACTIVE));
                        }
                        // data.selected_sources.set(selected);
                    })
            })
            // .lens(SourceGroup::sources)
                ;
            let group_header = Flex::column()
                .with_default_spacer()
                .with_child(
                    Flex::row()
                        .with_child(album_artists.align_left())
                        .with_default_spacer()
                        .with_flex_child(album_title, 1.0)
                        .align_left()
                        .expand_width(),
                )
                .with_default_spacer()
                .with_child(year.align_left())
                .expand_width()
                .controller(ClickHandler::new(|mouse_event: &MouseEvent, ctx: &mut EventCtx, data: &mut SourceGroupSourceSelection, _env| {
                    debug!("Source group clicked clicked: {:?}", data.source_group.group_tags);

                    ctx.submit_notification(SELECT_TRACKS.with((data.source_group.sources.clone(), mouse_event.mods)));
                }));
            Flex::column()
                .with_child(group_header)
                .with_default_spacer()
                .with_child(tracks.padding(Insets::uniform_xy(7.0, 0.0)))
                .expand_width()
        })
        .with_spacing(3.0)
        .expand_width()
        .lens(CollectionSourceGroupsLens)
        .controller(TrackSelector)
    )
    .vertical()
    .padding(Insets::uniform(3.))
    .boxed()
}

#[derive(Debug)]
pub struct CollectionLens {
    target: CollectionDescriptor,
}

impl CollectionLens {
    pub fn new(target: CollectionDescriptor) -> Self {
        CollectionLens { target }
    }
}

impl Lens<AppState, Deferred<Collection>> for CollectionLens {
    fn with<V, F: FnOnce(&Deferred<Collection>) -> V>(&self, data: &AppState, f: F) -> V {
        if let Some(t) = data.collections_state.collections.get(&self.target) {
            f(&t)
        } else {
            f(&Deferred::Uninitialised)
        }
    }

    fn with_mut<V, F: FnOnce(&mut Deferred<Collection>) -> V>(
        &self,
        data: &mut AppState,
        f: F,
    ) -> V {
        if let Some(t) = data.collections_state.collections.get_mut(&self.target) {
            f(t)
        } else {
            let mut t = Deferred::Uninitialised;
            let v = f(&mut t);
            data.collections_state
                .collections
                .insert(self.target.clone(), t);
            v
        }
    }
}
