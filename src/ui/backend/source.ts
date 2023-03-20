import TransformSources from 'raw-loader!../../graphql/mutations/transform_sources.graphql'
import PreviewTransformSources from 'raw-loader!../../graphql/queries/preview_transform.graphql'
import {post_request} from "./net";
import {
    PreviewTransformSourcesQuery,
    PreviewTransformSourcesQueryVariables,
    Source, TagPair, Transform,
    TransformSourcesMutation, TransformSourcesMutationVariables
} from "../../graphql/generated";

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
    covers?: PreviewTransformSourcesQuery["library"]["sources"][number]["coverImage"],
    error?: Extract<PreviewTransformSourcesQuery["library"]["sources"][number]["previewTransform"], HasId>,
}

export function preview_transform_sources(sources: Partial<Source>[], transformations: Transform[]): Promise<Array<SourceTransformAggregate>> {
    const request = {
        query: PreviewTransformSources,
        variables: {
            "srcIds": sources.map(s => s.id),
            "transformations": transformations
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
                      transformed: previewTransform._0,
                      covers: source.coverImage
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

export function transform_sources(sources: Partial<Source>[], transformations: Transform[]): Promise<Array<SourceTransformAggregate>> {
    const request = {
        query: TransformSources,
        variables: {
            "srcIds": sources.map(s => s.id),
            "transformations": transformations
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

export function groupTags(sources: Source[]): TagPair[] {
    return sources.map(src => src.metadata.tags)
        .reduce((previousValue, currentValue) => {
            if (previousValue) {
                return previousValue.filter(a => {
                    return currentValue.find(b => {
                        return a.key === b.key
                            && a.value === b.value;
                    });
                });
            }
            return currentValue;
        });
}

type MappedTag = { mappingName: string, values: Array<string> }

type GroupTags = Partial<{
    albumArtist: [string],
    albumTitle: string,
    year: string,
    discNumber: string,
    totalDiscs: string,
    genre: [string],
}>

function _head<T>(a: [T] | undefined): T | undefined {
    return a && a[0] ? a[0] : undefined;
}

export function groupMappedTags(mappedTags: [MappedTag]): GroupTags {
    let map = _reify_tags(mappedTags);
    return {
        albumArtist: map.get("album_artist"),
        albumTitle: _head(map.get("album_title")),
        discNumber: _head(map.get("disc_number")),
        totalDiscs: _head(map.get("total_discs")),
        year: _head(map.get("year")),
        genre: map.get("genre"),
    }
}

type TrackTags = Partial<{
    trackArtist: [string],
    trackTitle: string,
    trackNumber: string,
}>

export function trackTags(mappedTags: [MappedTag]): TrackTags {
    let map = _reify_tags(mappedTags);
    return {
        trackArtist: map.get("artist"),
        trackNumber: _head(map.get("track_number")),
        trackTitle: _head(map.get("track_title")),
    };
}

function _reify_tags(mappedTags: [MappedTag]): Map<string, [string]> {
    const map = new Map();
    mappedTags.forEach(m => map.set(m.mappingName, m.values));
    return map;
}
