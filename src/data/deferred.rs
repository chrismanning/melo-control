use druid::Data;

#[derive(Debug, Clone, Data, PartialEq)]
pub enum Deferred<T: Data> {
    Uninitialised,
    Loading,
    Loaded(Option<T>),
    Error,
}

impl<T: Data> Deferred<T> {
    pub fn state(&self) -> DeferredState {
        match self {
            Deferred::Uninitialised => DeferredState::Uninitialised,
            Deferred::Loading => DeferredState::Loading,
            Deferred::Loaded(_) => DeferredState::Loaded,
            Deferred::Error => DeferredState::Error,
        }
    }
}

#[derive(Debug, Ord, PartialOrd, Eq, PartialEq, Hash, Clone, Copy)]
pub enum DeferredState {
    Uninitialised,
    Loading,
    Error,
    Loaded,
}
