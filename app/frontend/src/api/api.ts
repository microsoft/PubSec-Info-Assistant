// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { AskRequest, 
    AskResponse, 
    ChatRequest, 
    BlobClientUrlResponse, 
    AllFilesUploadStatus, 
    GetUploadStatusRequest, 
    GetInfoResponse, 
    ActiveCitation, 
    GetWarningBanner, 
    StatusLogEntry, 
    StatusLogResponse, 
    ApplicationTitle, 
    GetTagsResponse,
    DeleteItemRequest,
    ResubmitItemRequest,
    GetFeatureFlagsResponse,
    } from "./models";

export async function askApi(options: AskRequest): Promise<AskResponse> {
    const response = await fetch("/ask", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            question: options.question,
            approach: options.approach,
            overrides: {
                semantic_ranker: options.overrides?.semanticRanker,
                semantic_captions: options.overrides?.semanticCaptions,
                top: options.overrides?.top,
                temperature: options.overrides?.temperature,
                prompt_template: options.overrides?.promptTemplate,
                prompt_template_prefix: options.overrides?.promptTemplatePrefix,
                prompt_template_suffix: options.overrides?.promptTemplateSuffix,
                exclude_category: options.overrides?.excludeCategory,
                user_persona: options.overrides?.userPersona,
                system_persona: options.overrides?.systemPersona,
                ai_persona: options.overrides?.aiPersona,
            }
        })
    });

    const parsedResponse: AskResponse = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error(parsedResponse.error || "Unknown error");
    }
    
    return parsedResponse;
}

export async function chatApi(options: ChatRequest): Promise<AskResponse> {
    const response = await fetch("/chat", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            history: options.history,
            approach: options.approach,
            overrides: {
                semantic_ranker: options.overrides?.semanticRanker,
                semantic_captions: options.overrides?.semanticCaptions,
                top: options.overrides?.top,
                temperature: options.overrides?.temperature,
                prompt_template: options.overrides?.promptTemplate,
                prompt_template_prefix: options.overrides?.promptTemplatePrefix,
                prompt_template_suffix: options.overrides?.promptTemplateSuffix,
                exclude_category: options.overrides?.excludeCategory,
                suggest_followup_questions: options.overrides?.suggestFollowupQuestions,
                byPassRAG: options.overrides?.byPassRAG,
                user_persona: options.overrides?.userPersona,
                system_persona: options.overrides?.systemPersona,
                ai_persona: options.overrides?.aiPersona,
                response_length: options.overrides?.responseLength,
                response_temp: options.overrides?.responseTemp,
                selected_folders: options.overrides?.selectedFolders,
                selected_tags: options.overrides?.selectedTags
            }
        })
    });

    const parsedResponse: AskResponse = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error(parsedResponse.error || "Unknown error");
    }
   
    return parsedResponse;
}

export function getCitationFilePath(citation: string): string {
    return `${encodeURIComponent(citation)}`;
}

export async function getBlobClientUrl(): Promise<string> {
    const response = await fetch("/getblobclienturl", {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });

    const parsedResponse: BlobClientUrlResponse = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error(parsedResponse.error || "Unknown error");
    }

    return parsedResponse.url;
}

export async function getAllUploadStatus(options: GetUploadStatusRequest): Promise<AllFilesUploadStatus> {
    const response = await fetch("/getalluploadstatus", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            timeframe: options.timeframe,
            state: options.state as string,
            folder: options.folder as string,
            tag: options.tag as string
            })
        });
    
    const parsedResponse: any = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error(parsedResponse.error || "Unknown error");
    }
    const results: AllFilesUploadStatus = {statuses: parsedResponse};
    return results;
}

export async function deleteItem(options: DeleteItemRequest): Promise<boolean> {
    try {
        const response = await fetch("/deleteItems", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                path: options.path
            })
        });
        if (!response.ok) {
            // If the response is not ok, throw an error
            const errorResponse = await response.json();
            throw new Error(errorResponse.error || "Unknown error");
        }
        // If the response is ok, return true
        return true;
    } catch (error) {
        console.error("Error during deleteItem:", error);
        return false;
    }
}


