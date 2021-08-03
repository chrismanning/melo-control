use std::iter::FromIterator;
use std::ops::{Deref, DerefMut};

use druid::im;
use druid::widget::ListIter;
use druid::{Data, Lens};

use crate::data::collections::CollectionsState;

use crate::data::navigation::NavRoute;
use crate::data::selection::SelectableItem;

pub mod collections;
pub mod deferred;
pub mod navigation;
pub mod selection;

#[derive(Clone, Data, Lens)]
pub struct AppState {
    pub current_route: NavRoute,
    pub collections_state: CollectionsState,
    pub routes: OrdSet<SelectableItem<NavRoute>>,
}

#[derive(Debug, Clone)]
pub struct OrdSet<T: Ord>(pub(crate) im::OrdSet<T>);

impl<T: Ord> OrdSet<T> {
    pub fn new() -> Self {
        Self(im::OrdSet::new())
    }
}

impl<T: Data + Clone + PartialEq + Ord> Data for OrdSet<T> {
    fn same(&self, other: &Self) -> bool {
        self.0 == other.0
    }
}

impl<T: Ord> Deref for OrdSet<T> {
    type Target = im::OrdSet<T>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<T: Ord> DerefMut for OrdSet<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl<T: Data + PartialEq + Ord> ListIter<T> for OrdSet<T> {
    fn for_each(&self, mut cb: impl FnMut(&T, usize)) {
        for (i, x) in self.0.iter().enumerate() {
            cb(&x, i);
        }
    }

    fn for_each_mut(&mut self, mut cb: impl FnMut(&mut T, usize)) {
        let mut clone: Vec<_> = self.0.iter().cloned().collect();
        for (i, mut x) in clone.iter_mut().enumerate() {
            cb(&mut x, i);
        }
        self.0 = im::OrdSet::from_iter(clone.into_iter());
    }

    fn data_len(&self) -> usize {
        self.0.len()
    }
}
