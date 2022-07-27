export interface GraphQLRequest<Variables> {
    query: string,
    variables?: Variables,
}

export function post_request<Response, Variables>(request: GraphQLRequest<Variables>): Promise<Response> {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', "http://localhost:5000/api");
        xhr.onreadystatechange = () => {
            console.debug("readystate: ", xhr.readyState);
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.debug(xhr.responseText);
                    try {
                        const response = JSON.parse(xhr.responseText);
                        if ("data" in response) {
                            resolve(response.data as Response);
                        } else {
                            reject(new Error("graphql error"))
                        }
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
