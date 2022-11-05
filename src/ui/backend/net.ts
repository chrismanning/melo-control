import * as url from "url";

export interface GraphQLRequest<Variables> {
    query: string,
    variables?: Variables,
}

type Config = {
    server_url: string,
}

export let config: Config = {
    server_url: ""
}

export function post_request<Response, Variables>(request: GraphQLRequest<Variables>): Promise<Response> {
    try {
        url.parse(config.server_url);
    } catch(e) {
        console.error(e);
        let msg = "Invalid 'server_url' value configured: " + config.server_url;
        console.error(msg);
        return Promise.reject(msg);
    }
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        console.warn(`${config.server_url}/api`);
        xhr.open('POST', `${config.server_url}/api`);
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
                            reject("graphql error");
                        }
                    }
                    catch (e) {
                        reject(`${e}`);
                    }
                } else {
                    reject("server error");
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
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify(request));
    });
}
