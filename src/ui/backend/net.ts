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

export function post_request(request: GraphQLRequest): Promise<GraphQLResponse> {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', "http://localhost:5000/api");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.debug(xhr.responseText);
                    try {
                        const response = JSON.parse(xhr.responseText);
                        resolve(response);
                    }
                    catch (e) {
                        reject(e);
                    }
                }
            }
        };
        xhr.onerror = () => {
            reject(xhr.statusText);
        };
        xhr.ontimeout = () => {
            reject("timeout");
        };
        xhr.onabort = () => {
            reject("abort");
        };
        xhr.send(JSON.stringify(request));
    });
}
