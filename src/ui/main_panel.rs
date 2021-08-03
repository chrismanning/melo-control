use std::collections::HashMap;

use druid::widget::{CrossAxisAlignment, Flex, Label, Spinner};
use druid::{
    BoxConstraints, Env, Event, EventCtx, LayoutCtx, LifeCycle, LifeCycleCtx, PaintCtx, Point,
    Size, UpdateCtx, Widget, WidgetExt, WidgetPod,
};

use crate::data::navigation::NavRoute;
use crate::data::AppState;
use crate::ui::collection::{collection_widget, CollectionLens};
use crate::ui::controllers::CollectionsLoader;
use crate::ui::widgets::deferred::Deferred;

pub fn main_panel() -> impl Widget<AppState> {
    MainPanel::new().controller(CollectionsLoader)
}

pub struct MainPanel {
    nav_route_widgets: HashMap<NavRoute, WidgetPod<AppState, Box<dyn Widget<AppState>>>>,
}

impl MainPanel {
    pub fn new() -> Self {
        Self {
            nav_route_widgets: HashMap::new(),
        }
    }
}

impl Widget<AppState> for MainPanel {
    fn event(&mut self, ctx: &mut EventCtx, event: &Event, data: &mut AppState, env: &Env) {
        // if event.should_propagate_to_hidden() {
        //     for widget in self.nav_route_widgets.values_mut() {
        //         widget.event(ctx, event, data, env);
        //     }
        // } else
        trace!("MainPanel::event called: {:?}", event);
        if let Some(current) = self.nav_route_widgets.get_mut(&data.current_route) {
            current.event(ctx, event, data, env);
        }
    }

    fn lifecycle(&mut self, ctx: &mut LifeCycleCtx, event: &LifeCycle, data: &AppState, env: &Env) {
        if let LifeCycle::WidgetAdded = event {
            for selectable_route in data.routes.iter() {
                self.nav_route_widgets
                    .entry(selectable_route.inner().clone())
                    .or_insert_with(|| WidgetPod::new(widget_factory(selectable_route.inner())));
            }
        }
        trace!("MainPanel::lifecycle event: {:?}", event);
        if let Some(current) = self.nav_route_widgets.get_mut(&data.current_route) {
            current.lifecycle(ctx, event, data, env);
        }
    }

    fn update(&mut self, ctx: &mut UpdateCtx, old_data: &AppState, data: &AppState, env: &Env) {
        trace!("MainPanel::update called");
        let old_routes = old_data
            .routes
            .0
            .iter()
            .map(|s| s.inner().clone())
            .collect::<Vec<_>>();
        let new_routes = data
            .routes
            .0
            .iter()
            .map(|s| s.inner().clone())
            .collect::<Vec<_>>();
        if old_routes.len() != new_routes.len() {
            for new_route in &new_routes {
                self.nav_route_widgets
                    .entry(new_route.clone())
                    .or_insert_with(|| WidgetPod::new(widget_factory(new_route)));
            }
            self.nav_route_widgets.retain(|k, _| new_routes.contains(k));
        }
        trace!("Old route: {:?}", &old_data.current_route);
        trace!("New route: {:?}", &data.current_route);
        if old_data.current_route != data.current_route {
            debug!("Route changed");
            ctx.children_changed();
        } else if let Some(current) = self.nav_route_widgets.get_mut(&data.current_route) {
            trace!("Current main widget available");
            if current.is_initialized() {
                trace!("Updating main child widget");
                current.update(ctx, data, env);
            }
        }
    }

    fn layout(
        &mut self,
        ctx: &mut LayoutCtx,
        bc: &BoxConstraints,
        data: &AppState,
        env: &Env,
    ) -> Size {
        trace!("MainPanel::layout called");
        if let Some(current) = self.nav_route_widgets.get_mut(&data.current_route) {
            trace!("MainPanel::layout current route is Some");
            let child_size = current.layout(ctx, bc, data, env);
            trace!("MainPanel::layout child_size: {:?}", child_size);
            current.set_origin(ctx, data, env, Point::ORIGIN);

            return child_size;
        }
        trace!("MainPanel::layout bc.max()");
        bc.max()
    }

    fn paint(&mut self, ctx: &mut PaintCtx, data: &AppState, env: &Env) {
        trace!("MainPanel::paint called");
        if let Some(current) = self.nav_route_widgets.get_mut(&data.current_route) {
            trace!("Painting main panel");
            if current.is_initialized() {
                current.paint_raw(ctx, data, env)
            }
        }
    }
}

fn widget_factory(route: &NavRoute) -> Box<dyn Widget<AppState>> {
    debug!("Creating widget for route {:?}", route);
    match route {
        NavRoute::Home => Label::new("Home").boxed(),
        NavRoute::Collection(c) => {
            Deferred::new(
                || Label::new("Uninitialised").boxed(),
                || {
                    Flex::row()
                        .with_child(Spinner::new())
                        .with_child(Label::new("Loading"))
                        .cross_axis_alignment(CrossAxisAlignment::Start)
                        .boxed()
                },
                || Label::new("Error").boxed(),
                || collection_widget().expand().boxed(),
            )
            .lens(CollectionLens::new(c.clone()))
            .expand()
            // .debug_invalidation()
            .boxed()
        }
        NavRoute::RecentlyAdded => Label::new("Recently Added").boxed(),
        NavRoute::Settings => Label::new("Settings").boxed(),
    }
}
