// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { renderToStaticMarkup } from "react-dom/server";
import { getCitationFilePath, Approaches } from "../../api";

import styles from "./Answer.module.css";

type HtmlParsedAnswer = {
    answerHtml: string;
    work_citations: string[];
    web_citations: string[];
    work_sourceFiles: Record<string, string>;
    web_sourceFiles: Record<string, string>;
    pageNumbers: Record<string, number>;
    followupQuestions: string[];
    approach: Approaches;
};

type ThoughtChain = Record<string, string>;

type CitationLookup = Record<string, {
    citation: string;
    source_path: string;
    page_number: string;
}>;

export function parseAnswerToHtml(answer: string, approach: Approaches, work_citation_lookup: CitationLookup, web_citation_lookup: CitationLookup, thought_chain: ThoughtChain, onCitationClicked: (citationFilePath: string, citationSourcePath: string, pageNumber: string) => void): HtmlParsedAnswer {
    const work_citations: string[] = [];
    const web_citations: string[] = [];
    const work_sourceFiles: Record<string, string> = {};
    const web_sourceFiles: Record<string, string> = {};
    const pageNumbers: Record<string, number> = {};
    const followupQuestions: string[] = [];

    // Extract any follow-up questions that might be in the answer
    let parsedAnswer = answer.replace(/<<<([^>>>]+)>>>/g, (match, content) => {
        followupQuestions.push(content);
        return "";
    });

    // trim any whitespace from the end of the answer after removing follow-up questions
    parsedAnswer = parsedAnswer.trim();
    var fragments: string[] = [];
    var work_fragments: string[] = [];
    var web_fragments: string[] = [];

    if (approach == Approaches.ChatWebRetrieveRead || approach == Approaches.ReadRetrieveRead) {
        // Split the answer into parts, where the odd parts are citations
        const parts = parsedAnswer.split(/\[([^\]]+)\]/g);
        fragments = parts.map((part, index) => {
            if (index % 2 === 0) {
                // Even parts are just text
                return part;
            } else {
                if (approach == Approaches.ReadRetrieveRead) {
                    const citation_lookup = work_citation_lookup;
                    // LLM Sometimes refers to citations as "source"
                    part = part.replace("source", "File");
                    // Odd parts are citations as the "FileX" moniker
                    const citation = citation_lookup[part];
                    if (!citation) {
                        // if the citation reference provided by the OpenAI response does not match a key in the citation_lookup object
                        // then return an empty string to avoid a crash or blank citation
                        console.log("citation not found for: " + part)
                        return "";
                    }
                    else {
                        let citationIndex: number;
                        let citationShortName: string
                        // splitting the full file path from citation_lookup into an array and then slicing it to get the folders, file name, and extension 
                        // the first 4 elements of the full file path are the "https:", "", "blob storaage url", and "container name" which are not needed in the display
                        citationShortName = (citation_lookup)[part].citation.split("/").slice(4).join("/");
        
                        // Check if the citationShortName is already in the citations array
                        if (work_citations.includes(citationShortName)) {
                            // If it exists, use the existing index (add 1 because array is 0-based but citation numbers are 1-based)
                            citationIndex = work_citations.indexOf(citationShortName) + 1;
                        } else {
                            work_citations.push(citationShortName);
                            // switch these to the citationShortName as key to allow dynamic lookup of the source path and page number
                            // The "FileX" moniker will not be used beyond this point in the UX code
                            work_sourceFiles[citationShortName] = citation.source_path;
                            citationIndex = work_citations.length;
        
                            // Check if the page_number property is a valid number.
                            if (!isNaN(Number(citation.page_number))) {
                                const pageNumber: number = Number(citation.page_number);
                                pageNumbers[citationShortName] = pageNumber;
                            } else {
                                console.log("page not found for: " + part)
                                // The page_number property is not a valid number, but we still generate a citation.
                                pageNumbers[citationShortName] = NaN;
                            }
                        }
                                            
                        const path = getCitationFilePath(citation.citation);
                        const sourcePath = citation.source_path;
                        const pageNumber = citation.page_number;
        
                        return renderToStaticMarkup(
                            <a className={styles.supContainerWork} title={citation.citation.split("/").slice(4).join("/")} onClick={() => onCitationClicked(path, sourcePath, pageNumber)}>
                                <sup>{citationIndex}</sup>
                            </a>
                        );
                    }
                }
                if (approach == Approaches.ChatWebRetrieveRead) {
                    const citation_lookup = web_citation_lookup;
                    // LLM Sometimes refers to citations as "source"
                    part = part.replace("source", "url");
                    // Odd parts are citations as the "FileX" moniker
                    const citation = citation_lookup[part];
                    if (!citation) {
                        // if the citation reference provided by the OpenAI response does not match a key in the citation_lookup object
                        // then return an empty string to avoid a crash or blank citation
                        console.log("citation not found for: " + part)
                        return "";
                    }
                    else {
                        let citationIndex: number;
        
                        // Check if the citation is already in the citations array
                        if (web_citations.includes(citation.citation)) {
                            // If it exists, use the existing index (add 1 because array is 0-based but citation numbers are 1-based)
                            citationIndex = web_citations.indexOf(citation.citation) + 1;
                        } else {
                            web_citations.push(citation.citation);
                            // switch these to the citation as key to allow dynamic lookup of the source path and page number
                            // The "FileX" moniker will not be used beyond this point in the UX code
                            web_sourceFiles[citation.citation] = citation.source_path;
                            citationIndex = web_citations.length;
        
                            // The page_number property is not valid for web citation.
                            pageNumbers[citation.citation] = NaN;
                        }

                        return renderToStaticMarkup(
                            <a className={styles.supContainerWeb} title={citation.citation} href={citation.citation} target="_blank" rel="noopener noreferrer">
                                <sup>{citationIndex}</sup>
                            </a>
                        );
                    }
                }
                return "";
            }
        });
    }
    if (approach == Approaches.CompareWorkWithWeb || approach == Approaches.CompareWebWithWork) {
        const parts = parsedAnswer.split(/\[([^\]]+)\]/g);
        fragments = parts.map((part, index) => {
            if (index % 2 === 0) {
                // Even parts are just text
                return part;
            } else {
                return "";
            }
        });
        const work_parts = thought_chain["work_response"].split(/\[([^\]]+)\]/g);
        work_fragments = work_parts.map((part, index) => {
            // Enumerate over work_citation_lookup and add the property citation to work_citations string array
            if (index % 2 === 0) {
                // Even parts are just text
                return part;
            } else {
                // LLM Sometimes refers to citations as "source"
                part = part.replace("source", "File");
                const work_citation = work_citation_lookup[part];
                if (!work_citation) {
                    // if the citation reference provided by the OpenAI response does not match a key in the citation_lookup object
                    // then return an empty string to avoid a crash or blank citation
                    console.log("citation not found for: " + part)
                    return "";
                }
                else {
                    // Check if the citation is already in the citations array
                    if (work_citations.includes(work_citation.citation.split("/").slice(4).join("/"))) {
                        // If it exists, don't add it again
                    } else {
                        work_citations.push(work_citation.citation.split("/").slice(4).join("/"));
                        work_sourceFiles[work_citation.citation.split("/").slice(4).join("/")] = work_citation.source_path;
                        pageNumbers[work_citation.citation] = Number(work_citation.page_number);
                    }
                }
            }
            return "";
        });
        const web_parts = thought_chain["web_response"].split(/\[([^\]]+)\]/g);
        web_fragments = web_parts.map((part, index) => {
            // Enumerate over web_citation_lookup and add the property citation to web_citations string array
            if (index % 2 === 0) {
                // Even parts are just text
                return part;
            } else {
                // LLM Sometimes refers to citations as "source"
                part = part.replace("source", "url");
                const web_citation = web_citation_lookup[part];
                if (!web_citation) {
                    // if the citation reference provided by the OpenAI response does not match a key in the citation_lookup object
                    // then return an empty string to avoid a crash or blank citation
                    console.log("citation not found for: " + part)
                    return "";
                }
                else {
                    // Check if the citation is already in the citations array
                    if (web_citations.includes(web_citation.citation)) {
                        // If it exists, don't add it again
                    } else {
                        web_citations.push(web_citation.citation);
                        web_sourceFiles[web_citation.citation] = web_citation.source_path;
                        pageNumbers[web_citation.citation] = NaN;
                    }
                }
            }
            return "";
        });
    }
    if (approach == Approaches.GPTDirect) {
        fragments.push(parsedAnswer);
    }
    

    return {
        answerHtml: fragments.join(""),
        work_citations,
        web_citations,
        work_sourceFiles,
        web_sourceFiles,
        pageNumbers,
        followupQuestions,
        approach
    };
}