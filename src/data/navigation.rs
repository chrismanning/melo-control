use std::cmp::Ordering;

use druid::Data;

use crate::data::collections::CollectionDescriptor;

#[derive(Clone, Data, Debug, PartialEq, Eq, Hash)]
pub enum NavRoute {
    Home,
    Collection(CollectionDescriptor),
    RecentlyAdded,
    Settings,
}

impl NavRoute {
    pub fn title(&self) -> String {
        use NavRoute::*;
        match self {
            Home => "Home".to_owned(),
            Collection(c) => c.name.clone(),
            RecentlyAdded => "Recently Added".to_owned(),
            Settings => "Settings".to_owned(),
        }
    }
}

impl PartialOrd for NavRoute {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(&other))
    }
}

impl Ord for NavRoute {
    fn cmp(&self, other: &Self) -> Ordering {
        use NavRoute::*;
        match (&self, other) {
            (Home, Home) => Ordering::Equal,
            (Home, _) => Ordering::Less,
            (_, Home) => Ordering::Greater,
            (Collection(a), Collection(b)) => a.name.cmp(&b.name),
            (Collection(_), _) => Ordering::Less,
            (_, Collection(_)) => Ordering::Greater,
            (RecentlyAdded, RecentlyAdded) => Ordering::Equal,
            (Settings, Settings) => Ordering::Equal,
            (Settings, _) => Ordering::Greater,
            (_, Settings) => Ordering::Less,
        }
    }
}
