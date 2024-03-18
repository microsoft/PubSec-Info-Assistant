// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useMemo } from "react";
import { Stack, IconButton } from "@fluentui/react";
import { ShieldCheckmark20Regular } from '@fluentui/react-icons';
import DOMPurify from "dompurify";

import styles from "./Answer.module.css";

import { Approaches, AskResponse, getCitationFilePath } from "../../api";
import { parseAnswerToHtml } from "./AnswerParser";
import { AnswerIcon } from "./AnswerIcon";
import { RAIPanel } from "../RAIPanel";

interface Props {
    answer: AskResponse;
    isSelected?: boolean;
    onCitationClicked: (filePath: string, sourcePath: string, pageNumber: string) => void;
    onThoughtProcessClicked: () => void;
    onWebSearchClicked: () => void;
    onRagSearchClicked: () => void;
    onWebCompareClicked: () => void;
    onRagCompareClicked: () => void;
    onSupportingContentClicked: () => void;
    onFollowupQuestionClicked?: (question: string) => void;
    showFollowupQuestions?: boolean;
    onAdjustClick?: () => void;
    onRegenerateClick?: () => void;
}

export const Answer = ({
    answer,
    isSelected,
    onCitationClicked,
    onThoughtProcessClicked,
    onWebSearchClicked,
    onRagSearchClicked,
    onWebCompareClicked,
    onRagCompareClicked,
    onSupportingContentClicked,
    onFollowupQuestionClicked,
    showFollowupQuestions,
    onAdjustClick,
    onRegenerateClick
}: Props) => {
    const parsedAnswer = useMemo(() => parseAnswerToHtml(answer.answer, answer.approach, answer.citation_lookup, onCitationClicked), [answer]);

    const sanitizedAnswerHtml = DOMPurify.sanitize(parsedAnswer.answerHtml);

    return (
        <Stack className={`${answer.approach == Approaches.ReadRetrieveRead ? styles.answerContainerWork : 
                            answer.approach == Approaches.ChatWebRetrieveRead ? styles.answerContainerWeb :
                            answer.approach == Approaches.CompareWorkWithWeb || answer.approach == Approaches.CompareWebWithWork ? styles.answerContainerCompare :
                            styles.answerContainer} ${isSelected && styles.selected}`} verticalAlign="space-between">
            <Stack.Item>
                <Stack horizontal horizontalAlign="space-between">
                    <AnswerIcon approach={answer.approach} />
                    <div>
                        <IconButton
                            style={{ color: "black" }}
                            iconProps={{ iconName: "Lightbulb" }}
                            title="Show thought process"
                            ariaLabel="Show thought process"
                            onClick={() => onThoughtProcessClicked()}
                            disabled={!answer.thoughts}
                        />
                        {answer.approach == Approaches.ReadRetrieveRead &&
                            <IconButton
                                style={{ color: "black" }}
                                iconProps={{ iconName: "ClipboardList" }}
                                title="Show supporting content"
                                ariaLabel="Show supporting content"
                                onClick={() => onSupportingContentClicked()}
                                disabled={!answer.data_points || !answer.data_points.length}
                            />
                        }
                    </div>
                </Stack>
            </Stack.Item>

            <Stack.Item grow>
                {(answer.approach == Approaches.ChatWebRetrieveRead || answer.approach == Approaches.CompareWorkWithWeb) &&
                    <div className={styles.protectedBanner}>
                        <ShieldCheckmark20Regular></ShieldCheckmark20Regular>Your personal and company data are protected
                    </div>
                }
                <div className={styles.answerText} dangerouslySetInnerHTML={{ __html: sanitizedAnswerHtml }}></div>
            </Stack.Item>

            {!!parsedAnswer.citations.length && (
                <Stack.Item>
                    <Stack horizontal wrap tokens={{ childrenGap: 5 }}>
                        <span className={styles.citationLearnMore}>Citations:</span>
                        {parsedAnswer.citations.map((x, i) => {
                            const path = getCitationFilePath(x);
                            return (
                                (parsedAnswer.approach == Approaches.ChatWebRetrieveRead || parsedAnswer.approach == Approaches.CompareWorkWithWeb) ? 
                                    <a key={i} className={parsedAnswer.approach == Approaches.ChatWebRetrieveRead ? styles.citationWeb : styles.citationCompare} 
                                    title={x} href={'https://'+ x} target="_blank" rel="noopener noreferrer">
                                    {`${++i}. ${x}`}
                                    </a>
                                 : 
                                 <a key={i} className={parsedAnswer.approach == Approaches.ReadRetrieveRead ? styles.citationWork : styles.citationCompare} 
                                 title={x} onClick={() => onCitationClicked(path, (parsedAnswer.sourceFiles as any)[x], (parsedAnswer.pageNumbers as any)[x])}>
                                 {`${++i}. ${x}`}
                                </a>
                            );
                        })}
                    </Stack>
                </Stack.Item>
                
            )}
            
            {!!parsedAnswer.followupQuestions.length && showFollowupQuestions && onFollowupQuestionClicked && (
                <Stack.Item>
                    <Stack horizontal wrap className={`${!!parsedAnswer.citations.length ? styles.followupQuestionsList : ""}`} tokens={{ childrenGap: 6 }}>
                        <span className={styles.followupQuestionLearnMore}>Follow-up questions:</span>
                        {parsedAnswer.followupQuestions.map((x, i) => {
                            return (
                                <a key={i} className={styles.followupQuestion} title={x} onClick={() => onFollowupQuestionClicked(x)}>
                                    {`${x}`}
                                </a>
                            );
                        })}
                    </Stack>
                </Stack.Item>
            )}
            <Stack.Item>
                <div className={styles.raiwarning}>AI-generated content may be incorrect</div>
            </Stack.Item>
            <Stack.Item align="center">
                <RAIPanel approach={answer.approach} onAdjustClick={onAdjustClick} onRegenerateClick={onRegenerateClick} onWebSearchClicked={onWebSearchClicked} onWebCompareClicked={onWebCompareClicked} onRagCompareClicked={onRagCompareClicked} onRagSearchClicked={onRagSearchClicked} />
            </Stack.Item>
        </Stack>
    );
};
