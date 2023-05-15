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
    let parsedAnswer = answer.replace(/<<([^>>]+)>>/g, (match, content) => {
        followupQuestions.push(content);
        return "";
    });

    // trim any whitespace from the end of the answer after removing follow-up questions
    parsedAnswer = parsedAnswer.trim();

    const parts = parsedAnswer.split(/\[([^\]]+)\]/g);

    const fragments: string[] = parts.map((part, index) => {
        if (index % 2 === 0) {
            return part;
        } else {
            let citationIndex: number;
            if (citations.indexOf((citation_lookup as any)[part]) !== -1) {
                citationIndex = citations.indexOf((citation_lookup as any)[part]) + 1;
            } else {
                citations.push((citation_lookup as any)[part].split("/").slice(4).join("/"));
                citationIndex = citations.length;
            }

            const path = getCitationFilePath((citation_lookup as any)[part]);

            return renderToStaticMarkup(
                <a className="supContainer" title={(citation_lookup as any)[part].split("/").slice(4).join("/")} onClick={() => onCitationClicked(path)}>
                    <sup>{citationIndex}</sup>
                </a>
            );
        }
    });

    return {
        answerHtml: fragments.join(""),
        citations,
        followupQuestions
    };
}
