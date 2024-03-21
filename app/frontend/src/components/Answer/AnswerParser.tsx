// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { renderToStaticMarkup } from "react-dom/server";
import { getCitationFilePath, Approaches } from "../../api";

type HtmlParsedAnswer = {
    answerHtml: string;
    citations: string[];
    sourceFiles: Record<string, string>;
    pageNumbers: Record<string, number>;
    followupQuestions: string[];
    approach: Approaches;
};

type CitationLookup = Record<string, {
    citation: string;
    source_path: string;
    page_number: string;
}>;

export function parseAnswerToHtml(answer: string, approach: Approaches, citation_lookup: CitationLookup, onCitationClicked: (citationFilePath: string, citationSourcePath: string, pageNumber: string) => void): HtmlParsedAnswer {
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
                if (approach == Approaches.ChatWebRetrieveRead || approach == Approaches.CompareWorkWithWeb) {
                    citationShortName = new URL(citation.citation).hostname;
                }else{
                    citationShortName = (citation_lookup)[part].citation.split("/").slice(4).join("/");
                }

                // Check if the citationShortName is already in the citations array
                if (citations.includes(citationShortName)) {
                    // If it exists, use the existing index (add 1 because array is 0-based but citation numbers are 1-based)
                    citationIndex = citations.indexOf(citationShortName) + 1;
                } else {
                    citations.push(citationShortName);
                    // switch these to the citationShortName as key to allow dynamic lookup of the source path and page number
                    // The "FileX" moniker will not be used beyond this point in the UX code
                    sourceFiles[citationShortName] = citation.source_path;
                    citationIndex = citations.length;

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
                if (approach == Approaches.ChatWebRetrieveRead || approach == Approaches.CompareWorkWithWeb) {
                    return renderToStaticMarkup(
                        <a className="supContainer" title={citationShortName} href={citation.citation} target="_blank" rel="noopener noreferrer">
                            <sup>{citationIndex}</sup>
                        </a>
                    );
                }
                const path = getCitationFilePath(citation.citation);
                const sourcePath = citation.source_path;
                const pageNumber = citation.page_number;

                return renderToStaticMarkup(
                    <a className="supContainer" title={citation.citation.split("/").slice(4).join("/")} onClick={() => onCitationClicked(path, sourcePath, pageNumber)}>
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
        followupQuestions,
        approach
    };
}