import TransformSources from 'raw-loader!../../graphql/mutations/transform_sources.graphql'
import GetCollectionSources from 'raw-loader!./../../graphql/queries/get_collection_sources.graphql'
import PreviewTransformSources from 'raw-loader!../../graphql/queries/preview_transform.graphql'
import {post_request} from "./net";
import {
    GetCollectionSourcesQuery,
    GetCollectionSourcesQueryVariables,
    PreviewTransformSourcesQuery,
    PreviewTransformSourcesQueryVariables,
    Source,
    TransformSourcesMutation, TransformSourcesMutationVariables
} from "../../graphql/generated";

export function get_collection_sources(collection_id: string): Promise<GetCollectionSourcesQuery> {
    const request = {
        query: GetCollectionSources,
        variables: {
            "collectionId": collection_id,
        }
    };
    return post_request<GetCollectionSourcesQuery, GetCollectionSourcesQueryVariables>(request);
}

type HasId = {
    id: string,
}

type Has_0 = {
    _0: HasId,
}

type SourceTransformAggregate = {
    originalId: string,
    original: Partial<Source> & HasId,
    transformed?: Extract<PreviewTransformSourcesQuery["library"]["sources"][number]["previewTransform"], Has_0>["_0"],
    error?: Extract<PreviewTransformSourcesQuery["library"]["sources"][number]["previewTransform"], HasId>,
}

export function preview_transform_sources(sources: Partial<Source>[], movePattern: string): Promise<Array<SourceTransformAggregate>> {
    const originals = new Map<string, Partial<Source>>(sources.map(source => [source.id, source]));

    const request = {
        query: PreviewTransformSources,
        variables: {
            "srcIds": sources.map(s => s.id),
            "movePattern": movePattern
        }
    };
    return post_request<PreviewTransformSourcesQuery, PreviewTransformSourcesQueryVariables>(request)
      .then(response => {
          return response.library.sources.map((source, index) => {
              const {previewTransform, metadata} = source;
              if (previewTransform.__typename === 'UpdatedSource') {
                  return {
                      originalId: sources[index].id,
                      original: {...sources[index], metadata},
                      transformed: previewTransform._0
                  } as SourceTransformAggregate;
              } else if (previewTransform.__typename === 'FailedSourceUpdate') {
                  return {
                      originalId: sources[index].id,
                      original: {...sources[index], metadata},
                      error: previewTransform
                  } as SourceTransformAggregate;
              } else {
                  return {
                      originalId: sources[index].id,
                      original: {...sources[index], metadata}
                  } as SourceTransformAggregate;
              }
          });
      });
}

export function transform_sources(sources: Partial<Source>[], movePattern: string): Promise<Array<SourceTransformAggregate>> {
    const request = {
        query: TransformSources,
        variables: {
            "srcIds": sources.map(s => s.id),
            "movePattern": movePattern
        }
    };
    return post_request<TransformSourcesMutation, TransformSourcesMutationVariables>(request)
      .then(response => {
          return response.library.transformSources.map((source, index) => {
              if (source.__typename === 'UpdatedSource') {
                  return {
                      originalId: sources[index].id,
                      original: sources[index],
                      transformed: source._0
                  } as SourceTransformAggregate;
              } else if (source.__typename === 'FailedSourceUpdate') {
                  return {
                      originalId: sources[index].id,
                      original: sources[index],
                      error: source.id
                  } as SourceTransformAggregate;
              } else {
                  return {
                      originalId: sources[index].id,
                      original: sources[index]
                  } as SourceTransformAggregate;
              }
          });
      });
}
