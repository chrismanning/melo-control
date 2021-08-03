use std::collections::HashMap;
use std::rc::Rc;

use druid::lens::Unit;
use druid::widget::{Label, Maybe};
use druid::{
    BoxConstraints, Data, Env, Event, EventCtx, LayoutCtx, Lens, LifeCycle, LifeCycleCtx, PaintCtx,
    Point, Size, UpdateCtx, Widget, WidgetExt, WidgetPod,
};

use crate::data::deferred as data;
use crate::data::deferred::DeferredState;

type UninitialisedFactory = dyn Fn() -> Box<dyn Widget<()>>;
type LoadingFactory = dyn Fn() -> Box<dyn Widget<()>>;
type ErrorFactory = dyn Fn() -> Box<dyn Widget<()>>;
type LoadedFactory<T> = dyn Fn() -> Box<dyn Widget<T>>;

pub struct Deferred<T: Data> {
    children: DeferredWidgets<T>,
}

struct DeferredWidgets<T: Data> {
    uninitialised_factory: Rc<UninitialisedFactory>,
    loading_factory: Rc<LoadingFactory>,
    error_factory: Rc<ErrorFactory>,
    loaded_factory: Rc<LoadedFactory<T>>,
    widgets: HashMap<data::DeferredState, DeferredWidget<T>>,
}

impl<T: Data> DeferredWidgets<T> {
    pub fn new<F, G, H, I, W, X, Y, Z>(
        uninitialised_factory: F,
        loading_factory: G,
        error_factory: H,
        loaded_factory: I,
    ) -> Self
    where
        F: Fn() -> W + 'static,
        G: Fn() -> X + 'static,
        H: Fn() -> Y + 'static,
        I: Fn() -> Z + 'static,
        W: Widget<()> + 'static,
        X: Widget<()> + 'static,
        Y: Widget<()> + 'static,
        Z: Widget<T> + 'static,
    {
        let uninitialised_factory = Rc::new(move || uninitialised_factory().boxed());
        let loading_factory = Rc::new(move || loading_factory().boxed());
        let error_factory = Rc::new(move || error_factory().boxed());
        let loaded_factory = Rc::new(move || loaded_factory().boxed());
        DeferredWidgets {
            uninitialised_factory,
            loading_factory,
            error_factory,
            loaded_factory,
            widgets: HashMap::new(),
        }
    }

    pub fn get(&self, state: data::DeferredState) -> &DeferredWidget<T> {
        self.widgets.get(&state).unwrap()
    }

    pub fn get_mut(&mut self, state: data::DeferredState) -> &mut DeferredWidget<T> {
        self.widgets.get_mut(&state).unwrap()
    }

    fn rebuild_widgets(&mut self) {
        debug!("Rebuilding Deferred widgets");
        self.widgets.clear();
        self.widgets.insert(
            data::DeferredState::Uninitialised,
            DeferredWidget::Uninitialised(WidgetPod::new(
                (self.uninitialised_factory)().lens(Unit).boxed(),
            )),
        );
        self.widgets.insert(
            data::DeferredState::Loading,
            DeferredWidget::Loading(WidgetPod::new((self.loading_factory)().lens(Unit).boxed())),
        );
        self.widgets.insert(
            data::DeferredState::Error,
            DeferredWidget::Error(WidgetPod::new((self.error_factory)().lens(Unit).boxed())),
        );
    }

    fn rebuild_loaded(&mut self) {
        debug!("Rebuilding Deferred::Loaded widget");
        let loaded_factory = self.loaded_factory.clone();
        let loaded = Maybe::new(move || loaded_factory(), || Label::new("Not loaded"))
            .lens(LoadedLens)
            .boxed();
        self.widgets.insert(
            DeferredState::Loaded,
            DeferredWidget::Loaded(WidgetPod::new(loaded)),
        );
    }
}

type DeferredInner<T> = WidgetPod<data::Deferred<T>, Box<dyn Widget<data::Deferred<T>>>>;

enum DeferredWidget<T: Data> {
    Uninitialised(DeferredInner<T>),
    Loading(DeferredInner<T>),
    Error(DeferredInner<T>),
    Loaded(DeferredInner<T>),
}

impl<T: Data> DeferredWidget<T> {
    fn inner(&self) -> &DeferredInner<T> {
        match &self {
            DeferredWidget::Uninitialised(w) => w,
            DeferredWidget::Loading(w) => w,
            DeferredWidget::Error(w) => w,
            DeferredWidget::Loaded(w) => w,
        }
    }