export async function resubmitItem(options: ResubmitItemRequest): Promise<boolean> {
    try {
        const response = await fetch("/resubmitItems", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                path: options.path
            })
        });
        if (!response.ok) {
            // If the response is not ok, throw an error
            const errorResponse = await response.json();
            throw new Error(errorResponse.error || "Unknown error");
        }
        // If the response is ok, return true
        return true;
    } catch (error) {
        console.error("Error during deleteItem:", error);
        return false;
    }
}


export async function getFolders(): Promise<string[]> {
    const response = await fetch("/getfolders", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            })
        });
    
    const parsedResponse: any = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error(parsedResponse.error || "Unknown error");
    }
    // Assuming parsedResponse is the array of strings (folder names) we want
    // Check if it's actually an array and contains strings
    if (Array.isArray(parsedResponse) && parsedResponse.every(item => typeof item === 'string')) {
        return parsedResponse;
    } else {
        throw new Error("Invalid response format");
    }
}


export async function getTags(): Promise<string[]> {
    const response = await fetch("/gettags", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            })
        });
    
    const parsedResponse: any = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error(parsedResponse.error || "Unknown error");
    }
    // Assuming parsedResponse is the array of strings (folder names) we want
    // Check if it's actually an array and contains strings
    if (Array.isArray(parsedResponse) && parsedResponse.every(item => typeof item === 'string')) {
        return parsedResponse;
    } else {
        throw new Error("Invalid response format");
    }
}


export async function getHint(question: string): Promise<String> {
    const response = await fetch(`/getHint?question=${encodeURIComponent(question)}`, {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });
    
    const parsedResponse: String = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error("Unknown error");
    }

    return parsedResponse;
}


export function streamData(question: string, onMessage: (data: string) => void): EventSource {
    const encodedQuestion = encodeURIComponent(question);
    const eventSource = new EventSource(`/stream?question=${encodedQuestion}`);

    eventSource.onmessage = (event) => {
        onMessage(event.data);
    };

    return eventSource;
}
export function streamCsvData(question: string, onMessage: (data: string) => void): EventSource {
    const encodedQuestion = encodeURIComponent(question);
    const eventSource = new EventSource(`/csvstream?question=${encodedQuestion}`);

    eventSource.onmessage = (event) => {
        onMessage(event.data);
    };

    return eventSource;
}

export async function getSolve(question: string): Promise<String[]> {
    const response = await fetch(`/getSolve?question=${encodeURIComponent(question)}`, {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });
    
    const parsedResponse: String[] = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error("Unknown error");
    }

    return parsedResponse;
}
export async function refresh(): Promise<String[]> {
    const response = await fetch(`/refresh?`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        }
    });
    
    const parsedResponse: String[] = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error("Unknown error");
    }

    return parsedResponse;
}


export async function postCsv(file: File): Promise<String> {
    const formData = new FormData();
    formData.append('csv', file);

    const response = await fetch('/postCsv', {
        method: 'POST',
        body: formData,
    });

    const parsedResponse: String = await response.text();
    if (response.status > 299 || !response.ok) {
        throw Error("Unknown error");
    }

    return parsedResponse;
}
export async function getCsvAnalysis(question: string, file: File, retries: number = 3): Promise<String[]> {
    let lastError;
    const formData = new FormData();
    formData.append('csv', file);

    const response = await fetch('/postCsv', {
        method: 'POST',
        body: formData,
    });

    const parsedResponse: String = await response.text();
    if (response.status > 299 || !response.ok) {
        throw Error("Unknown error");
    }
    for (let i = 0; i < retries; i++) {
        try {
            const response = await fetch(`/getCsvAnalysis?question=${encodeURIComponent(question)}`, {
                method: "GET",
                headers: {
                    "Content-Type": "application/json"
                }
            });

            const parsedResponse: String[] = await response.json();
            if (response.status > 299 || !response.ok) {
                throw Error("Unknown error");
            }

            return parsedResponse;
        } catch (error) {
            lastError = error;
        }
    }

    throw lastError;
}

