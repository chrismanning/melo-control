export type Maybe<T> = T | null;
export type InputMaybe<T> = Maybe<T>;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]?: Maybe<T[SubKey]> };
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]: Maybe<T[SubKey]> };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
  CollectionRef: any;
  SourceRef: any;
};

export type Collection = {
  __typename?: 'Collection';
  id: Scalars['CollectionRef'];
  kind: Scalars['String'];
  name: Scalars['String'];
  rootUri: Scalars['String'];
  sourceGroups: Array<SourceGroup>;
  sources: Array<Source>;
  watch: Scalars['Boolean'];
};


export type CollectionSourcesArgs = {
  where?: InputMaybe<SourceWhere>;
};

export type CollectionMutation = {
  __typename?: 'CollectionMutation';
  add: Collection;
  delete: Unit;
  deleteAll: Unit;
};


export type CollectionMutationAddArgs = {
  newCollection: NewCollection;
};


export type CollectionMutationDeleteArgs = {
  id: Scalars['CollectionRef'];
};

export type CollectionWhere = {
  id?: InputMaybe<Where>;
  rootUri?: InputMaybe<Where>;
};

export type ContainsExpr = {
  contains: Scalars['String'];
};

export type EditMetadata = {
  metadataTransform: MetadataTransformation;
};

export type EqExpr = {
  eq: Scalars['String'];
};

export type FailedSourceUpdate = {
  __typename?: 'FailedSourceUpdate';
  id: Scalars['SourceRef'];
  msg: Scalars['String'];
};

export type GroupTags = {
  __typename?: 'GroupTags';
  albumArtist?: Maybe<Array<Scalars['String']>>;
  albumTitle?: Maybe<Scalars['String']>;
  date?: Maybe<Scalars['String']>;
  discNumber?: Maybe<Scalars['String']>;
  genre?: Maybe<Array<Scalars['String']>>;
  musicbrainzAlbumArtistId?: Maybe<Array<Scalars['String']>>;
  musicbrainzAlbumId?: Maybe<Scalars['String']>;
  musicbrainzArtistId?: Maybe<Array<Scalars['String']>>;
  totalDiscs?: Maybe<Scalars['String']>;
  totalTracks?: Maybe<Scalars['String']>;
};

export type Image = {
  __typename?: 'Image';
  downloadUri: Scalars['String'];
  fileName: Scalars['String'];
};

export type InExpr = {
  in: Array<Scalars['String']>;
};

export type LibraryMutation = {
  __typename?: 'LibraryMutation';
  collection: CollectionMutation;
  stageSources: StagedSources;
  transformSources: Array<UpdateSourceResult>;
  updateSources: Array<UpdateSourceResult>;
};


export type LibraryMutationStageSourcesArgs = {
  uris: Array<Scalars['String']>;
};


export type LibraryMutationTransformSourcesArgs = {
  transformations: Array<Transform>;
  where?: InputMaybe<SourceWhere>;
};


export type LibraryMutationUpdateSourcesArgs = {
  updates: Array<SourceUpdate>;
};

export type LibraryQuery = {
  __typename?: 'LibraryQuery';
  collections: Array<Collection>;
  sourceGroups: Array<SourceGroup>;
  sources: Array<Source>;
};


export type LibraryQueryCollectionsArgs = {
  where?: InputMaybe<CollectionWhere>;
};


export type LibraryQuerySourcesArgs = {
  where?: InputMaybe<SourceWhere>;
};

export type MappedTags = {
  __typename?: 'MappedTags';
  albumArtist?: Maybe<Array<Scalars['String']>>;
  albumTitle?: Maybe<Scalars['String']>;
  artistName?: Maybe<Array<Scalars['String']>>;
  comment?: Maybe<Scalars['String']>;
  date?: Maybe<Scalars['String']>;
  discNumber?: Maybe<Scalars['String']>;
  genre?: Maybe<Array<Scalars['String']>>;
  musicbrainzAlbumArtistId?: Maybe<Array<Scalars['String']>>;
  musicbrainzAlbumId?: Maybe<Scalars['String']>;
  musicbrainzArtistId?: Maybe<Array<Scalars['String']>>;
  musicbrainzTrackId?: Maybe<Scalars['String']>;
  totalDiscs?: Maybe<Scalars['String']>;
  totalTracks?: Maybe<Scalars['String']>;
  trackNumber?: Maybe<Scalars['String']>;
  trackTitle?: Maybe<Scalars['String']>;
};

