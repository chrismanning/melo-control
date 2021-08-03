use std::fmt::Debug;
use std::hash::{Hash, Hasher};

use std::sync::{Arc, Weak};

use druid::widget::ListIter;
use druid::{im, Data, Lens};
use itertools::Itertools;

use crate::api::get_collection::{
    GetCollectionLibraryCollections, GetCollectionLibraryCollectionsSourceGroups,
    GetCollectionLibraryCollectionsSourceGroupsGroupTags,
    GetCollectionLibraryCollectionsSourceGroupsSources,
    GetCollectionLibraryCollectionsSourceGroupsSourcesMetadata,
    GetCollectionLibraryCollectionsSourceGroupsSourcesMetadataMappedTags,
};
use crate::api::get_collections::GetCollectionsLibraryCollections;
use crate::data::deferred::Deferred;

#[derive(Clone, Data, Lens)]
pub struct CollectionsState {
    pub collection_descriptors: Deferred<im::Vector<CollectionDescriptor>>,
    pub collections: im::HashMap<CollectionDescriptor, Deferred<Collection>>,
    pub current_collection: Option<Arc<CollectionDescriptor>>,
}

impl CollectionsState {
    pub fn new() -> Self {
        CollectionsState {
            collection_descriptors: Deferred::Uninitialised,
            collections: im::hashmap![],
            current_collection: None,
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Hash, Data, Lens)]
pub struct CollectionDescriptor {
    pub id: String,
    pub name: String,
    pub kind: CollectionKind,
    pub root_uri: String,
}

impl From<GetCollectionsLibraryCollections> for CollectionDescriptor {
    fn from(c: GetCollectionsLibraryCollections) -> Self {
        CollectionDescriptor {
            id: c.id,
            name: c.name,
            kind: CollectionKind::Filesystem,
            root_uri: c.root_uri,
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Hash, Data)]
pub enum CollectionKind {
    Filesystem,
}

#[derive(Debug, Clone, Eq, PartialEq, Data, Lens)]
pub struct Collection {
    pub id: String,
    pub name: String,
    pub source_groups: im::Vector<Arc<SourceGroup>>,
    pub selected: im::HashSet<SourceRef>,
}

impl From<GetCollectionLibraryCollections> for Collection {
    fn from(c: GetCollectionLibraryCollections) -> Self {
        debug!("Converting GetCollectionLibraryCollections to Collection");
        Collection {
            id: c.id,
            name: c.name,
            source_groups: c
                .source_groups
                .into_iter()
                .map_into()
                .map(Arc::new)
                .collect(),
            selected: im::HashSet::new(),
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Data, Lens)]
pub struct SourceGroup {
    pub sources: im::Vector<Arc<Source>>,
    pub group_tags: GroupTags,
}

impl From<GetCollectionLibraryCollectionsSourceGroups> for SourceGroup {
    fn from(s: GetCollectionLibraryCollectionsSourceGroups) -> Self {
        SourceGroup {
            group_tags: s.group_tags.into(),
            sources: s.sources.into_iter().map_into().map(Arc::new).collect(),
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Data, Lens)]
pub struct GroupTags {
    pub album_artist: im::Vector<String>,
    pub album_title: Option<String>,
    pub date: Option<String>,
    pub disc_number: Option<String>,
    pub genre: im::Vector<String>,
    pub total_discs: Option<String>,
}

impl From<GetCollectionLibraryCollectionsSourceGroupsGroupTags> for GroupTags {
    fn from(s: GetCollectionLibraryCollectionsSourceGroupsGroupTags) -> Self {
        GroupTags {
            album_artist: s.album_artist.into_iter().flatten().collect(),
            album_title: s.album_title,
            date: s.date,
            disc_number: s.disc_number,
            genre: s.genre.into_iter().flatten().collect(),
            total_discs: s.total_discs,
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Hash, Data, Lens)]
pub struct Source {
    pub id: String,
    pub metadata: Metadata,
    pub download_uri: String,
}

impl From<GetCollectionLibraryCollectionsSourceGroupsSources> for Source {
    fn from(s: GetCollectionLibraryCollectionsSourceGroupsSources) -> Self {
        Source {
            id: s.id,
            metadata: s.metadata.into(),
            download_uri: s.download_uri,
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Hash, Data, Lens)]
pub struct Metadata {
    pub mapped_tags: MappedTags,
}

impl From<GetCollectionLibraryCollectionsSourceGroupsSourcesMetadata> for Metadata {
    fn from(m: GetCollectionLibraryCollectionsSourceGroupsSourcesMetadata) -> Self {
        Metadata {
            mapped_tags: m.mapped_tags.into(),
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Hash, Data, Lens)]
pub struct MappedTags {
    pub artist_name: im::Vector<String>,
    pub track_number: Option<String>,
    pub track_title: Option<String>,
}

impl From<GetCollectionLibraryCollectionsSourceGroupsSourcesMetadataMappedTags> for MappedTags {
    fn from(m: GetCollectionLibraryCollectionsSourceGroupsSourcesMetadataMappedTags) -> Self {
        MappedTags {
            artist_name: m.artist_name.into_iter().flatten().collect(),
            track_number: m.track_number,
            track_title: m.track_title,
        }
    }
}

#[derive(Debug, Clone, Data)]
pub struct SourceRef(pub Weak<Source>);

impl Eq for SourceRef {}

impl PartialEq for SourceRef {
    fn eq(&self, other: &Self) -> bool {
        self.0.ptr_eq(&other.0)
    }
}

impl Hash for SourceRef {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.0.as_ptr().hash(state)
    }
}

#[derive(Clone, Data, Lens)]
pub struct SourceSelection {
    pub source: Arc<Source>,
    pub selected_sources: im::HashSet<SourceRef>,
}

#[derive(Clone, Data)]
pub struct SourceGroupSourceSelection {
    pub source_group: Arc<SourceGroup>,
    pub selected_sources: im::HashSet<SourceRef>,
}

impl ListIter<SourceSelection> for SourceGroupSourceSelection {
    fn for_each(&self, mut cb: impl FnMut(&SourceSelection, usize)) {
        for (i, source) in self.source_group.sources.iter().enumerate() {
            let s = SourceSelection {
                source: source.clone(),
                selected_sources: self.selected_sources.clone(),
            };
            cb(&s, i);
        }
    }

