// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { renderToStaticMarkup } from "react-dom/server";
import { getCitationFilePath } from "../../api";

type HtmlParsedAnswer = {
    answerHtml: string;
    citations: string[];
    sourceFiles: Record<string, string>;
    pageNumbers: Record<string, number>;
    // sourceFiles: {};
    // pageNumbers: {};
    followupQuestions: string[];
};

type CitationLookup = Record<string, {
    citation: string;
    source_path: string;
    page_number: string;
  }>;

export function parseAnswerToHtml(answer: string, citation_lookup: CitationLookup, onCitationClicked: (citationFilePath: string, citationSourcePath: string, pageNumber: string) => void): HtmlParsedAnswer {
    const citations: string[] = [];
    // const sourceFiles: {} = {};
    const sourceFiles: Record<string, string> = {};
    // const pageNumbers: {} = {};
    const pageNumbers: Record<string, number> = {};
    const followupQuestions: string[] = [];

    // Extract any follow-up questions that might be in the answer
    let parsedAnswer = answer.replace(/<<<([^>>>]+)>>>/g, (match, content) => {
        followupQuestions.push(content);
        return "";
    });

    // trim any whitespace from the end of the answer after removing follow-up questions
    parsedAnswer = parsedAnswer.trim();
    
    // Split the answer into parts, where the odd parts are citations
    const parts = parsedAnswer.split(/\[([^\]]+)\]/g);
    const fragments: string[] = parts.map((part, index) => {
        if (index % 2 === 0) {
            // Even parts are just text
            return part;
        } else {
            // Odd parts are citations as the "FileX" moniker
            // if ( typeof((citation_lookup as any)[part]) === "undefined") {

            //Added this for citation Bug. aparmar
            const citation = citation_lookup[part];
            
            if (!citation) {
                // if the citation reference provided by the OpenAI response does not match a key in the citation_lookup object
                // then return an empty string to avoid a crash or blank citation
                console.log("citation not found for: " + part)
                return "";
            }
            else {
                let citationIndex: number;
                if (citations.indexOf((citation_lookup as any)[part]) !== -1) {
                    citationIndex = citations.indexOf((citation_lookup as any)[part]) + 1;
               
                } else {
                    // splitting the full file path from citation_lookup into an array and then slicing it to get the folders, file name, and extension 
                    // the first 4 elements of the full file path are the "https:", "", "blob storaage url", and "container name" which are not needed in the display
                  
                    //Updated below code section for citation bug. aparmar
                    let citationShortName: string = (citation_lookup)[part].citation.split("/").slice(4).join("/");
                    citations.push(citationShortName);
                    // switch these to the citationShortName as key to allow dynamic lookup of the source path and page number
                    // The "FileX" moniker will not be used beyond this point in the UX code
                    sourceFiles[citationShortName] = citation.source_path;
                    // pageNumbers[citationShortName] = citation.page_number;
                    
                    // Check if the page_number property is a valid number.
                    if (!isNaN(Number(citation.page_number))) {
                        const pageNumber: number = Number(citation.page_number);
                        pageNumbers[citationShortName] = pageNumber;
                    } else {
                        console.log("page not found for: " + part)
                        // The page_number property is not a valid number, but we still generate a citation.
                        pageNumbers[citationShortName] = NaN;
                    }
                    // (sourceFiles as any)[citationShortName] = ((citation_lookup as any)[part].source_path);
                    // (pageNumbers as any)[citationShortName] = ((citation_lookup as any)[part].page_number);
                    citationIndex = citations.length;
                }
            const path = getCitationFilePath(citation.citation);
            const sourcePath = citation.source_path;
            const pageNumber = citation.page_number;
                
                // const path = getCitationFilePath((citation_lookup as any)[part].citation);
                // const sourcePath = (citation_lookup as any)[part].source_path;
                // const pageNumber = (citation_lookup as any)[part].page_number;

            return renderToStaticMarkup(
                    // splitting the full file path from citation_lookup into an array and then slicing it to get the folders, file name, and extension 
                    // the first 4 elements of the full file path are the "https:", "", "blob storaage url", and "container name" which are not needed in the display
                    
                    <a className="supContainer" title={citation.citation.split("/").slice(4).join("/")} onClick={() => onCitationClicked(path, sourcePath, pageNumber)}>
                    {/* <a className="supContainer" title={(citation_lookup as any)[part].citation.split("/").slice(4).join("/")} onClick={() => onCitationClicked(path, sourcePath, pageNumber)}> */}
                        <sup>{citationIndex}</sup>
                    </a>
                );
            }
        }
        
        });

    return {
        answerHtml: fragments.join(""),
        citations,
        sourceFiles,
        pageNumbers,
        followupQuestions
    };
}