export type MappedTagsInput = {
  albumArtist?: InputMaybe<Array<Scalars['String']>>;
  albumTitle?: InputMaybe<Scalars['String']>;
  artistName?: InputMaybe<Array<Scalars['String']>>;
  comment?: InputMaybe<Scalars['String']>;
  date?: InputMaybe<Scalars['String']>;
  discNumber?: InputMaybe<Scalars['String']>;
  genre?: InputMaybe<Array<Scalars['String']>>;
  musicbrainzAlbumArtistId?: InputMaybe<Array<Scalars['String']>>;
  musicbrainzAlbumId?: InputMaybe<Scalars['String']>;
  musicbrainzArtistId?: InputMaybe<Array<Scalars['String']>>;
  musicbrainzTrackId?: InputMaybe<Scalars['String']>;
  totalDiscs?: InputMaybe<Scalars['String']>;
  totalTracks?: InputMaybe<Scalars['String']>;
  trackNumber?: InputMaybe<Scalars['String']>;
  trackTitle?: InputMaybe<Scalars['String']>;
};

export type Metadata = {
  __typename?: 'Metadata';
  format: Scalars['String'];
  formatId: Scalars['String'];
  mappedTags: MappedTags;
  tags: Array<TagPair>;
};

/**
 * Note! This input is an exclusive object,
 * i.e., the customer can provide a value for only one field.
 */
export type MetadataTransformation = {
  RemoveMappings?: InputMaybe<RemoveMappings>;
  Retain?: InputMaybe<Retain>;
  SetMapping?: InputMaybe<SetMapping>;
};

export type Move = {
  collectionRef?: InputMaybe<Scalars['String']>;
  destPattern: Scalars['String'];
};

export type Mutation = {
  __typename?: 'Mutation';
  library: LibraryMutation;
};

export type NewCollection = {
  name: Scalars['String'];
  rootPath: Scalars['String'];
  watch: Scalars['Boolean'];
};

export type NotEqExpr = {
  notEq: Scalars['String'];
};

export type Query = {
  __typename?: 'Query';
  library: LibraryQuery;
};

export type RemoveMappings = {
  mappings: Array<Scalars['String']>;
};

export type Retain = {
  mappings: Array<Scalars['String']>;
};

export type SetMapping = {
  mapping: Scalars['String'];
  values: Array<Scalars['String']>;
};

export type Source = {
  __typename?: 'Source';
  coverImage?: Maybe<Image>;
  downloadUri: Scalars['String'];
  filePath?: Maybe<Scalars['String']>;
  format: Scalars['String'];
  id: Scalars['SourceRef'];
  length: Scalars['Float'];
  metadata: Metadata;
  previewTransform: UpdateSourceResult;
  sourceName: Scalars['String'];
  sourceUri: Scalars['String'];
};


export type SourcePreviewTransformArgs = {
  transformations: Array<Transform>;
};

export type SourceGroup = {
  __typename?: 'SourceGroup';
  coverImage?: Maybe<Image>;
  groupParentUri: Scalars['String'];
  groupTags: GroupTags;
  sources: Array<Source>;
};

export type SourceUpdate = {
  id: Scalars['SourceRef'];
  updateTags: TagUpdate;
};

export type SourceWhere = {
  id?: InputMaybe<Where>;
  sourceUri?: InputMaybe<Where>;
};

export type SplitMultiTrackFile = {
  collectionRef?: InputMaybe<Scalars['String']>;
  destPattern: Scalars['String'];
};

export type StagedSources = {
  __typename?: 'StagedSources';
  groups: Array<SourceGroup>;
  numberOfSourcesImported: Scalars['Int'];
  sources: Array<Source>;
};

export type StartsWithExpr = {
  startsWith: Scalars['String'];
};

export type TagPair = {
  __typename?: 'TagPair';
  key: Scalars['String'];
  value: Scalars['String'];
};

export type TagUpdate = {
  setMappedTags?: InputMaybe<MappedTagsInput>;
  setTags?: InputMaybe<Array<UpdatePair>>;
};

/**
 * Note! This input is an exclusive object,
 * i.e., the customer can provide a value for only one field.
 */
export type Transform = {
  EditMetadata?: InputMaybe<EditMetadata>;
  Move?: InputMaybe<Move>;
  SplitMultiTrackFile?: InputMaybe<SplitMultiTrackFile>;
};

export enum Unit {
  Unit = 'Unit'
}