    fn inner_mut(&mut self) -> &mut DeferredInner<T> {
        match self {
            DeferredWidget::Uninitialised(w) => w,
            DeferredWidget::Loading(w) => w,
            DeferredWidget::Error(w) => w,
            DeferredWidget::Loaded(w) => w,
        }
    }
}

impl<T: Data> Deferred<T> {
    pub fn new<F, G, H, I>(
        uninitialised_factory: F,
        loading_factory: G,
        error_factory: H,
        loaded_factory: I,
    ) -> Self
    where
        F: Fn() -> Box<dyn Widget<()>> + 'static,
        G: Fn() -> Box<dyn Widget<()>> + 'static,
        H: Fn() -> Box<dyn Widget<()>> + 'static,
        I: Fn() -> Box<dyn Widget<T>> + 'static,
    {
        Deferred {
            children: DeferredWidgets::new(
                uninitialised_factory,
                loading_factory,
                error_factory,
                loaded_factory,
            ),
        }
    }
}

impl<T: Data + PartialEq> Widget<data::Deferred<T>> for Deferred<T> {
    fn event(
        &mut self,
        ctx: &mut EventCtx,
        event: &Event,
        data: &mut data::Deferred<T>,
        env: &Env,
    ) {
        trace!("Deferred::event called: {:?}", event);
        if event.should_propagate_to_hidden() {
            for child in self.children.widgets.values_mut() {
                child.inner_mut().event(ctx, event, data, env);
            }
        } else {
            self.children
                .get_mut(data.state())
                .inner_mut()
                .event(ctx, event, data, env);
        }
        // ctx.request_update();
    }

    fn lifecycle(
        &mut self,
        ctx: &mut LifeCycleCtx,
        event: &LifeCycle,
        data: &data::Deferred<T>,
        env: &Env,
    ) {
        trace!("Deferred::lifecycle called: {:?}", event);
        if let LifeCycle::WidgetAdded = event {
            self.children.rebuild_widgets();
        }
        if event.should_propagate_to_hidden() {
            for child in self.children.widgets.values_mut() {
                child.inner_mut().lifecycle(ctx, event, data, env);
            }
        } else {
            self.children
                .get_mut(data.state())
                .inner_mut()
                .lifecycle(ctx, event, data, env);
        }
    }

    fn update(
        &mut self,
        ctx: &mut UpdateCtx,
        old_data: &data::Deferred<T>,
        data: &data::Deferred<T>,
        env: &Env,
    ) {
        if old_data.state() != data.state() {
            debug!(
                "Deferred data state changed; Old: {:?}; New: {:?}",
                old_data.state(),
                data.state()
            );
            if data.state() == DeferredState::Loaded {
                self.children.rebuild_loaded();
            }
            ctx.children_changed();
        } else {
            self.children
                .get_mut(data.state())
                .inner_mut()
                .update(ctx, data, env);
        }
    }

    fn layout(
        &mut self,
        ctx: &mut LayoutCtx,
        bc: &BoxConstraints,
        data: &data::Deferred<T>,
        env: &Env,
    ) -> Size {
        trace!("Deferred::layout called");
        let inner = self.children.get_mut(data.state()).inner_mut();
        if inner.is_initialized() {
            let child_size = inner.layout(ctx, bc, data, env);
            trace!("Deferred::layout child_size: {:?}", child_size);
            inner.set_origin(ctx, data, env, Point::ORIGIN);

            child_size
        } else {
            bc.max()
        }
    }

    fn paint(&mut self, ctx: &mut PaintCtx, data: &data::Deferred<T>, env: &Env) {
        self.children
            .get_mut(data.state())
            .inner_mut()
            .paint_raw(ctx, data, env)
    }
}

struct LoadedLens;

impl<T: Data> Lens<data::Deferred<T>, Option<T>> for LoadedLens {
    fn with<V, F: FnOnce(&Option<T>) -> V>(&self, data: &data::Deferred<T>, f: F) -> V {
        let t = if let data::Deferred::Loaded(t) = data {
            t
        } else {
            &None
        };
        f(t)
    }

    fn with_mut<V, F: FnOnce(&mut Option<T>) -> V>(&self, data: &mut data::Deferred<T>, f: F) -> V {
        if let data::Deferred::Loaded(t) = data {
            f(t)
        } else {
            let mut t = None;
            let v = f(&mut t);
            *data = data::Deferred::Loaded(t);
            v
        }
    }
}