    fn for_each_mut(&mut self, mut cb: impl FnMut(&mut SourceSelection, usize)) {
        trace!("for_each_mut SourceGroupSourceSelection");
        let sources = self.source_group.sources.clone();
        let sources = sources
            .iter()
            .enumerate()
            .map(|(i, source)| {
                let mut s = SourceSelection {
                    source: source.clone(),
                    selected_sources: self.selected_sources.clone(),
                };
                cb(&mut s, i);
                self.selected_sources = s.selected_sources;
                s.source
            })
            .collect();

        let source_group = Arc::make_mut(&mut self.source_group);
        source_group.sources = sources;
    }

    fn data_len(&self) -> usize {
        self.source_group.sources.len()
    }
}

#[derive(Clone, Data)]
pub struct SourceGroupsSourceSelection {
    pub source_groups: im::Vector<Arc<SourceGroup>>,
    pub selected_sources: im::HashSet<SourceRef>,
}

impl ListIter<SourceGroupSourceSelection> for SourceGroupsSourceSelection {
    fn for_each(&self, mut cb: impl FnMut(&SourceGroupSourceSelection, usize)) {
        for (i, source_group) in self.source_groups.iter().enumerate() {
            let s = SourceGroupSourceSelection {
                source_group: source_group.clone(),
                selected_sources: self.selected_sources.clone(),
            };
            cb(&s, i);
        }
    }

    fn for_each_mut(&mut self, mut cb: impl FnMut(&mut SourceGroupSourceSelection, usize)) {
        trace!("for_each_mut SourceGroupsSourceSelection");
        let mut source_groups = self.source_groups.iter().cloned().collect_vec();
        self.source_groups = source_groups
            .iter_mut()
            .enumerate()
            .map(|(i, source_group)| {
                let mut s = SourceGroupSourceSelection {
                    source_group: source_group.clone(),
                    selected_sources: self.selected_sources.clone(),
                };
                cb(&mut s, i);
                self.selected_sources = s.selected_sources;
                s.source_group
            })
            .collect();
    }

    fn data_len(&self) -> usize {
        self.source_groups.len()
    }
}

pub struct CollectionSourceGroupsLens;

impl Lens<Collection, SourceGroupsSourceSelection> for CollectionSourceGroupsLens {
    fn with<V, F: FnOnce(&SourceGroupsSourceSelection) -> V>(&self, data: &Collection, f: F) -> V {
        let groups = SourceGroupsSourceSelection {
            source_groups: data.source_groups.clone(),
            selected_sources: data.selected.clone(),
        };
        f(&groups)
    }

    fn with_mut<V, F: FnOnce(&mut SourceGroupsSourceSelection) -> V>(
        &self,
        data: &mut Collection,
        f: F,
    ) -> V {
        trace!("Mutating via CollectionSourceGroupsLens");
        let mut groups = SourceGroupsSourceSelection {
            source_groups: data.source_groups.clone(),
            selected_sources: data.selected.clone(),
        };
        let r = f(&mut groups);
        data.selected = groups.selected_sources;
        data.source_groups = groups.source_groups;
        r
    }
}