export type UpdatePair = {
  key: Scalars['String'];
  value: Scalars['String'];
};

export type UpdateSourceResult = FailedSourceUpdate | UpdatedSource;

export type UpdatedSource = {
  __typename?: 'UpdatedSource';
  _0: Source;
};

/**
 * Note! This input is an exclusive object,
 * i.e., the customer can provide a value for only one field.
 */
export type Where = {
  ContainsExpr?: InputMaybe<ContainsExpr>;
  EqExpr?: InputMaybe<EqExpr>;
  InExpr?: InputMaybe<InExpr>;
  NotEqExpr?: InputMaybe<NotEqExpr>;
  StartsWithExpr?: InputMaybe<StartsWithExpr>;
};

export type AddCollectionMutationVariables = Exact<{
  name: Scalars['String'];
  rootPath: Scalars['String'];
  watch: Scalars['Boolean'];
}>;


export type AddCollectionMutation = { __typename?: 'Mutation', library: { __typename?: 'LibraryMutation', collection: { __typename?: 'CollectionMutation', add: { __typename?: 'Collection', id: any, name: string, kind: string, rootUri: string, watch: boolean } } } };

export type DeleteCollectionMutationVariables = Exact<{
  collectionId: Scalars['CollectionRef'];
}>;


export type DeleteCollectionMutation = { __typename?: 'Mutation', library: { __typename?: 'LibraryMutation', collection: { __typename?: 'CollectionMutation', delete: Unit } } };

export type GetCollectionQueryVariables = Exact<{
  collectionId: Scalars['String'];
}>;


export type GetCollectionQuery = { __typename?: 'Query', library: { __typename?: 'LibraryQuery', collections: Array<{ __typename?: 'Collection', id: any, name: string, sourceGroups: Array<{ __typename?: 'SourceGroup', sources: Array<{ __typename?: 'Source', id: any, downloadUri: string, metadata: { __typename?: 'Metadata', mappedTags: { __typename?: 'MappedTags', artistName?: Array<string> | null, trackNumber?: string | null, trackTitle?: string | null } } }>, groupTags: { __typename?: 'GroupTags', albumArtist?: Array<string> | null, albumTitle?: string | null, date?: string | null, discNumber?: string | null, genre?: Array<string> | null, totalDiscs?: string | null } }> }> } };

export type GetCollectionSourcesQueryVariables = Exact<{
  collectionId: Scalars['String'];
}>;


export type GetCollectionSourcesQuery = { __typename?: 'Query', library: { __typename?: 'LibraryQuery', collections: Array<{ __typename?: 'Collection', sourceGroups: Array<{ __typename?: 'SourceGroup', groupParentUri: string, coverImage?: { __typename?: 'Image', downloadUri: string, fileName: string } | null, groupTags: { __typename?: 'GroupTags', albumArtist?: Array<string> | null, albumTitle?: string | null, date?: string | null, totalTracks?: string | null, discNumber?: string | null, totalDiscs?: string | null, genre?: Array<string> | null }, sources: Array<{ __typename?: 'Source', id: any, downloadUri: string, format: string, sourceName: string, filePath?: string | null, length: number, metadata: { __typename?: 'Metadata', format: string, tags: Array<{ __typename?: 'TagPair', value: string, key: string }>, mappedTags: { __typename?: 'MappedTags', trackNumber?: string | null, trackTitle?: string | null, artistName?: Array<string> | null } } }> }> }> } };

export type GetCollectionsQueryVariables = Exact<{ [key: string]: never; }>;


export type GetCollectionsQuery = { __typename?: 'Query', library: { __typename?: 'LibraryQuery', collections: Array<{ __typename?: 'Collection', id: any, name: string, kind: string, rootUri: string }> } };

export type PreviewTransformSourcesQueryVariables = Exact<{
  srcIds: Array<Scalars['String']> | Scalars['String'];
  movePattern: Scalars['String'];
}>;


export type PreviewTransformSourcesQuery = { __typename?: 'Query', library: { __typename?: 'LibraryQuery', sources: Array<{ __typename?: 'Source', previewTransform: { __typename: 'FailedSourceUpdate', id: any, msg: string } | { __typename: 'UpdatedSource', _0: { __typename?: 'Source', id: any, downloadUri: string, sourceName: string, filePath?: string | null, metadata: { __typename?: 'Metadata', format: string, tags: Array<{ __typename?: 'TagPair', key: string, value: string }> } } } }> } };
