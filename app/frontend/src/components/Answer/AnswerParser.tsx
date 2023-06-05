import { renderToStaticMarkup } from "react-dom/server";
import { getCitationFilePath } from "../../api";

type HtmlParsedAnswer = {
    answerHtml: string;
    citations: string[];
    followupQuestions: string[];
};

export function parseAnswerToHtml(answer: string, citation_lookup: {}, onCitationClicked: (citationFilePath: string) => void): HtmlParsedAnswer {
    const citations: string[] = [];
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
            if ( typeof((citation_lookup as any)[part]) === "undefined") {
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
                    citations.push((citation_lookup as any)[part].split("/").slice(4).join("/"));
                    citationIndex = citations.length;
                }

                const path = getCitationFilePath((citation_lookup as any)[part]);

                return renderToStaticMarkup(
                    // splitting the full file path from citation_lookup into an array and then slicing it to get the folders, file name, and extension 
                    // the first 4 elements of the full file path are the "https:", "", "blob storaage url", and "container name" which are not needed in the display
                    <a className="supContainer" title={(citation_lookup as any)[part].split("/").slice(4).join("/")} onClick={() => onCitationClicked(path)}>
                        <sup>{citationIndex}</sup>
                    </a>
                );
            }
        }
    });

    return {
        answerHtml: fragments.join(""),
        citations,
        followupQuestions
    };
}
