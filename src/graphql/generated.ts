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
  PictureTypeWrapper: any;
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


export type CollectionSourceGroupsArgs = {
  groupByMappings: Array<Scalars['String']>;
};


export type CollectionSourcesArgs = {
  where?: InputMaybe<SourceWhere>;
};

export type CollectionMutation = {
  __typename?: 'CollectionMutation';
  add: Collection;
  delete?: Maybe<Scalars['CollectionRef']>;
  deleteAll: Array<Scalars['CollectionRef']>;
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

export type EmbeddedImage = {
  __typename?: 'EmbeddedImage';
  downloadUri: Scalars['String'];
  imageType: Scalars['PictureTypeWrapper'];
};

export type EqExpr = {
  eq: Scalars['String'];
};

export type ExternalImage = {
  __typename?: 'ExternalImage';
  downloadUri: Scalars['String'];
  fileName: Scalars['String'];
};

export type FailedSourceUpdate = {
  __typename?: 'FailedSourceUpdate';
  id: Scalars['SourceRef'];
  msg: Scalars['String'];
};

export type Image = EmbeddedImage | ExternalImage;

export type InExpr = {
  in: Array<Scalars['String']>;
};

export type LibraryMutation = {
  __typename?: 'LibraryMutation';
  collection: CollectionMutation;
  transformSources: Array<UpdateSourceResult>;
};


export type LibraryMutationTransformSourcesArgs = {
  transformations: Array<Transform>;
  where?: InputMaybe<SourceWhere>;
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


export type LibraryQuerySourceGroupsArgs = {
  groupByMappings: Array<Scalars['String']>;
  where?: InputMaybe<SourceWhere>;
};


export type LibraryQuerySourcesArgs = {
  where?: InputMaybe<SourceWhere>;
};

export type MappedTag = {
  __typename?: 'MappedTag';
  mappingName: Scalars['String'];
  values: Array<Scalars['String']>;
};

export type Metadata = {
  __typename?: 'Metadata';
  format: Scalars['String'];
  formatId: Scalars['String'];
  mappedTags: Array<MappedTag>;
  tags: Array<TagPair>;
};


export type MetadataMappedTagsArgs = {
  mappings: Array<Scalars['String']>;
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

export type MusicBrainzLookup = {
  options?: InputMaybe<Scalars['Int']>;
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
  length?: Maybe<Scalars['Float']>;
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
  groupTags: Array<MappedTag>;
  sources: Array<Source>;
};

export type SourceWhere = {
  id?: InputMaybe<Where>;
  sourceUri?: InputMaybe<Where>;
};

export type SplitMultiTrackFile = {
  collectionRef?: InputMaybe<Scalars['String']>;
  destPattern: Scalars['String'];
};

export type StartsWithExpr = {
  startsWith: Scalars['String'];
};

export type TagPair = {
  __typename?: 'TagPair';
  key: Scalars['String'];
  value: Scalars['String'];
};

/**
 * Note! This input is an exclusive object,
 * i.e., the customer can provide a value for only one field.
 */
export type Transform = {
  EditMetadata?: InputMaybe<EditMetadata>;
  Move?: InputMaybe<Move>;
  MusicBrainzLookup?: InputMaybe<MusicBrainzLookup>;
  SplitMultiTrackFile?: InputMaybe<SplitMultiTrackFile>;
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


export type DeleteCollectionMutation = { __typename?: 'Mutation', library: { __typename?: 'LibraryMutation', collection: { __typename?: 'CollectionMutation', delete?: any | null } } };

export type TransformSourcesMutationVariables = Exact<{
  srcIds: Array<Scalars['String']> | Scalars['String'];
  transformations: Array<Transform> | Transform;
}>;


export type TransformSourcesMutation = { __typename?: 'Mutation', library: { __typename?: 'LibraryMutation', transformSources: Array<{ __typename: 'FailedSourceUpdate', id: any, msg: string } | { __typename: 'UpdatedSource', _0: { __typename?: 'Source', id: any } }> } };

export type GetCollectionSourcesQueryVariables = Exact<{
  collectionId: Scalars['String'];
}>;


export type GetCollectionSourcesQuery = { __typename?: 'Query', library: { __typename?: 'LibraryQuery', collections: Array<{ __typename?: 'Collection', sourceGroups: Array<{ __typename?: 'SourceGroup', groupParentUri: string, coverImage?: { __typename?: 'EmbeddedImage', downloadUri: string } | { __typename?: 'ExternalImage', downloadUri: string } | null, groupTags: Array<{ __typename?: 'MappedTag', mappingName: string, values: Array<string> }>, sources: Array<{ __typename?: 'Source', id: any, downloadUri: string, format: string, sourceName: string, filePath?: string | null, length?: number | null, metadata: { __typename?: 'Metadata', format: string, mappedTags: Array<{ __typename?: 'MappedTag', mappingName: string, values: Array<string> }> } }> }> }> } };

export type GetCollectionsQueryVariables = Exact<{ [key: string]: never; }>;


export type GetCollectionsQuery = { __typename?: 'Query', library: { __typename?: 'LibraryQuery', collections: Array<{ __typename?: 'Collection', id: any, name: string, kind: string, rootUri: string }> } };

export type PreviewTransformSourcesQueryVariables = Exact<{
  srcIds: Array<Scalars['String']> | Scalars['String'];
  transformations: Array<Transform> | Transform;
}>;


export type PreviewTransformSourcesQuery = { __typename?: 'Query', library: { __typename?: 'LibraryQuery', sources: Array<{ __typename?: 'Source', metadata: { __typename?: 'Metadata', format: string, tags: Array<{ __typename?: 'TagPair', key: string, value: string }> }, previewTransform: { __typename: 'FailedSourceUpdate', id: any, msg: string } | { __typename: 'UpdatedSource', _0: { __typename?: 'Source', id: any, downloadUri: string, sourceName: string, filePath?: string | null, metadata: { __typename?: 'Metadata', format: string, tags: Array<{ __typename?: 'TagPair', key: string, value: string }>, mappedTags: Array<{ __typename?: 'MappedTag', mappingName: string, values: Array<string> }> } } } }> } };