export async function processCsvAgentResponse(question: string, file: File, retries: number = 3): Promise<String> {
    let lastError;

    const formData = new FormData();
    formData.append('csv', file);

    const response = await fetch('/postCsv', {
        method: 'POST',
        body: formData,
    });

    const parsedResponse: String = await response.text();
    if (response.status > 299 || !response.ok) {
        throw Error("Unknown error");
    }
    for (let i = 0; i < retries; i++) {
        try {
            const response = await fetch(`/process_csv_agent_response?question=${encodeURIComponent(question)}`, {
                method: "GET",
                headers: {
                    "Content-Type": "application/json"
                }
            });

            const parsedResponse: String = await response.json();
            if (response.status > 299 || !response.ok) {
                throw Error("Unknown error");
            }

            return parsedResponse;
        } catch (error) {
            lastError = error;
        }
    }

    throw lastError;
}

export async function processAgentResponse(question: string): Promise<String> {
    const response = await fetch(`/process_agent_response?question=${encodeURIComponent(question)}`, {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });
    
    const parsedResponse: String = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error("Unknown error");
    }

    return parsedResponse;    
}

export async function logStatus(status_log_entry: StatusLogEntry): Promise<StatusLogResponse> {
    var response = await fetch("/logstatus", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            "path": status_log_entry.path,
            "status": status_log_entry.status,
            "status_classification": status_log_entry.status_classification,
            "state": status_log_entry.state
            })
    });

    var parsedResponse: StatusLogResponse = await response.json();
    if (response.status > 299 || !response.ok) {
        throw Error(parsedResponse.error || "Unknown error");
    }

    var results: StatusLogResponse = {status: parsedResponse.status};
    return results;
}

export async function getInfoData(): Promise<GetInfoResponse> {
    const response = await fetch("/getInfoData", {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });
    const parsedResponse: GetInfoResponse = await response.json();
    if (response.status > 299 || !response.ok) {
        console.log(response);
        throw Error(parsedResponse.error || "Unknown error");
    }
    console.log(parsedResponse);
    return parsedResponse;
}

export async function getWarningBanner(): Promise<GetWarningBanner> {
    const response = await fetch("/getWarningBanner", {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });
    const parsedResponse: GetWarningBanner = await response.json();
    if (response.status > 299 || !response.ok) {
        console.log(response);
        throw Error(parsedResponse.error || "Unknown error");
    }
    console.log(parsedResponse);
    return parsedResponse;
}

export async function getCitationObj(citation: string): Promise<ActiveCitation> {
    const response = await fetch(`/getcitation`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            citation: citation
        })
    });
    const parsedResponse: ActiveCitation = await response.json();
    if (response.status > 299 || !response.ok) {
        console.log(response);
        throw Error(parsedResponse.error || "Unknown error");
    }
    return parsedResponse;
}

export async function getApplicationTitle(): Promise<ApplicationTitle> {
    console.log("fetch Application Titless");
    const response = await fetch("/getApplicationTitle", {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });

    const parsedResponse: ApplicationTitle = await response.json();
    if (response.status > 299 || !response.ok) {
        console.log(response);
        throw Error(parsedResponse.error || "Unknown error");
    }
    console.log(parsedResponse);
    return parsedResponse;
}

export async function getAllTags(): Promise<GetTagsResponse> {
    const response = await fetch("/getalltags", {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });

    const parsedResponse: any = await response.json();
    if (response.status > 299 || !response.ok) {
        console.log(response);
        throw Error(parsedResponse.error || "Unknown error");
    }
    var results: GetTagsResponse = {tags: parsedResponse};
    return results;
}

export async function getFeatureFlags(): Promise<GetFeatureFlagsResponse> {
    const response = await fetch("/getFeatureFlags", {
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    });
    const parsedResponse: GetFeatureFlagsResponse = await response.json();
    if (response.status > 299 || !response.ok) {
        console.log(response);
        throw Error(parsedResponse.error || "Unknown error");
    }
    console.log(parsedResponse);
    return parsedResponse;
}