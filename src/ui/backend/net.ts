export interface GraphQLRequest {
    query: string,
    variables?: Record<string, any>,
}

export type GraphQLResponse = GraphQLDataResponse | GraphQLErrorResponse;

export interface GraphQLDataResponse {
    data: Record<string, any>,
    extensions: any,
}

export interface GraphQLErrorResponse {
    errors: any[],
}

export type GraphQLCallback = (response: GraphQLResponse) => void;

export function post_request(request: GraphQLRequest, callback?: GraphQLCallback) {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', "http://localhost:5000/api");
    xhr.onreadystatechange = () => {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            console.debug(xhr.responseText);
            if (xhr.status === 200 && callback) {
                callback(JSON.parse(xhr.responseText));
            }
        }
    };
    xhr.send(JSON.stringify(request));
}
